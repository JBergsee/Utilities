//
//  TimePicker.swift
//  
//
//  Created by Johan Nyman on 2022-07-26.
//

import UIKit

@objc public protocol TimePickerDelegate {
    func timePicker(_ picker: TimePicker, didReturnMinutes minutes: Int)
}

public class TimePicker: UIDatePicker {
    
    @IBOutlet public weak var timeDelegate: TimePickerDelegate?
    
    public var minutes: Int {
        get {
            let timeOffset = date.timeIntervalSince1970
            //if negative, add 24 hours
            let minutes = timeOffset >= 0 ? timeOffset/60 : timeOffset/60 + 24*60
            return Int(minutes)
        }
        set {
            valueIsPicked = (newValue >= 0)
            //Treat negative values as zero
            let minutes = newValue > -1 ? newValue * 60 : 0
            date = Date(timeIntervalSince1970: Double(minutes))
        }
    }
    private var valueIsPicked: Bool = false
    
    public var isSet: Bool {
        valueIsPicked
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupSelf()
    }
    
    /**
     * Make sure to register for control events when created from nib or programatically,
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
        valueIsPicked = true
        //Call delegate with minutes
        timeDelegate?.timePicker(self, didReturnMinutes: minutes)
    }
}
