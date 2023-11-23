//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-05-06.
//

import Foundation
import UIKit
import Logging

public extension UIViewController {
    
    @objc(showAlertWithTitle:message:buttonTitle:)
    func showAlert(title: String?, message: String? = "", buttonTitle: String) {
        showAlert(title: title, message: message, buttonTitle: buttonTitle, completion: nil)
    }
    
    @objc(showAlertWithTitle:message:actionButtons:)
    func showAlert(title: String?, message: String? = "", actions: Array<UIAlertAction>) {
        
        showAlert(title:title, message:message, actions:actions, completion:nil)
    }
    
    
    @objc(showAlertWithTitle:message:buttonTitle:completion:)
    func showAlert(title: String?, message: String? = "", buttonTitle: String, completion:(() -> Void)? = nil) {
        
        let defaultAction = UIAlertAction(title: buttonTitle,
                                          style: .default,
                                          handler: nil)
        showAlert(title: title, message: message, actions: [defaultAction], completion: completion)
    }
    
    @objc(showAlertWithTitle:message:actionButtons:completion:)
    func showAlert(title: String?, message: String? = "", actions: Array<UIAlertAction>, completion: (() -> Void)? = nil) {
        
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        
        for action in actions {
            alert.addAction(action)
        }
        
        present(alert, animated: true, completion: completion)
        
    }
    
    @objc(currentViewController)
    static func current() -> UIViewController {
        
        // Find best view controller
        
        guard let rootVC = UIApplication.shared.delegate?.window??.rootViewController else {
            Log.fault(message: "Could not get root ViewController.", in: .functionality)
            return UIViewController()
        }
        return findTopViewControllerFor(rootVC)
    }
    
    /* Recursive internal method to the above */
    private static func findTopViewControllerFor(_ vc:UIViewController) -> UIViewController {
        
        if (vc.presentedViewController != nil) {
            
            // Return presented view controller
            return findTopViewControllerFor(vc.presentedViewController!)
            
        } else if let svc = vc as? UISplitViewController {
            
            // Return right hand side
            if (svc.viewControllers.count > 0) {
                return findTopViewControllerFor(svc.viewControllers.last!)
            } else {
                return vc
            }
        } else if let nc = vc as? UINavigationController {
            
            // Return top view
            if (nc.viewControllers.count > 0) {
                return findTopViewControllerFor(nc.topViewController!)
            } else {
                return vc
            }
        } else if let tbc = vc as? UITabBarController {
            
            // Return visible view
            if (tbc.viewControllers?.count ?? 0) > 0 {
                return findTopViewControllerFor(tbc.selectedViewController!)
            } else {
                return vc
            }
        } else {
            
            //Any other view controller type, return last child view controller
            Log.debug(message:"Returning \(type(of:vc)) for presentation.", in: .functionality)
            return vc
        }
    }
}
