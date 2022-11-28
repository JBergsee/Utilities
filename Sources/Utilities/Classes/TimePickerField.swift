//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-11-27.
//

import UIKit

@objc public protocol TimePickerFieldDelegate where Self: UIViewController {
    
    ///Time in minutes or -1 if not set or unparseable
    func timePickerField(_ timePickerField: TimePickerField, didReturnMinutes minutes: Int)
}


@objc public class TimePickerField: ChainedField {
    
    @IBOutlet public weak var timeDelegate: TimePickerFieldDelegate?
    
    private var pickerView = TimePickerViewController(nibName: "TimePickerView", bundle: .module)
    
    
    public override func awakeFromNib() {
        super.awakeFromNib()
    
        //Set self as UITextfield delegate to be able to present popup instead of keyboard
        delegate = self
        pickerView.delegate = self
    }
    
    
    //MARK: - Return values from the string
    
    /* returns nil if not set */
    private var minutes: Int? {
        let times = text?.components(separatedBy: ":") ?? []
        
        switch (times.count) {
        case 0:
            //nothing there
            break;
            
        case 1:
            //only minutes
            return Int(times[0])
            
        case 2:
            //hours and minutes
            return Int(times[1])
            
        default:
            break;
        }
        return nil
    }
    
    /* returns nil if not set */
    private var hours: Int? {
        let times = text?.components(separatedBy: ":") ?? []
        
        switch (times.count) {
        case 0:
            //nothing there
            break;
            
        case 1,2:
            //only minutes, or hours and minutes
            return Int(times[0])
            
        default:
            break;
        }
        return nil
    }
    
    /* returns nil if not set */
    public var timeInMinutes: Int? {
        get {
        guard let mins = minutes, let hrs = hours, let str = self.text else { return nil }
        
        //Take into account a deleted figure!! return nil
        //Assume that the value is removed, or half removed when less than h:mm
        guard (str.count >= 4) else { return nil }
        
        return hrs * 60 + mins
        }
        set {
            text = newValue?.toTimeString()
        }
    }
    
}

//MARK: - Text Field Delegate

extension TimePickerField: UITextFieldDelegate {
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        //Show a popup with the pickerView
        pickerView.modalPresentationStyle = .popover
        pickerView.preferredContentSize = CGSize(width: 232, height: 232)
        pickerView.popoverPresentationController?.sourceView = self
        
        timeDelegate?.present(pickerView, animated: true)
        
        //Set current value in the pickerView
        let minutes = timeInMinutes ?? 0
        pickerView.date = Date(timeIntervalSince1970: Double(minutes*60))
        
        //Do not show the keyboard
        return false;
        
    }
}

extension TimePickerField: TimePickerViewControllerDelegate {
    
    ///Set time in textfield
    public func timePickerViewControllerReturnedTime(_ date: Date) {
        
        //Format the output
        //(using a cached date formatter in Utilities extension
        let time = date.toString(using: .HHmm)
        
        //Handle as if it was written manually.
        text = time
        //And call delegate
        timeDelegate?.timePickerField(self, didReturnMinutes: timeInMinutes ?? -1)
        
        //Dismiss picker and...
        timeDelegate?.dismiss(animated: true) {
            //Switch to next textfield
            self.nextField?.becomeFirstResponder()
        }
    }
    
    public func timePickerViewControllerRemovedTime() {
        //Remove time in textfield
        text = ""
        
        //And call delegate
        timeDelegate?.timePickerField(self, didReturnMinutes: -1)
        
        //Dismiss picker and...
        timeDelegate?.dismiss(animated: true) {
            //Switch to next textfield
            self.nextField?.becomeFirstResponder()
        }
    }
}
