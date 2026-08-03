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

        // A HUD must overlay *and* block interaction. Adding it directly inside a
        // scroll view (e.g. a UITableView) fails on both counts: its edge anchors
        // resolve against the scrollable content (so the HUD lands at the content
        // origin), and the scroll view's own pan/selection gestures still fire
        // because a gesture recognizer receives touches on its view and subviews.
        // So for a scroll view, host the HUD in its nearest non-scrolling ancestor
        // and pin it to the scroll view's frame — a sibling on top of the scroll
        // view. Touches then hit the overlay instead of the scroll view.
        let hostView = hostingController.view!
        let container: UIView
        let anchorView: UIView
        if let scrollView = view as? UIScrollView, let ancestor = scrollView.superview {
            container = ancestor
            anchorView = scrollView
        } else {
            container = view
            anchorView = view
        }

        container.addSubview(hostView)
        NSLayoutConstraint.activate([
            hostView.leadingAnchor.constraint(equalTo: anchorView.leadingAnchor),
            hostView.trailingAnchor.constraint(equalTo: anchorView.trailingAnchor),
            hostView.topAnchor.constraint(equalTo: anchorView.topAnchor),
            hostView.bottomAnchor.constraint(equalTo: anchorView.bottomAnchor)
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
