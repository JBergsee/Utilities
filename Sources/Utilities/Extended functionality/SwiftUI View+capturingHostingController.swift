//
//  SwiftUI View+capturingHostingController.swift
//  Utilities
//
//  Created by Claude on 2026-09-11.
//

import SwiftUI
import UIKit

public extension View {
    /// Captures the `UIViewController` hosting this view's hierarchy into `controller`,
    /// for use with `DocumentPhotoEditor.present(image:over:)` from SwiftUI call sites
    /// that don't already have a `UIViewController` in scope.
    ///
    /// Usage:
    /// ```swift
    /// struct MyView: View {
    ///     @State private var hostingController: UIViewController?
    ///     var body: some View {
    ///         content
    ///             .capturingHostingController($hostingController)
    ///     }
    /// }
    /// ```
    func capturingHostingController(_ controller: Binding<UIViewController?>) -> some View {
        background(HostingControllerCapture(controller: controller))
    }
}

/// Zero-size, invisible helper that walks up its own `.parent` containment
/// chain to find the `UIViewController` hosting this view, reporting itself
/// if there's no meaningful parent. Deliberately scoped to the view's own
/// hierarchy — does not scrape `UIApplication.shared` windows.
private struct HostingControllerCapture: UIViewControllerRepresentable {
    @Binding var controller: UIViewController?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Deferred to the next runloop turn so the binding isn't written to
        // mid SwiftUI view-update transaction.
        DispatchQueue.main.async {
            var candidate = uiViewController
            while let parent = candidate.parent {
                candidate = parent
            }
            if controller !== candidate {
                controller = candidate
            }
        }
    }
}
