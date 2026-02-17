//
//  FloatingPointRangeStrategy.swift
//  Utilities
//
//  Created by Claude on 2026-02-10.
//

import UIKit

/// A validation strategy for floating-point values within a closed range.
///
/// Accepts digits, the decimal point, and the minus sign during typing.
/// On commit, the text is parsed as a `Double` and checked against `min` ... `max`.
/// The `decimals` parameter sets the maximum precision — input is rounded
/// to this many decimal places during parsing. Formatting preserves the
/// user's entered precision (no trailing zeros are added).
///
/// ```swift
/// ValidatedField("Weight", value: $weight,
///                strategy: FloatingPointRangeStrategy(min: 0, max: 500, decimals: 1))
/// ```
public struct FloatingPointRangeStrategy: ValidatedFieldStrategy, Sendable {
    public let min: Double
    public let max: Double
    public let decimals: Int

    public init(min: Double, max: Double, decimals: Int = 2) {
        precondition(min <= max, "FloatingPointRangeStrategy: min (\(min)) must be <= max (\(max))")
        self.min = min
        self.max = max
        self.decimals = decimals
    }

    public func allowsCharacter(_ character: Character) -> Bool {
        character.isNumber || character == "." || character == "-"
    }

    public func parse(_ text: String) -> Double? {
        guard let raw = Double(text) else { return nil }
        let factor = pow(10.0, Double(decimals))
        return (raw * factor).rounded() / factor
    }

    public func validate(_ value: Double) -> ValidationResult {
        if value < min {
            return .tooLow(message: String(format: "%.\(decimals)f is below minimum value of %.\(decimals)f", value, min))
        }
        if value > max {
            return .tooHigh(message: String(format: "%.\(decimals)f is above maximum value of %.\(decimals)f", value, max))
        }
        return .valid
    }

    public func format(_ value: Double) -> String {
        // Format up to `decimals` places, then strip trailing zeros
        // so we don't display more precision than the user entered.
        var result = String(format: "%.\(decimals)f", value)
        if result.contains(".") {
            while result.hasSuffix("0") { result.removeLast() }
            if result.hasSuffix(".") { result.removeLast() }
        }
        return result
    }

    public var keyboardType: UIKeyboardType { .decimalPad }
}
