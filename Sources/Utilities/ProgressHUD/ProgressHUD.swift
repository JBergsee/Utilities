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

    // When the HUD is shown in a scroll view we disable scrolling so touches
    // and pans don't slip past the overlay, restoring the previous value on hide.
    private weak var scrolledView: UIScrollView?
    private var previousScrollEnabled = true

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

        // The HUD is always added as a direct subview of the target view, so callers
        // never have to reason about the surrounding view hierarchy. For a scroll
        // view (e.g. a UITableView) we pin to its `frameLayoutGuide` rather than its
        // edges: that keeps the HUD fixed over the visible frame, doesn't scroll with
        // the content, and doesn't affect `contentSize`. We also disable scrolling
        // while the HUD is shown so pans don't slip past the overlay.
        let hostView = hostingController.view!
        view.addSubview(hostView)

        // Pin to the scroll view's frame guide (fixed over the visible frame) or,
        // for a regular view, to the view's own edges (full-bleed dim background).
        let leading: NSLayoutXAxisAnchor
        let trailing: NSLayoutXAxisAnchor
        let top: NSLayoutYAxisAnchor
        let bottom: NSLayoutYAxisAnchor
        if let scrollView = view as? UIScrollView {
            let guide = scrollView.frameLayoutGuide
            (leading, trailing, top, bottom) = (guide.leadingAnchor, guide.trailingAnchor, guide.topAnchor, guide.bottomAnchor)
            hud.scrolledView = scrollView
            hud.previousScrollEnabled = scrollView.isScrollEnabled
            scrollView.isScrollEnabled = false
        } else {
            (leading, trailing, top, bottom) = (view.leadingAnchor, view.trailingAnchor, view.topAnchor, view.bottomAnchor)
        }

        NSLayoutConstraint.activate([
            hostView.leadingAnchor.constraint(equalTo: leading),
            hostView.trailingAnchor.constraint(equalTo: trailing),
            hostView.topAnchor.constraint(equalTo: top),
            hostView.bottomAnchor.constraint(equalTo: bottom)
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

        // Restore scrolling if we disabled it when showing in a scroll view.
        scrolledView?.isScrollEnabled = previousScrollEnabled
        scrolledView = nil

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
