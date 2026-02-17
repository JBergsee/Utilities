//
//  IntegerRangeStrategy.swift
//  Utilities
//
//  Created by Claude on 2026-02-10.
//

import UIKit

/// A validation strategy for integer values within a closed range.
///
/// Accepts digits and the minus sign during typing. On commit, the text is
/// parsed as an `Int` and checked against `min` ... `max`.
///
/// ```swift
/// ValidatedField("Age", value: $age,
///                strategy: IntegerRangeStrategy(min: 0, max: 150))
/// ```
public struct IntegerRangeStrategy: ValidatedFieldStrategy, Sendable {
    public let min: Int
    public let max: Int

    public init(min: Int, max: Int) {
        precondition(min <= max, "IntegerRangeStrategy: min (\(min)) must be <= max (\(max))")
        self.min = min
        self.max = max
    }

    public func allowsCharacter(_ character: Character) -> Bool {
        character.isNumber || character == "-"
    }

    public func parse(_ text: String) -> Int? {
        Int(text)
    }

    public func validate(_ value: Int) -> ValidationResult {
        if value < min {
            return .tooLow(message: "\(value) is below minimum value of \(min)")
        }
        if value > max {
            return .tooHigh(message: "\(value) is above maximum value of \(max)")
        }
        return .valid
    }

    public func format(_ value: Int) -> String {
        "\(value)"
    }

    public var keyboardType: UIKeyboardType { .numberPad }
}
