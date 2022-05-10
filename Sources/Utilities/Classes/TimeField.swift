//
//  TimeField.swift
//  
//
//  Created by Johan Nyman on 2022-03-08.
//

import UIKit

@objc public protocol TimeFieldDelegate {
    
    @objc(presentTimeAlertFor:message:changeAction:cancelAction:)
    func presentAlertFor(_ timeField:TimeField, message:String, changeAction:UIAlertAction, cancelAction:UIAlertAction)
    
    @objc optional func timeFieldDidBeginEditing(_ timeField:TimeField)
    @objc optional func timeField(_ timeField:TimeField, didReturnMinutes minutes:Int)
}



public class TimeField: ChainedField, UITextFieldDelegate {
    
    @IBOutlet public var timeDelegate:TimeFieldDelegate?
    
    
    override init(frame:CGRect)
    {
        super.init(frame: frame)
        setupSelf()
        setupBar()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSelf()
        setupBar()
    }
    
    public override func awakeFromNib()
    {
        super.awakeFromNib()
        setupSelf()
        setupBar()
    }
    
    /* Make sure to register for control events when created from nib or programatically,
     * Set as its own delegate,
     * Set keyboard type,
     */
    private func setupSelf() {
        self.addTarget(self, action: #selector(insertColonIfAppropriate), for: .editingChanged)
        self.delegate = self
        self.keyboardType = .numberPad
    }
    
    
    
    //Setup a now button on the bar and disable autocorrection
    private func setupBar()
    {
        
        //Create a "NOW" button
        let clockIcon = UIImage(systemName: "clock")
        let clockButton = UIButton.systemButton(with: clockIcon!, target: self, action: #selector(setCurrentTime))
        clockButton.setTitle("Now", for: .normal)
        let nowButton = UIBarButtonItem(customView: clockButton)
        //or simply
        //let nowButton = UIBarButtonItem(image: clockIcon, style: .plain, target: self, action: #selector(setCurrentTime))
        
        //Add flexible space to try to push the button to the far right.
        let flex = UIBarButtonItem.flexibleSpace()
        
        // Create an item group.
        let group = UIBarButtonItemGroup(barButtonItems: [flex, nowButton], representativeItem: nil)
        
        //Add button but hide the rest of the bar above the keyboard
        let bar = self.inputAssistantItem
        bar.leadingBarButtonGroups = [];
        bar.trailingBarButtonGroups = [group];
        
        //Disable autocorrection
        self.autocorrectionType = .no
        
        
    }
    
    
    @objc private func setCurrentTime()
    {
        //Get the time
        let now = Date()
        
        //Format the output
        //(using a cached date formatter in Utilities extension
        
        let time = now.formatToString(using: .HHmm)
        Log.debug(message: "Current time (UTC): \(time)", in: .functionality)
        
        
        //Handle as if it was written manually.
        self.text = time
        
        //press "enter", this will call the delegate and eventually move to the next field.
        let tReturn = textFieldShouldReturn(self)
        
        
        //If not we do it manually:
        if (!tReturn) {
            //Switch to next textfield
            nextField?.becomeFirstResponder()
            print("Code should not come here, something is wrong with the responderchain on \(self)")
        }
    }
    
    //MARK: - UIResponder method to disable editing menu
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false //Disable all actions in order to disable menu.
    }
    
    //MARK: - Logics...
    
    /*
     * This method should be called by the delegate's
     * - ( BOOL )textField:( UITextField * )textField
     * shouldChangeCharactersInRange:( NSRange )range
     * replacementString:( NSString * )string
     * with the replacementString as argument.
     *
     * example:
     * - (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
     * {
     *     if ([textField isKindOfClass:[TimeField class]]) {
     *         return [(TimeField *) textField checkAllowedCharactersInString:string];
     *     }
     *     return YES; //All "normal" values and other textfields
     * }
     */
    private func checkAllowedCharactersIn(string:String) -> Bool
    {
        //Check for backspace first
        guard string.count > 0 else { return true } //allow backspace
        
        //begin with an easy test of length: hh:mm
        if (self.text?.count ?? 0 > 4) { return false }
        
        //allowedCharacterSet
        var allowedCharacters:CharacterSet = .decimalDigits
        allowedCharacters.insert(":")
        
        var containsOnlyAllowedCharacters = true
        
        for i in 0...string.count-1 {
            if let currentCharacter = Unicode.Scalar(string[i]) {
                if ( !allowedCharacters.contains(currentCharacter)) {
                    containsOnlyAllowedCharacters = false;
                }
            }
        }
        
        return containsOnlyAllowedCharacters
    }
    
    //check for insertion of ":"
    //This will be called every time editingChanged event is sent
    @objc private func insertColonIfAppropriate()
    {
        if (self.text?.count == 3) {
            guard let string = self.text else { return }
            let thirdComponent = string[2]
            let secondComponent = string[1] //someone may enter 1:...
            if (!(thirdComponent == ":" || secondComponent == ":")) { //if it's not already there
                //insert the colon
                let newString = NSMutableString(string: string)
                newString.deleteCharacters(in: NSRange(location: 2, length: 1))
                newString.appendFormat(":%@", thirdComponent)
                self.text = "\(newString)"
            }
        }
        
    }
    
    
    /* When using the TimeField as a self-contained unit (being its own UITextFieldDelegate),
         * this method is called when the textfield ends editing (either by pressing return or loosing focus).
         */
    private func checkTimeAndAlert(_ showAlert:Bool) -> Bool
    {
        //exit an empty field
        guard text?.count ?? 0 > 0 else { return true }
        
        //Make sure it's a valid time value
        let validTime = (((hours ?? 25 ) < 24) && ((minutes ?? 61) < 60))

        if (!validTime && showAlert) {
            
            //Show AlertView
            
            //Prepare the default action, delegate may have other ideas
            let changeValueAction = UIAlertAction(title: "Change Value",
                                                  style: .default) { [weak self] _ in
                self?.selectAll(self)
            }
            
            //Prepare the cancel action
            let cancelAction = UIAlertAction(title: "Cancel",
                                             style: .cancel) { _ in
                //No action necessary
            }
            
            
            //Ask the delegate to present the alert
            timeDelegate?.presentAlertFor(self,
                                          message: "No valid time.\n(00:00 - 23:59)",
                                          changeAction: changeValueAction,
                                          cancelAction: cancelAction)
            
        }
        return validTime
    }
    
    
    
    
//MARK: - Return values from the string
    
    /* returns nil if not set */
    public var minutes:Int? {
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
    public var hours:Int? {
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
    public var allMinutes:Int? {
        guard let mins = minutes, let hrs = hours, let str = self.text else {return nil}
        
        //Take into account a deleted figure!! return nil
        //Assume that the value is removed, or half removed when less than h:mm
        guard (str.count >= 4) else { return nil }
        
        return hrs*60+mins
    }
    
    
    //MARK: - Text Field Delegate
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        //Just call the delegate
        timeDelegate?.timeFieldDidBeginEditing?(self)
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return checkAllowedCharactersIn(string: string)
    }
    
    public override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard resignFirstResponder() else { return false }
        
        if let tf = (textField as? ChainedField) {
            tf.jumpToNext()
        }
        
        return true
    }
    
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let tf = (textField as? TimeField) {
            return tf.checkTimeAndAlert(true)
        }
        return true
        //When true is returned, textfieldDidEndEditing will be called
    }

    
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        //Call the delegate and give the new value
        timeDelegate?.timeField?(self, didReturnMinutes: allMinutes ?? -1)
    }
}
