//
//  TimePickerViewController.swift
//  
//
//  Created by Johan Nyman on 2022-11-27.
//

import UIKit

@MainActor public protocol TimePickerViewControllerDelegate: AnyObject {
    func timePickerViewControllerReturnedTime(_ date: Date)
    func timePickerViewControllerRemovedTime()
}

class TimePickerViewController: UIViewController {
    
    @IBOutlet var picker: UIDatePicker?
    
    weak var delegate: TimePickerViewControllerDelegate?
    
    var date: Date {
        get {
            picker?.date ?? Date()
        }
        set {
            picker?.date = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker?.timeZone = TimeZone(identifier: "UTC")
        picker?.date = Date(timeIntervalSince1970: 0)
    }
    
    
    ///Remove view and update time in delegate
    @IBAction func doneTapped() {
        delegate?.timePickerViewControllerReturnedTime(date)
    }
    
    ///Remove view and return time -1
    @IBAction func removeTapped() {
        delegate?.timePickerViewControllerRemovedTime()
    }
}
