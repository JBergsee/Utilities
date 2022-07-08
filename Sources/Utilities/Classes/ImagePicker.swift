//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-02-23.
//

import UIKit
import AVFoundation //For authorization request



import UIKit

public protocol ImagePickerDelegate: AnyObject {
    func didSelect(image: UIImage?)
    func didFail(error:PermissionError)
}

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
        self.pickerController.allowsEditing = true
        self.pickerController.mediaTypes = ["public.image"]
    }
    
    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }
        
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }
    
    public func present(from sourceView: UIView) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let action = self.action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
        //Photolibrary and camera roll looks the same, so use just library
        if let action = self.action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }
        
        checkPermissions { granted in
            //We are now coming back on a background thread!
            if granted {
                DispatchQueue.main.async {
                    self.presentationController?.present(alertController, animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate?.didFail(error: PermissionError.denied)
                }
            }
        }
    }
    
    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)
        self.delegate?.didSelect(image: image)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        self.pickerController(picker, didSelect: image)
    }
}

extension ImagePicker: UINavigationControllerDelegate {
    
}

//MARK: - Authorization

public enum PermissionError: Error {
    case denied, restricted
}

private enum Permission {
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
