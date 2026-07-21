//
//  UIApplication+badge.swift
//
//
//  Created by Johan Bergsee on 2026-07-22.
//
//

import UIKit
import UserNotifications
import JBLogging

public extension UIApplication {

    private static let badgeCountKey = "badgeCountOnIcon"

    /// The badge count this app last set. Backed by UserDefaults, since the system
    /// provides no non-deprecated getter for the app icon's badge number.
    var storedBadgeCount: Int {
        UserDefaults.standard.integer(forKey: Self.badgeCountKey)   // 0 when unset
    }

    /// Sets the app icon badge to `count`, clamped to be non-negative.
    ///
    /// Uses `UNUserNotificationCenter.setBadgeCount(_:withCompletionHandler:)`
    /// (the replacement for the deprecated `applicationIconBadgeNumber`). The
    /// stored count is only updated once the system confirms the change succeeded.
    func setBadgeCount(_ count: Int) {
        let clamped = Self.clampedBadgeCount(current: count, delta: 0)
        UNUserNotificationCenter.current().setBadgeCount(clamped) { error in
            if let error {
                Log.error(error, message: "Failed to set badge count to \(clamped).", in: .functionality)
                return
            }
            UserDefaults.standard.set(clamped, forKey: Self.badgeCountKey)
        }
    }

    /// Increases the app icon badge by `amount` (default 1).
    func increaseBadgeCount(by amount: Int = 1) {
        setBadgeCount(Self.clampedBadgeCount(current: storedBadgeCount, delta: amount))
    }

    /// Decreases the app icon badge by `amount` (default 1), never going below 0.
    func decreaseBadgeCount(by amount: Int = 1) {
        setBadgeCount(Self.clampedBadgeCount(current: storedBadgeCount, delta: -amount))
    }

    /// Pure helper: the badge count never drops below zero.
    private static func clampedBadgeCount(current: Int, delta: Int) -> Int {
        max(0, current + delta)
    }
}
