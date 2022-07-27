//
//  TimePicker.swift
//  
//
//  Created by Johan Nyman on 2022-07-26.
//

import UIKit

@objc public protocol TimePickerDelegate {
    func timePicker(_ picker:TimePicker, didReturnMinutes minutes:Int)
}

public class TimePicker: UIDatePicker {

    @IBOutlet public var timeDelegate:TimePickerDelegate?
        
    public var minutes: Int {
        get {
            let timeOffset = date.timeIntervalSince1970
            let minutes = timeOffset/60
            return Int(minutes)
        }
        set {
            date = Date(timeIntervalSince1970: Double(newValue * 60))
        }
    }
    
    public override func awakeFromNib()
    {
        super.awakeFromNib()
        setupSelf()
            }
    
    /* Make sure to register for control events when created from nib or programatically,
     *
     */
    private func setupSelf() {
        //Appearance
        preferredDatePickerStyle = .compact
        datePickerMode = .time
        minuteInterval = 1
        
        //Correct times
        locale = Locale(identifier: "sv")
        timeZone = TimeZone(identifier: "UTC")
        date = Date(timeIntervalSince1970: 0)
        
        //Action
        addTarget(self, action: #selector(timeChanged), for: .valueChanged)
    }
    
    @objc func timeChanged() {
        //Call delegate with minutes
        timeDelegate?.timePicker(self, didReturnMinutes: minutes)
    }
}
