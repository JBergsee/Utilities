//
//  ValidatedField.swift
//  Utilities
//
//  Created by Claude on 2026-02-10.
//

import SwiftUI

// MARK: - ValidatedField

/// A generic SwiftUI text field that filters keystrokes, validates on commit,
/// and optionally participates in a cross-container focus chain.
///
/// `ValidatedField` is parameterised by a ``ValidatedFieldStrategy`` that
/// defines how characters are filtered, how text is parsed into a typed value,
/// and how that value is validated and formatted.
///
/// ## Basic Usage (no focus chain)
/// ```swift
/// @State private var age: Int?
///
/// ValidatedField("Age", value: $age,
///                strategy: IntegerRangeStrategy(min: 0, max: 150))
/// ```
///
/// ## Cross-Container Focus Chain
///
/// Define a `Hashable` enum for all focusable fields. Pass the same
/// `@FocusState` binding into every section so focus can advance across
/// view boundaries.
///
/// ```swift
/// enum FormField: Hashable { case name, age, weight }
///
/// struct MyForm: View {
///     @FocusState private var focus: FormField?
///     @State private var name: String?
///     @State private var age: Int?
///     @State private var weight: Double?
///
///     var body: some View {
///         ValidatedField("Name", value: $name,
///                        strategy: CharacterSetStrategy(allowed: .letters),
///                        focus: $focus, equals: .name, next: .age)
///         ValidatedField("Age", value: $age,
///                        strategy: IntegerRangeStrategy(min: 0, max: 150),
///                        focus: $focus, equals: .age, next: .weight)
///         ValidatedField("Weight", value: $weight,
///                        strategy: FloatingPointRangeStrategy(min: 0, max: 500),
///                        focus: $focus, equals: .weight, next: nil)
///     }
/// }
/// ```
///
/// When `next` is non-nil the return key shows **Next**; when `nil` it shows
/// **Done** and dismisses the keyboard.
@available(iOS 18.0, *)
public struct ValidatedField<Strategy: ValidatedFieldStrategy, FocusValue: Hashable>: View {

    // MARK: Configuration

    private let title: String
    @Binding private var value: Strategy.Value?
    private let strategy: Strategy
    private let onCommit: ((Strategy.Value?) -> Void)?

    // Focus chain (optional)
    private var focusBinding: FocusState<FocusValue?>.Binding?
    private let focusTag: FocusValue?
    private let nextFocusTag: FocusValue?

    // Modifiers (stored as state so view modifiers can set them)
    @Environment(\.validationMessageOverride) private var messageOverride
    @Environment(\.maxInputLength) private var maxInputLength
    @Environment(\.inlineValidationEnabled) private var inlineValidation

    // MARK: Internal state

    @FocusState private var isFocused: Bool
    @State private var text: String = ""
    @State private var selectedText: TextSelection?
    @State private var validationError: String?
    @State private var showAlert = false
    @State private var shouldReselectOnAlertDismiss = false

    // MARK: Initialisers

    /// Creates a validated field without focus chain participation.
    public init(
        _ title: String,
        value: Binding<Strategy.Value?>,
        strategy: Strategy,
        onCommit: ((Strategy.Value?) -> Void)? = nil
    ) where FocusValue == Never {
        self.title = title
        self._value = value
        self.strategy = strategy
        self.onCommit = onCommit
        self.focusBinding = nil
        self.focusTag = nil
        self.nextFocusTag = nil
    }

    /// Creates a validated field that participates in a shared focus chain.
    ///
    /// - Parameters:
    ///   - title: Placeholder text.
    ///   - value: Two-way binding to the parsed value; `nil` when empty.
    ///   - strategy: The validation strategy instance.
    ///   - focus: A `FocusState` binding shared across form sections.
    ///   - equals: The enum case this field corresponds to.
    ///   - next: The enum case to activate on commit, or `nil` to dismiss the keyboard.
    ///   - onCommit: Optional closure called when editing ends with a valid value.
    public init(
        _ title: String,
        value: Binding<Strategy.Value?>,
        strategy: Strategy,
        focus: FocusState<FocusValue?>.Binding,
        equals: FocusValue,
        next: FocusValue?,
        onCommit: ((Strategy.Value?) -> Void)? = nil
    ) {
        self.title = title
        self._value = value
        self.strategy = strategy
        self.onCommit = onCommit
        self.focusBinding = focus
        self.focusTag = equals
        self.nextFocusTag = next
    }

    // MARK: Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            textField
            if inlineValidation, let error = validationError, !isFocused {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .alert("Validation Error", isPresented: $showAlert) {
            Button("Discard") {
                text = ""
                value = nil
                validationError = nil
            }
            Button("Edit") {
                shouldReselectOnAlertDismiss.toggle()
                isFocused = true
            }
        } message: {
            Text(messageOverride ?? validationError ?? "")
        }
        .onChange(of: shouldReselectOnAlertDismiss) {
            Task { @MainActor in
                isFocused = true
                if let tag = focusTag {
                    focusBinding?.wrappedValue = tag
                }
                selectedText = TextSelection(range: text.startIndex..<text.endIndex)
            }
        }
        .onChange(of: value) { _, newValue in
            // Sync external binding changes into the text field
            if let v = newValue {
                let formatted = strategy.format(v)
                if text != formatted { text = formatted }
            } else if !isFocused {
                text = ""
            }
        }
        .onAppear {
            if let v = value {
                text = strategy.format(v)
            }
        }
    }

    @ViewBuilder
    private var textField: some View {
        let field = TextField(title, text: $text, selection: $selectedText)
            .keyboardType(strategy.keyboardType)
            .submitLabel(nextFocusTag != nil ? .next : .done)
            .autocorrectionDisabled()
            .onSubmit {
                commitValue()
                advanceFocus()
            }
            .onChange(of: text) { oldValue, newValue in
                let filtered = filterText(newValue)
                if filtered != newValue {
                    text = filtered
                }
            }
            .onChange(of: isFocused) { wasFocused, nowFocused in
                if nowFocused {
                    validationError = nil
                } else if wasFocused {
                    commitValue()
                }
            }

        // Two `.focused()` modifiers are needed when a focus chain is active:
        // `$isFocused` (Bool) drives the Edit-button refocus and focus-loss detection,
        // while the enum binding handles the cross-container focus chain.
        if let binding = focusBinding, let tag = focusTag {
            field
                .focused($isFocused)
                .focused(binding, equals: tag)
        } else {
            field
                .focused($isFocused)
        }
    }

    // MARK: Private helpers

    /// Filters pasted or typed text through the strategy's character filter
    /// and the optional max-length constraint.
    private func filterText(_ input: String) -> String {
        var result = String(input.filter { strategy.allowsCharacter($0) })
        if let max = maxInputLength, result.count > max {
            result = String(result.prefix(max))
        }
        return result
    }

    /// Parses, validates, and commits the current text.
    private func commitValue() {
        // Empty field → nil binding
        guard !text.isEmpty else {
            value = nil
            validationError = nil
            onCommit?(nil)
            return
        }

        // Parse
        guard let parsed = strategy.parse(text) else {
            let msg = messageOverride ?? "\"\(text)\" is not a valid value"
            validationError = msg
            presentError()
            return
        }

        // Validate
        let result = strategy.validate(parsed)
        if result.isValid {
            value = parsed
            validationError = nil
            onCommit?(parsed)
        } else {
            let msg = messageOverride ?? result.message ?? "Invalid value"
            validationError = msg
            presentError()
        }
    }

    private func presentError() {
        if !inlineValidation {
            showAlert = true
        }
    }

    private func advanceFocus() {
        guard let binding = focusBinding else { return }
        if let next = nextFocusTag {
            binding.wrappedValue = next
        } else {
            binding.wrappedValue = nil
        }
    }
}

// MARK: - Environment Keys for View Modifiers

private struct ValidationMessageOverrideKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

private struct MaxInputLengthKey: EnvironmentKey {
    static let defaultValue: Int? = nil
}

private struct InlineValidationKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var validationMessageOverride: String? {
        get { self[ValidationMessageOverrideKey.self] }
        set { self[ValidationMessageOverrideKey.self] = newValue }
    }

    var maxInputLength: Int? {
        get { self[MaxInputLengthKey.self] }
        set { self[MaxInputLengthKey.self] = newValue }
    }

    var inlineValidationEnabled: Bool {
        get { self[InlineValidationKey.self] }
        set { self[InlineValidationKey.self] = newValue }
    }
}

// MARK: - Public View Modifiers

public extension View {
    /// Overrides the default validation error message for a ``ValidatedField``.
    func validationMessage(_ message: String?) -> some View {
        environment(\.validationMessageOverride, message)
    }

    /// Limits the number of characters a ``ValidatedField`` accepts during typing.
    func maxInputLength(_ length: Int) -> some View {
        environment(\.maxInputLength, length)
    }

    /// Enables inline error text below the field instead of an alert dialog.
    func inlineValidation(_ enabled: Bool = true) -> some View {
        environment(\.inlineValidationEnabled, enabled)
    }
}
