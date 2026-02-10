//
//  ValidatedFieldTests.swift
//  Utilities
//
//  Created by Claude on 2026-02-10.
//

import Testing
import Foundation
@testable import Utilities

// MARK: - ValidationResult Tests

struct ValidationResultTests {

    @Test func validIsValid() {
        let result = ValidationResult.valid
        #expect(result.isValid)
        #expect(result.message == nil)
    }

    @Test func tooLowIsNotValid() {
        let result = ValidationResult.tooLow(message: "too low")
        #expect(!result.isValid)
        #expect(result.message == "too low")
    }

    @Test func tooHighIsNotValid() {
        let result = ValidationResult.tooHigh(message: "too high")
        #expect(!result.isValid)
        #expect(result.message == "too high")
    }

    @Test func invalidIsNotValid() {
        let result = ValidationResult.invalid(message: "bad input")
        #expect(!result.isValid)
        #expect(result.message == "bad input")
    }

    @Test func equatability() {
        #expect(ValidationResult.valid == ValidationResult.valid)
        #expect(ValidationResult.tooLow(message: "a") == ValidationResult.tooLow(message: "a"))
        #expect(ValidationResult.tooLow(message: "a") != ValidationResult.tooLow(message: "b"))
        #expect(ValidationResult.tooHigh(message: "x") != ValidationResult.invalid(message: "x"))
    }
}

// MARK: - IntegerRangeStrategy Tests

struct IntegerRangeStrategyTests {

    let strategy = IntegerRangeStrategy(min: 0, max: 100)

    // MARK: allowsCharacter

    @Test func allowsDigits() {
        for c in "0123456789" {
            #expect(strategy.allowsCharacter(c), "Should allow digit \(c)")
        }
    }

    @Test func allowsMinus() {
        #expect(strategy.allowsCharacter("-"))
    }

    @Test func rejectsLetters() {
        #expect(!strategy.allowsCharacter("a"))
        #expect(!strategy.allowsCharacter("Z"))
    }

    @Test func rejectsDecimalPoint() {
        #expect(!strategy.allowsCharacter("."))
    }

    // MARK: parse

    @Test func parsesValidIntegers() {
        #expect(strategy.parse("42") == 42)
        #expect(strategy.parse("-5") == -5)
        #expect(strategy.parse("0") == 0)
    }

    @Test func parseReturnsNilForNonInteger() {
        #expect(strategy.parse("") == nil)
        #expect(strategy.parse("abc") == nil)
        #expect(strategy.parse("3.14") == nil)
    }

    // MARK: validate

    @Test func validatesWithinRange() {
        #expect(strategy.validate(0) == .valid)
        #expect(strategy.validate(50) == .valid)
        #expect(strategy.validate(100) == .valid)
    }

    @Test func validatesTooLow() {
        let result = strategy.validate(-1)
        #expect(!result.isValid)
        if case .tooLow(let msg) = result {
            #expect(msg.contains("-1"))
            #expect(msg.contains("0"))
        } else {
            Issue.record("Expected .tooLow, got \(result)")
        }
    }

    @Test func validatesTooHigh() {
        let result = strategy.validate(101)
        #expect(!result.isValid)
        if case .tooHigh(let msg) = result {
            #expect(msg.contains("101"))
            #expect(msg.contains("100"))
        } else {
            Issue.record("Expected .tooHigh, got \(result)")
        }
    }

    // MARK: format

    @Test func formatsValue() {
        #expect(strategy.format(42) == "42")
        #expect(strategy.format(-7) == "-7")
    }
}

// MARK: - FloatingPointRangeStrategy Tests

struct FloatingPointRangeStrategyTests {

    let strategy = FloatingPointRangeStrategy(min: 0.0, max: 100.0, decimals: 2)

    // MARK: allowsCharacter

    @Test func allowsDigitsAndPointAndMinus() {
        for c in "0123456789.-" {
            #expect(strategy.allowsCharacter(c), "Should allow '\(c)'")
        }
    }

    @Test func rejectsLetters() {
        #expect(!strategy.allowsCharacter("a"))
        #expect(!strategy.allowsCharacter("Z"))
    }

    // MARK: parse

    @Test func parsesValidDoubles() {
        #expect(strategy.parse("3.14") == 3.14)
        #expect(strategy.parse("-2.5") == -2.5)
        #expect(strategy.parse("0") == 0.0)
        #expect(strategy.parse("100") == 100.0)
    }

    @Test func parseReturnsNilForInvalid() {
        #expect(strategy.parse("") == nil)
        #expect(strategy.parse("abc") == nil)
        #expect(strategy.parse("..") == nil)
    }

    // MARK: validate

    @Test func validatesWithinRange() {
        #expect(strategy.validate(0.0) == .valid)
        #expect(strategy.validate(50.5) == .valid)
        #expect(strategy.validate(100.0) == .valid)
    }

    @Test func validatesTooLow() {
        let result = strategy.validate(-0.01)
        #expect(!result.isValid)
        if case .tooLow = result { } else {
            Issue.record("Expected .tooLow, got \(result)")
        }
    }

    @Test func validatesTooHigh() {
        let result = strategy.validate(100.01)
        #expect(!result.isValid)
        if case .tooHigh = result { } else {
            Issue.record("Expected .tooHigh, got \(result)")
        }
    }

    // MARK: format

    @Test func formatsWithoutTrailingZeros() {
        #expect(strategy.format(3.14159) == "3.14")
        #expect(strategy.format(42.0) == "42")
        #expect(strategy.format(42.10) == "42.1")
        #expect(strategy.format(3.14) == "3.14")
    }

    @Test func customDecimalPlaces() {
        let s = FloatingPointRangeStrategy(min: 0, max: 1000, decimals: 1)
        #expect(s.format(3.14159) == "3.1")
        #expect(s.format(3.0) == "3")
    }

    @Test func parseRoundsToDecimalPlaces() {
        // decimals: 2 — rounds to 2 decimal places
        #expect(strategy.parse("3.14159") == 3.14)
        #expect(strategy.parse("3.145") == 3.15)
        #expect(strategy.parse("99.999") == 100.0)

        // decimals: 1
        let s1 = FloatingPointRangeStrategy(min: 0, max: 1000, decimals: 1)
        #expect(s1.parse("3.14") == 3.1)
        #expect(s1.parse("3.15") == 3.2)
    }
}

// MARK: - CharacterSetStrategy Tests

struct CharacterSetStrategyTests {

    let strategy = CharacterSetStrategy(allowed: .letters, maxLength: 10)

    // MARK: allowsCharacter

    @Test func allowsLetters() {
        #expect(strategy.allowsCharacter("a"))
        #expect(strategy.allowsCharacter("Z"))
        #expect(strategy.allowsCharacter("ö"))
    }

    @Test func rejectsDigits() {
        #expect(!strategy.allowsCharacter("1"))
        #expect(!strategy.allowsCharacter("0"))
    }

    @Test func rejectsSpecialCharacters() {
        #expect(!strategy.allowsCharacter("!"))
        #expect(!strategy.allowsCharacter(" "))
    }

    // MARK: parse

    @Test func parsesNonEmptyString() {
        #expect(strategy.parse("Hello") == "Hello")
    }

    @Test func parseReturnsNilForEmpty() {
        #expect(strategy.parse("") == nil)
    }

    // MARK: validate

    @Test func validatesWithinLength() {
        #expect(strategy.validate("Hello") == .valid)
        #expect(strategy.validate("TenLetters") == .valid) // exactly 10
    }

    @Test func validatesTooLong() {
        let result = strategy.validate("ElevenChars")
        #expect(!result.isValid)
        if case .invalid(let msg) = result {
            #expect(msg.contains("10"))
        } else {
            Issue.record("Expected .invalid, got \(result)")
        }
    }

    @Test func validatesDisallowedCharacters() {
        let result = strategy.validate("abc 123")
        #expect(!result.isValid)
        if case .invalid = result { } else {
            Issue.record("Expected .invalid, got \(result)")
        }
    }

    // MARK: format

    @Test func formatReturnsIdentity() {
        #expect(strategy.format("Hello") == "Hello")
    }

    // MARK: Unlimited length

    @Test func unlimitedLength() {
        let s = CharacterSetStrategy(allowed: .letters)
        let long = String(repeating: "A", count: 1000)
        #expect(s.validate(long) == .valid)
    }

    // MARK: Custom character set with spaces

    @Test func customCharacterSetWithSpaces() {
        var cs = CharacterSet.letters
        cs.insert(charactersIn: " ")
        let s = CharacterSetStrategy(allowed: cs, maxLength: 50)
        #expect(s.allowsCharacter(" "))
        #expect(s.validate("John Doe") == .valid)
    }
}
