//
//  TimeFieldDemoViewController.swift
//  Utilities-Example
//
//  Created by Claude on 2026-02-10.
//

import UIKit
import SwiftUI
import Utilities

// MARK: - Demo View Controller

/// Hosts the SwiftUI `TimeFieldDemoView` inside a `UIHostingController`.
@available(iOS 18.0, *)
class TimeFieldDemoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TimeField Demo"

        let hostingController = UIHostingController(rootView: TimeFieldDemoView())
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
    }
}

// MARK: - Focus Enum

/// Focus cases for the mixed focus chain demo, combining ValidatedField and TimeField.
private enum MixedField: Hashable {
    case pilotName, departure, arrival, blockTime
}

// MARK: - Demo SwiftUI View

@available(iOS 18.0, *)
private struct TimeFieldDemoView: View {

    @FocusState private var focus: MixedField?

    // Basic fields (standalone)
    @State private var wallClock: Int?
    @State private var interval: Int?

    // Mixed focus chain
    @State private var pilotName: String?
    @State private var departure: Int?
    @State private var arrival: Int?
    @State private var blockTime: Int?

    var body: some View {
        Form {
            // MARK: 1 — Basic fields (no focus chain)
            Section("Basic Fields") {
                TimeField("Wall Clock Time", value: $wallClock, mode: .time)
                TimeField("Interval", value: $interval, mode: .interval)
            }

            // MARK: 2 — Mixed focus chain
            Section("Mixed Focus Chain") {
                ValidatedField("Pilot Name", value: $pilotName,
                               strategy: CharacterSetStrategy(
                                   allowed: .letters.union(CharacterSet(charactersIn: " -")),
                                   maxLength: 50),
                               focus: $focus, equals: .pilotName, next: .departure)

                TimeField("Departure", value: $departure, mode: .time,
                          focus: $focus, equals: .departure, next: .arrival)

                TimeField("Arrival", value: $arrival, mode: .time,
                          focus: $focus, equals: .arrival, next: .blockTime)

                TimeField("Block Time", value: $blockTime, mode: .interval,
                          focus: $focus, equals: .blockTime, next: nil)
            }

            // MARK: 3 — Live values
            Section("Live Values") {
                LabeledContent("Wall Clock") {
                    Text(wallClock.map { $0.toTimeString() } ?? "—")
                }
                LabeledContent("Interval") {
                    Text(interval.map { $0.toTimeString() } ?? "—")
                }
                LabeledContent("Pilot Name") { Text(pilotName ?? "—") }
                LabeledContent("Departure") {
                    Text(departure.map { $0.toTimeString() } ?? "—")
                }
                LabeledContent("Arrival") {
                    Text(arrival.map { $0.toTimeString() } ?? "—")
                }
                LabeledContent("Block Time") {
                    Text(blockTime.map { $0.toTimeString() } ?? "—")
                }
            }
        }
    }
}
