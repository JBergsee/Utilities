//
//  File.swift
//
//
//  Created by Johan Nyman on 2022-02-23.
//

import UIKit
import AVFoundation //For authorization request
import PhotosUI //For PHPickerViewController


/// Presents a camera / photo-library picker and returns the selected image.
///
/// The consuming app's Info.plist **must** include:
/// - `NSCameraUsageDescription` — required for camera access.
///
/// Missing the key will cause a runtime crash when the camera is presented.
/// The photo library uses `PHPickerViewController` and needs no usage description.
@MainActor
open class ImagePicker {

    private weak var presentationController: UIViewController?

    public init(presentationController: UIViewController) {
        self.presentationController = presentationController
    }

    /// Presents the image picker and returns the selected image asynchronously.
    /// Returns `nil` if the user cancels, or throws `PermissionError` if camera access is denied.
    /// The photo library (PHPicker) needs no permission and is never blocked.
    ///
    @MainActor
    public func selectImage(from sourceView: UIView) async throws -> UIImage? {

        // Create the photo picker before the action sheet is shown, so the
        // out-of-process picker extension can start loading while the user
        // is still choosing a source.
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let photoPicker = PHPickerViewController(configuration: configuration)

        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = PickerCoordinator(continuation: continuation)
            photoPicker.delegate = coordinator

            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(title: "Take photo", style: .default) { [weak self] _ in
                    Task { @MainActor in
                        guard let self else {
                            coordinator.cancel()
                            return
                        }
                        // Camera permission is only needed (and requested) for this path.
                        guard await self.requestCameraAccess() else {
                            coordinator.fail(with: PermissionError.denied)
                            return
                        }
                        let picker = UIImagePickerController()
                        picker.sourceType = .camera
                        picker.allowsEditing = false
                        picker.mediaTypes = ["public.image"]
                        picker.delegate = coordinator
                        self.presentationController?.present(picker, animated: true)
                    }
                })
            }
            alert.addAction(UIAlertAction(title: "Photo library", style: .default) { [weak self] _ in
                // PHPicker runs out of process with deferred loading:
                // presents fast and requires no photo library permission.
                self?.presentationController?.present(photoPicker, animated: true)
            })
            /// On iPad the action sheet is shown in a popover and UIKit hides the Cancel button;
            /// tapping outside the popover cancels and returns `nil`.
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                coordinator.cancel()
            })

            if UIDevice.current.userInterfaceIdiom == .pad {
                alert.popoverPresentationController?.sourceView = sourceView
                alert.popoverPresentationController?.sourceRect = sourceView.bounds
                alert.popoverPresentationController?.permittedArrowDirections = [.down, .up]
            }

            self.presentationController?.present(alert, animated: true)
        }
    }

    /// Async wrapper around `AVCaptureDevice.requestAccess`.
    private func requestCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

//MARK: - Authorization

public enum PermissionError: Error, Sendable {
    case denied, restricted
}

//MARK: - Async picker coordinator

/// Per-call delegate that bridges UIImagePickerController callbacks to a CheckedContinuation.
/// Retains itself until the continuation is resumed, then releases.
private class PickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var continuation: CheckedContinuation<UIImage?, any Error>?
    private var retainCycle: PickerCoordinator?

    init(continuation: CheckedContinuation<UIImage?, any Error>) {
        self.continuation = continuation
        super.init()
        self.retainCycle = self
    }

    func cancel() {
        finish(with: nil)
    }

    func fail(with error: any Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        retainCycle = nil
    }

    private func finish(with image: UIImage?) {
        continuation?.resume(returning: image)
        continuation = nil
        retainCycle = nil
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        finish(with: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        finish(with: image)
    }
}

extension PickerCoordinator: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            // Empty results means the user cancelled.
            finish(with: nil)
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            // Completion is called on an arbitrary queue.
            Task { @MainActor in
                if let error {
                    self?.fail(with: error)
                } else {
                    self?.finish(with: object as? UIImage)
                }
            }
        }
    }
}
