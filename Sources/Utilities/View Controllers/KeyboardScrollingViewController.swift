//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-03-06.
//

import Foundation
import UIKit

open class KeyboardScrollingViewController : UIViewController, UITextFieldDelegate {
    
    /* The active field is the view that must be visible when the keyboard is shown.
     * It is normally a textfield, but may also be a textview, label or button, or any other view
     * that shall remain visible when the keyboard is shown.
     * The subclass is responsible of setting the _activeField when it becomes activated
     * i.e. when textFieldDidBeginEditing
     * And returning it to nil when textFieldDidEndEditing
     */
    public var _activeField:UIView?
    
    /* The scrollView may be connected to this view in Interface Builder,
     * or may be the scrollView of a PageContentController.
     */
    @IBOutlet public var scrollView:UIScrollView!
    
    
    public override func viewWillAppear(_ animated:Bool){
        super.viewWillAppear(animated)
        registerForKeyboardNotifications()
    }
    
    public override func viewWillDisappear(_ animated:Bool){
        //Save the last input if required:
        self.view.endEditing(false)//Ask the current view to resign first responder
        deRegisterForKeyboardNotifications()
        super.viewWillDisappear(animated)
    }
    
    
    private func registerForKeyboardNotifications() {
        // call the 'keyboardDidShow' function when the view controller receive the notification that a keyboard did show
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        
        // call the 'keyboardWillHide' function when the view controller receive notification that keyboard is going to be hidden
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func deRegisterForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    //MARK: - Keyboard handling
    
    /* In order to scroll when keyboard appears (and disappears).
     Based on Apple documentation
     https://developer.apple.com/Library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html#//apple_ref/doc/uid/TP40009542-CH5-SW1
     */
    
    // Called when the UIKeyboardDidShowNotification is sent.
    @objc func keyboardDidShow(notification: NSNotification) {
        
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size else {
            // if keyboard size is not available for some reason, dont do anything
            return
        }
        
        //Insert appropriate content insets
        var contentInsets = self.scrollView.contentInset //take the old one
        contentInsets.bottom = keyboardSize.height //set space for keyboard below
        scrollView.contentInset = contentInsets  //and set.
        scrollView.scrollIndicatorInsets = contentInsets
        
        // If active text field is hidden by keyboard, scroll to make it visible
        if let viewFrame = _activeField?.frame {
            var contentRect = self.scrollView.frame
            contentRect.size.height -= keyboardSize.height
            
            if (!contentRect.contains(CGPoint(x: viewFrame.origin.x, y: viewFrame.origin.y+viewFrame.height))) {
                self.scrollView.scrollRectToVisible(viewFrame,  animated:true)
            }

        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        var contentInsets = self.scrollView.contentInset //take the old one
        contentInsets.bottom = 0 //remove space for keyboard below
        scrollView.contentInset = contentInsets  //and set.
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    
    //MARK: - TextField Delegates
    /* This may be done in the subclass */

    public func textFieldDidBeginEditing(_ textField:UITextField)
    {
        _activeField = textField
    }

    public func textFieldDidEndEditing(_ textField: UITextField)
    {
        _activeField = nil
    }

}

