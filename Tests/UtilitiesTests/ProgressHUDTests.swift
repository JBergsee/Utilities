//
//  ProgressHUDTests.swift
//  UtilitiesTests
//
//  Created by Johan Nyman on 2025-02-09.
//

import Testing
import UIKit
@testable import Utilities

struct ProgressHUDStateTests {

    @Test func defaultValues() {
        let state = ProgressHUDState()
        #expect(state.mode == .indeterminate)
        #expect(state.label == nil)
        #expect(state.progress == 0)
        #expect(state.progressObject == nil)
        #expect(state.showsBackground == false)
        #expect(state.isSquare == false)
        #expect(state.buttonTitle == nil)
        #expect(state.buttonAction == nil)
    }

    @Test func modeChanges() {
        let state = ProgressHUDState()

        state.mode = .annularDeterminate
        #expect(state.mode == .annularDeterminate)

        state.mode = .horizontalBar
        #expect(state.mode == .horizontalBar)

        state.mode = .customView(systemImage: "checkmark")
        #expect(state.mode == .customView(systemImage: "checkmark"))

        state.mode = .indeterminate
        #expect(state.mode == .indeterminate)
    }

    @Test func labelUpdates() {
        let state = ProgressHUDState()
        state.label = "Connecting"
        #expect(state.label == "Connecting")

        state.label = "Receiving flight info 1 / 5"
        #expect(state.label == "Receiving flight info 1 / 5")

        state.label = nil
        #expect(state.label == nil)
    }

    @Test func progressValues() {
        let state = ProgressHUDState()
        state.progress = 0.5
        #expect(state.progress == 0.5)

        state.progress = 1.0
        #expect(state.progress == 1.0)

        state.progress = 0.0
        #expect(state.progress == 0.0)
    }

    @Test func buttonConfiguration() {
        let state = ProgressHUDState()
        var actionCalled = false

        state.buttonTitle = "Stop"
        state.buttonAction = { actionCalled = true }

        #expect(state.buttonTitle == "Stop")
        state.buttonAction?()
        #expect(actionCalled)
    }

    @Test func modeEquality() {
        #expect(ProgressHUDMode.indeterminate == .indeterminate)
        #expect(ProgressHUDMode.annularDeterminate == .annularDeterminate)
        #expect(ProgressHUDMode.horizontalBar == .horizontalBar)
        #expect(ProgressHUDMode.customView(systemImage: "checkmark") ==
                .customView(systemImage: "checkmark"))
        #expect(ProgressHUDMode.customView(systemImage: "checkmark") !=
                .customView(systemImage: "xmark"))
        #expect(ProgressHUDMode.indeterminate != .annularDeterminate)
    }

    @Test func modeTransitionsSequence() {
        let state = ProgressHUDState()

        // Simulate the SelectFlight flow
        state.mode = .indeterminate
        state.label = "Connecting"
        #expect(state.mode == .indeterminate)

        state.mode = .annularDeterminate
        state.progress = 0.5
        state.label = "Receiving flight info 3 / 5"
        #expect(state.mode == .annularDeterminate)
        #expect(state.progress == 0.5)

        state.mode = .customView(systemImage: "checkmark")
        state.label = "Done!"
        state.isSquare = true
        #expect(state.mode == .customView(systemImage: "checkmark"))
        #expect(state.isSquare)
    }
}

@MainActor
struct ProgressHUDTests {

    @Test func showAddsSubview() {
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let initialSubviewCount = parentView.subviews.count

        let hud = ProgressHUD.show(in: parentView, animated: false)

        #expect(parentView.subviews.count == initialSubviewCount + 1)
        hud.hide(animated: false)
    }

    @Test func hideRemovesSubview() {
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let initialSubviewCount = parentView.subviews.count

        let hud = ProgressHUD.show(in: parentView, animated: false)
        #expect(parentView.subviews.count == initialSubviewCount + 1)

        hud.hide(animated: false)
        #expect(parentView.subviews.count == initialSubviewCount)
    }

    @Test func staticHideForView() {
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let initialSubviewCount = parentView.subviews.count

        _ = ProgressHUD.show(in: parentView, animated: false)
        #expect(parentView.subviews.count == initialSubviewCount + 1)

        ProgressHUD.hide(for: parentView, animated: false)
        #expect(parentView.subviews.count == initialSubviewCount)
    }

    @Test func showReplacesExistingHUD() {
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let initialSubviewCount = parentView.subviews.count

        _ = ProgressHUD.show(in: parentView, animated: false)
        _ = ProgressHUD.show(in: parentView, animated: false)

        // Should still be only one HUD subview
        #expect(parentView.subviews.count == initialSubviewCount + 1)

        ProgressHUD.hide(for: parentView, animated: false)
        #expect(parentView.subviews.count == initialSubviewCount)
    }

    @Test func stateMutationsAfterShow() {
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let hud = ProgressHUD.show(in: parentView, animated: false)

        hud.state.label = "Testing"
        #expect(hud.state.label == "Testing")

        hud.state.mode = .annularDeterminate
        hud.state.progress = 0.75
        #expect(hud.state.mode == .annularDeterminate)
        #expect(hud.state.progress == 0.75)

        hud.hide(animated: false)
    }

    @Test func hideForViewWithNoHUD() {
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let initialSubviewCount = parentView.subviews.count

        // Should not crash
        ProgressHUD.hide(for: parentView, animated: false)
        #expect(parentView.subviews.count == initialSubviewCount)
    }
}
