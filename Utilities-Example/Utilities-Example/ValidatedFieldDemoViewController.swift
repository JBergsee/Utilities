//
//  ValidatedFieldDemoViewController.swift
//  Utilities-Example
//
//  Created by Claude on 2026-02-10.
//

import UIKit
import SwiftUI
import Utilities

// MARK: - Demo View Controller

/// Hosts the SwiftUI `ValidatedFieldDemoView` inside a `UIHostingController`.
@available(iOS 18.0, *)
class ValidatedFieldDemoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ValidatedField Demo"

        let hostingController = UIHostingController(rootView: ValidatedFieldDemoView())
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

/// A single enum representing every focusable field across all form sections.
/// Owned by the top-level container and passed down via `FocusState` bindings,
/// this enables cross-container focus chaining — fields in different SwiftUI
/// subviews can advance focus to one another because they share the same enum.
private enum FormField: Hashable {
    case name, age, fuel, maxWeight
}

/// Character set shared by all name fields in the demo.
private let nameAllowedCharacters: CharacterSet = {
    var cs = CharacterSet.letters
    cs.insert(charactersIn: " -")
    return cs
}()

// MARK: - Demo SwiftUI View

@available(iOS 18.0, *)
private struct ValidatedFieldDemoView: View {

    @FocusState private var focus: FormField?

    // Bound values
    @State private var name: String?
    @State private var age: Int?
    @State private var fuel: Double?
    @State private var maxWeight: Double?

    // Standalone fields (no focus chain)
    @State private var standaloneInt: Int?
    @State private var standaloneFloat: Double?
    @State private var standaloneText: String?

    // Inline validation demo
    @State private var inlineValue: Int?

    var body: some View {
        Form {
            // MARK: 1 — Basic fields (no focus chain)
            Section("Basic Fields") {
                ValidatedField("Integer (0–100)", value: $standaloneInt,
                               strategy: IntegerRangeStrategy(min: 0, max: 100))
                ValidatedField("Float (0–999.99)", value: $standaloneFloat,
                               strategy: FloatingPointRangeStrategy(min: 0, max: 999.99, decimals: 5))

                ValidatedField("Name (letters, max 30)", value: $standaloneText,
                               strategy: CharacterSetStrategy(allowed: nameAllowedCharacters, maxLength: 30))
            }

            // MARK: 2 — Cross-container focus chain
            //
            // The focus chain flows: name → age → fuel → maxWeight → dismiss.
            // Each section receives the same `$focus` binding, so the chain
            // works even though fields live in separate subviews.

            Section("Pilot Info (focus chain)") {
                PilotSection(focus: $focus, name: $name, age: $age)
            }

            Section("Aircraft Data (focus chain)") {
                AircraftSection(focus: $focus, fuel: $fuel, maxWeight: $maxWeight)
            }

            // MARK: 3 — Inline validation mode
            Section("Inline Validation") {
                ValidatedField("Score (1–10)", value: $inlineValue,
                               strategy: IntegerRangeStrategy(min: 1, max: 10))
                    .inlineValidation()
            }

            // MARK: 4 — Live readout
            Section("Live Values") {
                LabeledContent("Name") { Text(name ?? "—") }
                LabeledContent("Age") { Text(age.map { "\($0)" } ?? "—") }
                LabeledContent("Fuel") {
                    if let fuel { Text(fuel, format: .number.precision(.fractionLength(1))) }
                    else { Text("—") }
                }
                LabeledContent("Max Weight") {
                    if let maxWeight { Text(maxWeight, format: .number.precision(.fractionLength(1))) }
                    else { Text("—") }
                }
                LabeledContent("Standalone Int") { Text(standaloneInt.map { "\($0)" } ?? "—") }
                LabeledContent("Standalone Float") {
                    if let standaloneFloat { Text(standaloneFloat, format: .number.precision(.fractionLength(2))) }
                    else { Text("—") }
                }
                LabeledContent("Standalone Text") { Text(standaloneText ?? "—") }
                LabeledContent("Inline Score") { Text(inlineValue.map { "\($0)" } ?? "—") }
            }
        }
    }
}

// MARK: - Sub-sections demonstrating cross-container focus

/// Contains the name and age fields. Receives the shared focus binding
/// so focus can chain into the next section.
@available(iOS 18.0, *)
private struct PilotSection: View {
    var focus: FocusState<FormField?>.Binding
    @Binding var name: String?
    @Binding var age: Int?

    var body: some View {
        ValidatedField("Pilot Name", value: $name,
                       strategy: CharacterSetStrategy(allowed: nameAllowedCharacters, maxLength: 50),
                       focus: focus, equals: .name, next: .age)
        ValidatedField("Age", value: $age,
                       strategy: IntegerRangeStrategy(min: 16, max: 99),
                       focus: focus, equals: .age, next: .fuel)
    }
}

/// Contains the fuel and max-weight fields. The last field (`maxWeight`) has
/// `next: nil`, so pressing Return dismisses the keyboard.
@available(iOS 18.0, *)
private struct AircraftSection: View {
    var focus: FocusState<FormField?>.Binding
    @Binding var fuel: Double?
    @Binding var maxWeight: Double?

    var body: some View {
        ValidatedField("Fuel (kg)", value: $fuel,
                       strategy: FloatingPointRangeStrategy(min: 0, max: 50000, decimals: 1),
                       focus: focus, equals: .fuel, next: .maxWeight)
        ValidatedField("Max Weight (kg)", value: $maxWeight,
                       strategy: FloatingPointRangeStrategy(min: 1000, max: 600000, decimals: 1),
                       focus: focus, equals: .maxWeight, next: nil)
    }
}
