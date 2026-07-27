//
//  NetworkMonitorTests.swift
//  Utilities
//
//  Created by Claude on 2026-07-27.
//

import Testing
import Foundation
import Network
import os
@testable import Utilities

// MARK: - NetworkMonitor Tests

/// Tests drive an injected `AsyncStream<NWPath.Status>` instead of a real
/// `NWPathMonitor`, and use a private `NotificationCenter` so tests neither
/// interfere with each other nor start real monitoring.
/// `NetworkMonitor.shared` must never be touched from tests.
struct NetworkMonitorTests {

    /// Bundles a monitor with its injected path source and notification center.
    private struct Harness {
        let monitor: NetworkMonitor
        let source: AsyncStream<NWPath.Status>.Continuation
        let center: NotificationCenter

        init() {
            let (stream, source) = AsyncStream.makeStream(of: NWPath.Status.self)
            self.source = source
            self.center = NotificationCenter()
            self.monitor = NetworkMonitor(pathStatuses: stream, notificationCenter: center)
        }
    }

    // MARK: Status mapping

    @Test(arguments: [
        (NWPath.Status.satisfied, ConnectivityStatus.connected),
        (NWPath.Status.unsatisfied, ConnectivityStatus.notConnected),
        (NWPath.Status.requiresConnection, ConnectivityStatus.notConnected),
    ])
    func statusMapping(pathStatus: NWPath.Status, expected: ConnectivityStatus) {
        #expect(ConnectivityStatus(pathStatus) == expected)
    }

    // MARK: Synchronous state

    @Test func initialStatusIsUnknownAndOffline() {
        let harness = Harness()
        #expect(harness.monitor.currentStatus == .unknown)
        #expect(harness.monitor.isOnline == false)
    }

    @Test func currentStatusAndIsOnlineUpdateOnPathChange() async {
        let harness = Harness()
        var updates = harness.monitor.statusUpdates.makeAsyncIterator()
        #expect(await updates.next() == .unknown)

        harness.source.yield(.satisfied)

        #expect(await updates.next() == .connected)
        #expect(harness.monitor.currentStatus == .connected)
        #expect(harness.monitor.isOnline)
    }

    // MARK: Status stream

    @Test func streamDeliversChangesInOrder() async {
        let harness = Harness()
        var updates = harness.monitor.statusUpdates.makeAsyncIterator()
        #expect(await updates.next() == .unknown)

        harness.source.yield(.satisfied)
        harness.source.yield(.unsatisfied)

        #expect(await updates.next() == .connected)
        #expect(await updates.next() == .notConnected)
    }

    @Test func streamReplaysCurrentStatusOnSubscription() async {
        let harness = Harness()
        var first = harness.monitor.statusUpdates.makeAsyncIterator()
        #expect(await first.next() == .unknown)

        harness.source.yield(.satisfied)
        #expect(await first.next() == .connected)

        //A new subscriber immediately receives the current status.
        var second = harness.monitor.statusUpdates.makeAsyncIterator()
        #expect(await second.next() == .connected)
    }

    @Test func multipleConsumersEachReceiveUpdates() async {
        let harness = Harness()
        var first = harness.monitor.statusUpdates.makeAsyncIterator()
        var second = harness.monitor.statusUpdates.makeAsyncIterator()
        #expect(await first.next() == .unknown)
        #expect(await second.next() == .unknown)

        harness.source.yield(.satisfied)

        #expect(await first.next() == .connected)
        #expect(await second.next() == .connected)
    }

    @Test func noDuplicateEmissionWhenStatusUnchanged() async {
        let harness = Harness()
        var updates = harness.monitor.statusUpdates.makeAsyncIterator()
        #expect(await updates.next() == .unknown)

        harness.source.yield(.satisfied)
        harness.source.yield(.satisfied)         //unchanged: no emission
        harness.source.yield(.requiresConnection)

        #expect(await updates.next() == .connected)
        //Next element is the change to .notConnected, with no repeated .connected in between.
        #expect(await updates.next() == .notConnected)
    }

    @Test func streamsFinishWhenSourceFinishes() async {
        let harness = Harness()
        var updates = harness.monitor.statusUpdates.makeAsyncIterator()
        #expect(await updates.next() == .unknown)

        harness.source.finish()

        #expect(await updates.next() == nil)
    }

    // MARK: Notifications

    @Test func notificationPostedOnChange() async {
        let harness = Harness()
        let (notes, noteContinuation) = AsyncStream.makeStream(of: Void.self)
        let observer = harness.center.addObserver(forName: .ConnectivityDidChange,
                                                  object: nil,
                                                  queue: nil) { _ in
            noteContinuation.yield(())
        }
        defer { harness.center.removeObserver(observer) }

        harness.source.yield(.satisfied)

        var notifications = notes.makeAsyncIterator()
        #expect(await notifications.next() != nil)
    }

    @Test func noNotificationWhenStatusUnchanged() async {
        let harness = Harness()
        let postCount = OSAllocatedUnfairLock(initialState: 0)
        let (notes, noteContinuation) = AsyncStream.makeStream(of: Void.self)
        let observer = harness.center.addObserver(forName: .ConnectivityDidChange,
                                                  object: nil,
                                                  queue: nil) { _ in
            postCount.withLock { $0 += 1 }
            noteContinuation.yield(())
        }
        defer { harness.center.removeObserver(observer) }

        harness.source.yield(.satisfied)
        harness.source.yield(.satisfied)   //unchanged: must not post
        harness.source.yield(.unsatisfied)

        //Await both expected notifications; only three yields were made,
        //so a duplicate post for the unchanged status would make the count 3.
        var notifications = notes.makeAsyncIterator()
        _ = await notifications.next()
        _ = await notifications.next()
        #expect(postCount.withLock { $0 } == 2)
    }
}
