//
//  ValidatedFieldStrategy.swift
//  Utilities
//
//  Created by Claude on 2026-02-10.
//

import UIKit

// MARK: - Validation Result

/// The outcome of validating a parsed value against a strategy's constraints.
public enum ValidationResult: Equatable, Sendable {
    /// The value is within the acceptable range / passes all checks.
    case valid
    /// The value is below the minimum (numeric strategies).
    case tooLow(message: String)
    /// The value is above the maximum (numeric strategies).
    case tooHigh(message: String)
    /// General validation failure (unparseable input, character violations, length exceeded).
    case invalid(message: String)

    /// `true` when the result is `.valid`.
    public var isValid: Bool {
        self == .valid
    }

    /// The human-readable error message, or `nil` when valid.
    public var message: String? {
        switch self {
        case .valid: return nil
        case .tooLow(let msg): return msg
        case .tooHigh(let msg): return msg
        case .invalid(let msg): return msg
        }
    }
}

// MARK: - Validation Strategy Protocol

/// A type that defines how a `ValidatedField` filters keystrokes, parses text,
/// validates the parsed value, and formats it back to a display string.
///
/// Conform to this protocol to create custom validation strategies beyond the
/// built-in `IntegerRangeStrategy`, `FloatingPointRangeStrategy`, and
/// `CharacterSetStrategy`.
///
/// ## Example — Custom Percentage Strategy
/// ```swift
/// struct PercentageStrategy: ValidatedFieldStrategy {
///     func allowsCharacter(_ character: Character) -> Bool {
///         character.isNumber || character == "."
///     }
///     func parse(_ text: String) -> Double? { Double(text) }
///     func validate(_ value: Double) -> ValidationResult {
///         if value < 0   { return .tooLow(message: "Must be at least 0%") }
///         if value > 100  { return .tooHigh(message: "Cannot exceed 100%") }
///         return .valid
///     }
///     func format(_ value: Double) -> String { String(format: "%.1f", value) }
///     var keyboardType: UIKeyboardType { .decimalPad }
/// }
/// ```
public protocol ValidatedFieldStrategy {
    /// The parsed value type produced by this strategy.
    associatedtype Value: Equatable

    /// Returns `true` if the character should be accepted during typing.
    /// Called per-character on each keystroke and when filtering pasted text.
    func allowsCharacter(_ character: Character) -> Bool

    /// Attempts to parse the raw text into a typed value.
    /// Return `nil` when the text cannot be converted (e.g. empty string, non-numeric).
    func parse(_ text: String) -> Value?

    /// Validates a successfully parsed value against the strategy's constraints.
    func validate(_ value: Value) -> ValidationResult

    /// Formats a value back into a display string for the text field.
    func format(_ value: Value) -> String

    /// The keyboard type most appropriate for this strategy.
    var keyboardType: UIKeyboardType { get }
}
