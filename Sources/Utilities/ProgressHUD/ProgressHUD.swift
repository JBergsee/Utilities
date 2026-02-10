//
//  ProgressHUD.swift
//  Utilities
//
//  Created by Johan Nyman on 2025-02-09.
//

import UIKit
import SwiftUI

/// UIKit wrapper for the SwiftUI-based ProgressHUDView.
///
/// Usage:
/// ```
/// let hud = ProgressHUD.show(in: view)
/// hud.state.label = "Loading..."
/// hud.state.mode = .annularDeterminate
/// hud.state.progress = 0.5
/// hud.hide()
/// ```

@MainActor
public class ProgressHUD {

    /// The observable state driving the HUD's appearance.
    public let state: ProgressHUDState

    private var hostingController: UIHostingController<ProgressHUDView>?
    private weak var parentView: UIView?

    private static var activeHUDs: NSMapTable<UIView, ProgressHUD> = .weakToStrongObjects()

    private init(state: ProgressHUDState) {
        self.state = state
    }

    /// Shows a new ProgressHUD in the given view.
    @discardableResult
    public static func show(in view: UIView, animated: Bool = true) -> ProgressHUD {
        // Hide any existing HUD on this view first
        hide(for: view, animated: false)

        let hudState = ProgressHUDState()
        let hud = ProgressHUD(state: hudState)
        hud.parentView = view

        let hudView = ProgressHUDView(state: hudState)
        let hostingController = UIHostingController(rootView: hudView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hud.hostingController = hostingController

        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        activeHUDs.setObject(hud, forKey: view)

        if animated {
            hostingController.view.alpha = 0
            UIView.animate(withDuration: 0.2) {
                hostingController.view.alpha = 1
            }
        }

        return hud
    }

    /// Hides and removes any active ProgressHUD from the given view.
    public static func hide(for view: UIView, animated: Bool = true) {
        guard let hud = activeHUDs.object(forKey: view) else { return }
        hud.hide(animated: animated)
    }

    /// Hides and removes this HUD.
    public func hide(animated: Bool = true) {
        guard let hostingView = hostingController?.view else { return }

        if let parentView {
            ProgressHUD.activeHUDs.removeObject(forKey: parentView)
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                hostingView.alpha = 0
            }, completion: { _ in
                hostingView.removeFromSuperview()
            })
        } else {
            hostingView.removeFromSuperview()
        }

        hostingController = nil
    }
}
