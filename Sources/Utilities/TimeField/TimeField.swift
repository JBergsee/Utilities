//
//  TimeField.swift
//  Utilities
//
//  Created by Claude on 2026-02-10.
//

import SwiftUI

// MARK: - TimeFieldMode

/// Controls whether a ``TimeField`` represents a wall-clock time or a duration.
public enum TimeFieldMode: Sendable {
    /// Wall-clock time — picker defaults to the current time when the value is nil.
    case time
    /// Duration / interval — picker defaults to 00:00 when the value is nil.
    case interval
}

// MARK: - TimeFieldConversion

/// Pure-logic helpers for converting between minutes-since-midnight and `Date`.
/// Extracted as a non-availability-constrained enum so unit tests can access them freely.
public enum TimeFieldConversion {

    /// Converts minutes since midnight to a `Date` at that time on the Unix epoch day (UTC).
    public static func minutesToDate(_ minutes: Int) -> Date {
        Date(timeIntervalSince1970: Double(minutes * 60))
    }

    /// Extracts total minutes since midnight (UTC) from a `Date`.
    public static func dateToMinutes(_ date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
}

// MARK: - TimeField

/// A SwiftUI form field that presents a wheels-style time picker in a popover.
///
/// The field stores its value as `Int?` representing total minutes since midnight.
/// It supports the same `FocusState`-based focus chain pattern as ``ValidatedField``,
/// so both component types can coexist in a single focus chain.
///
/// ## Basic Usage (no focus chain)
/// ```swift
/// @State private var departure: Int?
///
/// TimeField("Departure", value: $departure, mode: .time)
/// ```
///
/// ## Focus Chain
/// ```swift
/// enum Field: Hashable { case dep, arr, blockTime }
///
/// @FocusState private var focus: Field?
///
/// TimeField("Departure", value: $dep, mode: .time,
///           focus: $focus, equals: .dep, next: .arr)
/// TimeField("Arrival", value: $arr, mode: .time,
///           focus: $focus, equals: .arr, next: .blockTime)
/// TimeField("Block", value: $block, mode: .interval,
///           focus: $focus, equals: .blockTime, next: nil)
/// ```
@available(iOS 18.0, *)
public struct TimeField<FocusValue: Hashable>: View {

    // MARK: Configuration

    private let title: String
    @Binding private var value: Int?
    private let mode: TimeFieldMode
    private let onCommit: ((Int?) -> Void)?

    // Focus chain (optional)
    private var focusBinding: FocusState<FocusValue?>.Binding?
    private let focusTag: FocusValue?
    private let nextFocusTag: FocusValue?

    // MARK: Internal state

    @State private var showPicker = false
    @State private var pickerDate = Date(timeIntervalSince1970: 0)
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    // MARK: Initialisers

    /// Creates a time field without focus chain participation.
    public init(
        _ title: String,
        value: Binding<Int?>,
        mode: TimeFieldMode = .time,
        onCommit: ((Int?) -> Void)? = nil
    ) where FocusValue == Never {
        self.title = title
        self._value = value
        self.mode = mode
        self.onCommit = onCommit
        self.focusBinding = nil
        self.focusTag = nil
        self.nextFocusTag = nil
    }

    /// Creates a time field that participates in a shared focus chain.
    ///
    /// - Parameters:
    ///   - title: Label text displayed on the leading edge.
    ///   - value: Two-way binding to the time in minutes since midnight; `nil` when unset.
    ///   - mode: `.time` (wall-clock) or `.interval` (duration).
    ///   - focus: A `FocusState` binding shared across form sections.
    ///   - equals: The enum case this field corresponds to.
    ///   - next: The enum case to activate on commit, or `nil` to end the chain.
    ///   - onCommit: Optional closure called when the value changes via Set or Remove.
    public init(
        _ title: String,
        value: Binding<Int?>,
        mode: TimeFieldMode = .time,
        focus: FocusState<FocusValue?>.Binding,
        equals: FocusValue,
        next: FocusValue?,
        onCommit: ((Int?) -> Void)? = nil
    ) {
        self.title = title
        self._value = value
        self.mode = mode
        self.onCommit = onCommit
        self.focusBinding = focus
        self.focusTag = equals
        self.nextFocusTag = next
    }

    // MARK: Body

    public var body: some View {
        textField
            .popover(isPresented: $showPicker) {
                TimePickerPopover(date: $pickerDate, onSet: setTime, onRemove: removeTime)
                    .presentationCompactAdaptation(.popover)
            }
            .onChange(of: showPicker) { _, isShowing in
                if !isShowing && isFocused {
                    isFocused = false
                    focusBinding?.wrappedValue = nil
                }
            }
            .onChange(of: value) { _, newValue in
                if newValue != nil {
                    if text != displayText { text = displayText }
                } else if !isFocused {
                    text = ""
                }
            }
            .onAppear {
                text = displayText
            }
    }

    @ViewBuilder
    private var textField: some View {
        let field = TextField(title, text: $text)
            .submitLabel(nextFocusTag != nil ? .next : .done)
            .autocorrectionDisabled()
            .onSubmit {
                dismissAndAdvance()
            }
            .onChange(of: text) { _, newValue in
                if newValue != displayText {
                    text = displayText
                }
            }
            .onChange(of: isFocused) { _, nowFocused in
                if nowFocused && !showPicker {
                    openPicker()
                }
            }

        if let binding = focusBinding, let tag = focusTag {
            field
                .focused($isFocused)
                .focused(binding, equals: tag)
        } else {
            field
                .focused($isFocused)
        }
    }

    // MARK: Display

    private var displayText: String {
        value.map { $0.toTimeString() } ?? ""
    }

    // MARK: Picker

    private func openPicker() {
        if let minutes = value {
            pickerDate = TimeFieldConversion.minutesToDate(minutes)
        } else {
            pickerDate = mode == .time ? Date() : Date(timeIntervalSince1970: 0)
        }
        showPicker = true
    }

    private func setTime(_ date: Date) {
        value = TimeFieldConversion.dateToMinutes(date)
        onCommit?(value)
        dismissAndAdvance()
    }

    private func removeTime() {
        value = nil
        onCommit?(nil)
        dismissAndAdvance()
    }

    private func dismissAndAdvance() {
        showPicker = false
        isFocused = false
        text = displayText
        Task { @MainActor in
            advanceFocus()
        }
    }

    // MARK: Focus chain

    private func advanceFocus() {
        focusBinding?.wrappedValue = nextFocusTag
    }
}
