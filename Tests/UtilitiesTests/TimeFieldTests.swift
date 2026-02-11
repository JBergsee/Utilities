//
//  TimeFieldTests.swift
//  Utilities
//
//  Created by Claude on 2026-02-10.
//

import Testing
import Foundation
@testable import Utilities

// MARK: - TimeField Logic Tests

struct TimeFieldTests {

    // MARK: Minutes → formatted string

    @Test func zeroMinutesFormatsAsZeroZero() {
        #expect(0.toTimeString() == "00:00")
    }

    @Test func maxMinutesFormatsCorrectly() {
        #expect(1439.toTimeString() == "23:59")
    }

    @Test func midDayFormatsCorrectly() {
        #expect(720.toTimeString() == "12:00")
    }

    @Test func singleDigitHourAndMinute() {
        // 1 hour 5 minutes = 65 minutes
        #expect(65.toTimeString() == "01:05")
    }

    @Test func negativeMinutesReturnsEmpty() {
        #expect((-1).toTimeString() == "")
    }

    // MARK: Minutes → Date → Minutes round-trip

    @Test func roundTripZero() {
        let date = TimeFieldConversion.minutesToDate(0)
        let result = TimeFieldConversion.dateToMinutes(date)
        #expect(result == 0)
    }

    @Test func roundTripMaxValue() {
        let date = TimeFieldConversion.minutesToDate(1439)
        let result = TimeFieldConversion.dateToMinutes(date)
        #expect(result == 1439)
    }

    @Test func roundTripMidDay() {
        let date = TimeFieldConversion.minutesToDate(720)
        let result = TimeFieldConversion.dateToMinutes(date)
        #expect(result == 720)
    }

    @Test func roundTripArbitraryValue() {
        let date = TimeFieldConversion.minutesToDate(137)
        let result = TimeFieldConversion.dateToMinutes(date)
        #expect(result == 137)
    }

    // MARK: minutesToDate produces expected epoch

    @Test func minutesToDateProducesCorrectEpoch() {
        let date = TimeFieldConversion.minutesToDate(90) // 1h30m
        #expect(date.timeIntervalSince1970 == 5400.0)
    }

    // MARK: dateToMinutes extracts correct components

    @Test func dateToMinutesFromEpoch() {
        let date = Date(timeIntervalSince1970: 0)
        #expect(TimeFieldConversion.dateToMinutes(date) == 0)
    }

    @Test func dateToMinutesFromKnownTime() {
        // 14:30 UTC = 870 minutes
        let date = Date(timeIntervalSince1970: 870 * 60)
        #expect(TimeFieldConversion.dateToMinutes(date) == 870)
    }

    // MARK: Mode defaults

    @Test func intervalModeDefaultIsZero() {
        // In interval mode, a nil value should default the picker to epoch (00:00)
        let defaultDate = Date(timeIntervalSince1970: 0)
        #expect(TimeFieldConversion.dateToMinutes(defaultDate) == 0)
    }

    // MARK: Edge cases

    @Test func wrapsAt1440() {
        // 1440 minutes = 24:00, which wraps via toTimeString
        #expect(1440.toTimeString() == "00:00")
    }

    @Test func justOverMidnight() {
        #expect(1.toTimeString() == "00:01")
    }

    @Test func lastMinuteBeforeMidnight() {
        #expect(1439.toTimeString() == "23:59")
    }
}
