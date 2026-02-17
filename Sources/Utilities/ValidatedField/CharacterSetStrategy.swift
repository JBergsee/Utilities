//
//  CharacterSetStrategy.swift
//  Utilities
//
//  Created by Claude on 2026-02-10.
//

import UIKit

/// A validation strategy for free-text input constrained to a `CharacterSet`
/// and an optional maximum length.
///
/// Each keystroke is checked against the `allowed` character set. On commit,
/// the full string is validated for length and character membership.
///
/// ```swift
/// ValidatedField("Name", value: $name,
///                strategy: CharacterSetStrategy(allowed: .letters, maxLength: 50))
/// ```
public struct CharacterSetStrategy: ValidatedFieldStrategy, Sendable {
    public let allowed: CharacterSet
    public let maxLength: Int

    public init(allowed: CharacterSet, maxLength: Int = .max) {
        self.allowed = allowed
        self.maxLength = maxLength
    }

    public func allowsCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    public func parse(_ text: String) -> String? {
        text.isEmpty ? nil : text
    }

    public func validate(_ value: String) -> ValidationResult {
        if value.count > maxLength {
            return .invalid(message: "Max length is \(maxLength) characters")
        }
        let allAllowed = value.unicodeScalars.allSatisfy { allowed.contains($0) }
        if !allAllowed {
            return .invalid(message: "Contains characters that are not allowed")
        }
        return .valid
    }

    public func format(_ value: String) -> String {
        value
    }

    public var keyboardType: UIKeyboardType { .default }
}
