//
//  File.swift
//
//
//  Created by Johan Nyman on 2022-02-23.
//

import UIKit
import AVFoundation //For authorization request


public protocol ImagePickerDelegate: AnyObject {
    func didSelect(image: UIImage?)
    func didFail(error:PermissionError)
}

/// Presents a camera / photo-library picker and returns the selected image.
///
/// The consuming app's Info.plist **must** include:
/// - `NSCameraUsageDescription` — required for camera access.
/// - `NSPhotoLibraryUsageDescription` — required for photo library access.
///
/// Missing either key will cause a runtime crash when the picker is presented.
open class ImagePicker: NSObject {

    private let pickerController: UIImagePickerController
    private var permission: Permission = .denied
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate?) {

        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false //true will crop to a square by default
        self.pickerController.mediaTypes = ["public.image"]
    }

    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [weak self] _ in
            self?.pickerController.sourceType = type
            self?.presentationController?.present(self!.pickerController, animated: true)
        }
    }

    /// Presents the image picker and returns the selected image asynchronously.
    /// Returns `nil` if the user cancels, or throws `PermissionError` if denied.
    @MainActor
    public func selectImage(from sourceView: UIView) async throws -> UIImage? {
        guard await requestCameraAccess() else {
            throw PermissionError.denied
        }

        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = PickerCoordinator(continuation: continuation)

            let picker = UIImagePickerController()
            picker.allowsEditing = false
            picker.mediaTypes = ["public.image"]
            picker.delegate = coordinator

            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(title: "Take photo", style: .default) { [weak self] _ in
                    picker.sourceType = .camera
                    self?.presentationController?.present(picker, animated: true)
                })
            }
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                alert.addAction(UIAlertAction(title: "Photo library", style: .default) { [weak self] _ in
                    picker.sourceType = .photoLibrary
                    self?.presentationController?.present(picker, animated: true)
                })
            }
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
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            permission = .granted
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permission = granted ? .granted : .denied
            return granted
        case .denied:
            permission = .denied
            return false
        case .restricted:
            permission = .restricted
            return false
        @unknown default:
            permission = .denied
            return false
        }
    }

    @available(*, deprecated, message: "Use async selectImage(from:) instead")
    public func present(from sourceView: UIView) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        //Cameraaction
        if let action = action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }

        //Photolibrary and camera roll looks the same, so use just library
        if let action = action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }

        //Cancelaction
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }

        checkPermissions { [weak self] granted in
            //We are now coming back on a background thread!
            if granted {
                DispatchQueue.main.async {
                    self?.presentationController?.present(alertController, animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    self?.delegate?.didFail(error: PermissionError.denied)
                }
            }
        }
    }

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)
        delegate?.didSelect(image: image)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.editedImage] as? UIImage {
            //Edited image, only available if allowsEditing = true
            pickerController(picker, didSelect: image)
        } else if let image = info[.originalImage] as? UIImage {
            //use original image
            pickerController(picker, didSelect: image)
        } else {
            //No image
            pickerController(picker, didSelect: nil)
        }
    }
}

//Required for UIImagePickerController
extension ImagePicker: UINavigationControllerDelegate {}

//MARK: - Authorization

public enum PermissionError: Error, Sendable {
    case denied, restricted
}

private enum Permission: Sendable {
    case granted, denied, restricted
}

extension ImagePicker {

    private func checkPermissions(then:@escaping (_ granted:Bool) ->()) {

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            permission = .granted
            then(true)
            break

        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.permission = .granted
                    then(true)
                } else {
                    self.permission = .denied
                    then(false)
                }
            }
            break

        case .denied: // The user has previously denied access.
            permission = .denied
            then(false)
            break

        case .restricted: // The user can't grant access due to restrictions.
            permission = .restricted
            then(false)
            break

        @unknown default:
            permission = .denied
            then(false)
            break
        }
    }
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
