//
//  NetworkMonitor.swift
//  Utilities
//
//  Created by Claude on 2026-07-27.
//  Copyright © 2026 JN Avionics. All rights reserved.
//

/*** NOTE: NOTIFICATIONS ARE UNRELIABLE ON SIMULATOR, TEST ON REAL DEVICE. **/

import Foundation
import Network
import os
import JBLogging


//For Swift
public extension Notification.Name {
    static let ConnectivityDidChange = Notification.Name("Connectivity changed")
}

public enum ConnectivityStatus: Int64, Sendable {
    case unknown = 0
    case notConnected = 1
    case connected = 2
}

extension ConnectivityStatus: CustomStringConvertible {
    public var description: String {
        if (self == .unknown) { return "'unknown'" }
        if (self == .notConnected) { return "'not connected'" }
        if (self == .connected) { return "'connected'" }
        return "'out of scope'"
    }
}

extension ConnectivityStatus {
    /// `.satisfied` maps to `.connected`; `.unsatisfied` and `.requiresConnection`
    /// both map to `.notConnected`, matching the legacy monitor's behavior.
    init(_ pathStatus: NWPath.Status) {
        self = (pathStatus == .satisfied) ? .connected : .notConnected
    }
}


extension NWPath.Status: @retroactive CustomStringConvertible {
    public var description: String {
        if (self == .satisfied) { return "'satisfied'" }
        if (self == .unsatisfied) { return "'unsatisfied'" }
        if (self == .requiresConnection) { return "'requires connection'" }
        return "unknown"
    }
}


/// Monitors network connectivity, replacing the deprecated ``ConnectivityMonitor``.
///
/// The monitor serves two purposes:
/// - Publishing connectivity changes, both as an async sequence (``statusUpdates``)
///   and by posting `.ConnectivityDidChange` to the notification center.
/// - Answering immediately whether internet is available: ``isOnline`` and
///   ``currentStatus`` are synchronous and may be called from any thread or
///   isolation context. The monitor itself may likewise be created on any thread.
///
/// Unlike the legacy monitor, the notification is posted with `object: nil` and from
/// a background context — observers that need the main thread should observe with
/// `queue: .main` or hop to the main actor themselves.
public final class NetworkMonitor: Sendable {

    /// Shared singleton observing the device's real network path.
    /// Monitoring starts on first access and lives for the remainder of the process.
    public static let shared = NetworkMonitor(pathStatuses: NetworkMonitor.livePathStatuses())

    /// All mutable state lives here, guarded by the `state` lock.
    private struct State {
        var currentStatus: ConnectivityStatus = .unknown
        var continuations: [UUID: AsyncStream<ConnectivityStatus>.Continuation] = [:]
    }

    private let state: OSAllocatedUnfairLock<State>
    private let notificationCenter: NotificationCenter
    private let monitoringTask: Task<Void, Never>

    /// The most recently observed connectivity status.
    public var currentStatus: ConnectivityStatus {
        state.withLock { $0.currentStatus }
    }

    /// Whether an internet connection is currently available.
    public var isOnline: Bool {
        currentStatus == .connected
    }

    /// A stream of connectivity statuses.
    ///
    /// Each access returns a new, independent stream (an `AsyncStream` supports only
    /// a single consumer). The stream first yields the current status, then yields on
    /// every subsequent change, and finishes when monitoring ends.
    public var statusUpdates: AsyncStream<ConnectivityStatus> {
        AsyncStream { continuation in
            let id = UUID()
            state.withLock { state in
                state.continuations[id] = continuation
                //Replay the current status inside the lock, so no update
                //can slip in between subscribing and the first element.
                continuation.yield(state.currentStatus)
            }
            continuation.onTermination = { [state] _ in
                state.withLock { $0.continuations[id] = nil }
            }
        }
    }

    /// Used by `shared`, and by unit tests to inject a path status source.
    init(pathStatuses: AsyncStream<NWPath.Status>,
         notificationCenter: NotificationCenter = .default) {
        let state = OSAllocatedUnfairLock(initialState: State())
        self.state = state
        self.notificationCenter = notificationCenter
        //Capture locals rather than self: no retain cycle, so non-singleton
        //instances deinit normally and cancel their monitoring task.
        self.monitoringTask = Task { [state, notificationCenter] in
            for await pathStatus in pathStatuses {
                Self.handle(pathStatus, state: state, notificationCenter: notificationCenter)
            }
            //Source ended: finish all subscriber streams.
            state.withLock { state in
                state.continuations.values.forEach { $0.finish() }
                state.continuations.removeAll()
            }
        }
    }

    deinit {
        monitoringTask.cancel()
    }

    /// The live path status source: `NWPathMonitor` iterated as an `AsyncSequence`.
    /// Monitoring starts when iteration begins and stops when the stream is terminated.
    private static func livePathStatuses() -> AsyncStream<NWPath.Status> {
        AsyncStream { continuation in
            let task = Task {
                let monitor = NWPathMonitor()
                for await path in monitor {
                    Log.debug(message: "Available interfaces: \(path.availableInterfaces)", in: .network)
                    continuation.yield(path.status)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func handle(_ pathStatus: NWPath.Status,
                               state: OSAllocatedUnfairLock<State>,
                               notificationCenter: NotificationCenter) {
        Log.debug(message: "Connectivity status: \(pathStatus)", in: .network)

        let newStatus = ConnectivityStatus(pathStatus)

        if newStatus == .connected {
            Log.trace(message: "Connectivity: We have internet!\n", in: .network)
        } else {
            Log.trace(message: "Connectivity: No internet available.\n", in: .network)
        }

        //Yielding inside the lock totally orders updates against new subscriptions
        //replaying the current status. Yield only buffers and never blocks,
        //so it is safe while the lock is held.
        let changed = state.withLock { state -> Bool in
            guard newStatus != state.currentStatus else { return false }
            state.currentStatus = newStatus
            state.continuations.values.forEach { $0.yield(newStatus) }
            return true
        }

        if changed {
            notificationCenter.post(name: .ConnectivityDidChange, object: nil)
        }
    }
}
