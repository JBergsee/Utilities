//
//  DocumentPhotoEditor.swift
//  Utilities
//
//  Created by Claude on 2026-09-11.
//

import UIKit
import SwiftUI

/// Presents a full-screen document photo editor modally and returns the
/// edited image, or `nil` if the user cancels.
///
/// One call, one continuation — no delegates for the caller to implement.
/// Works identically from a UIKit `UIViewController` or a SwiftUI `View`
/// (via `capturingHostingController(_:)` to obtain a presenter).
///
/// UIKit call site:
/// ```swift
/// let edited = await DocumentPhotoEditor.present(image: photo, over: self)
/// if let edited {
///     // use it
/// } else {
///     // user cancelled
/// }
/// ```
///
/// SwiftUI call site:
/// ```swift
/// struct MyView: View {
///     @State private var hostingController: UIViewController?
///     @State private var photo: UIImage
///
///     var body: some View {
///         Button("Edit Photo") {
///             Task {
///                 guard let hostingController else { return }
///                 if let edited = await DocumentPhotoEditor.present(image: photo, over: hostingController) {
///                     photo = edited
///                 }
///             }
///         }
///         .capturingHostingController($hostingController)
///     }
/// }
/// ```
@MainActor
public enum DocumentPhotoEditor {
    /// Presents a full-screen document editor modally over `presenter`.
    /// Suspends until the user taps Done or Cancel (or dismisses via swipe,
    /// which is treated as Cancel).
    /// - Parameters:
    ///   - image: the image to edit.
    ///   - presenter: the view controller to present the editor over.
    ///   - autoEnhanceEnabled: whether Auto Enhance is on when the image loads.
    ///     Only the initial state — the user can toggle it in the editor. `true`
    ///     (the default) suits document scans; pass `false` for general photos,
    ///     so the editor opens showing the image as it was taken.
    /// - Returns: the edited `UIImage` at the original image's resolution and
    ///   orientation if the user tapped Done; `nil` on cancel (this includes
    ///   the rare case where the final render fails).
    public static func present(
        image: UIImage,
        over presenter: UIViewController,
        autoEnhanceEnabled: Bool = true
    ) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let bridge = EditorPresentationBridge(continuation: continuation, presenter: presenter)
            bridge.present(image: image, autoEnhanceEnabled: autoEnhanceEnabled)
        }
    }
}

/// Bridges `DocumentPhotoEditorView`'s Done/Cancel closures (and swipe-to-dismiss,
/// via `UIAdaptivePresentationControllerDelegate`) to a single `CheckedContinuation`,
/// guarding against double-resume. Mirrors `PopoverPicker`'s continuation idiom:
/// the continuation is stored as an `Optional` and every resume path also nils it
/// out, so a later callback firing (e.g. the delegate, after Done already resumed)
/// is a no-op. Self-retains until resumed so it survives independent of the caller.
@MainActor
private final class EditorPresentationBridge: NSObject {
    private var continuation: CheckedContinuation<UIImage?, Never>?
    private weak var presenter: UIViewController?
    private weak var hostingController: UIViewController?
    private var retainCycle: EditorPresentationBridge?

    init(continuation: CheckedContinuation<UIImage?, Never>, presenter: UIViewController) {
        self.continuation = continuation
        self.presenter = presenter
        super.init()
        retainCycle = self
    }

    func present(image: UIImage, autoEnhanceEnabled: Bool) {
        let view = DocumentPhotoEditorView(
            image: image,
            autoEnhanceEnabled: autoEnhanceEnabled,
            onDone: { [weak self] edited in
                self?.finish(with: edited, dismiss: true)
            },
            onCancel: { [weak self] in
                self?.finish(with: nil, dismiss: true)
            })
        let host = UIHostingController(rootView: view)
        host.modalPresentationStyle = .fullScreen
        host.presentationController?.delegate = self
        hostingController = host
        presenter?.present(host, animated: true)
    }

    /// `dismiss: true` for the Done/Cancel closure paths, where the editor is
    /// still presented and must be dismissed here. `dismiss: false` for the
    /// `presentationControllerDidDismiss` path, where the dismissal has already
    /// happened by the time the delegate callback fires.
    private func finish(with image: UIImage?, dismiss: Bool) {
        guard let continuation else {
            return
        }
        self.continuation = nil
        if dismiss {
            hostingController?.dismiss(animated: true)
        }
        continuation.resume(returning: image)
        retainCycle = nil
    }
}

extension EditorPresentationBridge: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finish(with: nil, dismiss: false)
    }
}
