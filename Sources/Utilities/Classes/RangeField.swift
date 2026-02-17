//
//  TimeField.swift
//
//
//  Created by Johan Nyman on 2022-03-08.
//

//With some help from here: https://nshipster.com/characterset/


import UIKit

@objc public protocol RangeFieldDelegate {
    /* When using the RangeField as a self-contained unit (being its own UITextFieldDelegate),
     * this method is called when the textfield ends editing (either by pressing return or loosing focus).
     */
    
    func presentAlertFor(_ rangeField:RangeField, message:String, changeAction:UIAlertAction, cancelAction:UIAlertAction)
    
    @objc optional func rangeFieldDidBeginEditing(_ rangeField:RangeField)
    @objc optional func rangeField(_ rangeField:RangeField, didReturn value:NSNumber?)
}

public extension RangeFieldDelegate where Self: UIViewController {
    
    //Default implementation
    func presentAlertFor(_ rangeField: RangeField, message: String, changeAction: UIAlertAction, cancelAction: UIAlertAction) {
        //May be called several times...
        guard self.presentedViewController == nil else { return }
        
        //Show Alert, only include changeaction
        showAlert(title: "Value out of range",
                  message: message,
                  actions: [changeAction])
    }
}


public enum RangeFieldType: Sendable {
    case floatingPoint, integer, character
}

public class RangeField: ChainedField, UITextFieldDelegate {
    
    //Constant format strings for default messages
    private static let floatStringMin = "%.2f is below minimum value of %.2f"
    private static let floatStringMax = "%.2f is above maximum value of %.2f"
    
    private static let intStringMin = "%d is below minimum value of %d"
    private static let intStringMax = "%d is above maximum value of %d"
    
    private static let stringMaxLength = "Max length is %d characters"
    
    //Delegate to set in Interface Builder
    @IBOutlet public weak var rangeDelegate: RangeFieldDelegate?
    
    // Before initializing we make a floating point textfield with all floating point values (min to max)
    public var rangeType: RangeFieldType = .floatingPoint
    public var minValue: NSNumber = NSNumber(value: -Double.greatestFiniteMagnitude)
    public var maxValue: NSNumber = NSNumber(value: Double.greatestFiniteMagnitude)
    public var maxLength: Int = Int.max
    public var allowedCharacters: CharacterSet?
    
    private class var floatCharacterSet:CharacterSet {
        var set: CharacterSet = .decimalDigits
        set.insert(charactersIn: ".-") //point and minus
        return set
    }
    
    private class var intCharacterSet:CharacterSet {
        var set: CharacterSet = .decimalDigits
        set.insert("-") //add minus
        return set
    }
    
    
    //MARK: - Initialization
    
    // default init makes a floating point textfield with all floating point values (min to max)
    init(rangeType: RangeFieldType? = .floatingPoint,
         minValue: NSNumber = NSNumber(value: -Double.greatestFiniteMagnitude),
         maxValue: NSNumber = NSNumber(value: Double.greatestFiniteMagnitude),
         maxLength: Int = Int.max,
         allowedCharacters: CharacterSet? = floatCharacterSet) {
        
        self.rangeType = rangeType!
        self.minValue = minValue
        self.maxValue = maxValue
        self.maxLength = maxLength
        self.allowedCharacters = allowedCharacters
        super.init(frame: CGRect())
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setupSelf()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSelf()
    }
    
    public override func awakeFromNib()
    {
        super.awakeFromNib()
        setupFloatRange(min: -Double.greatestFiniteMagnitude,
                        max: Double.greatestFiniteMagnitude)
        setupSelf()
        
    }
    
    //MARK: - Easy setup
    
    public func setupIntRange(min: Int, max: Int) {
        rangeType = .integer
        minValue = NSNumber(value: min)
        maxValue = NSNumber(value: max)
        allowedCharacters = RangeField.intCharacterSet
    }
    
    public func setupFloatRange(min: Double, max: Double) {
        rangeType = .floatingPoint
        minValue = NSNumber(value: min)
        maxValue = NSNumber(value: max)
        allowedCharacters = RangeField.floatCharacterSet
    }
    
    public func setupCharacterRange(allowedCharacters: CharacterSet) {
        rangeType = .character
        self.allowedCharacters = allowedCharacters
    }
    
    /*
     * Set as its own delegate,
     * Set keyboard type,
     * if not set in IB
     *
     */
    private func setupSelf() {
        
        if delegate == nil { delegate = self }
        if keyboardType == .default { keyboardType = .decimalPad }
        //Hide the bar above the keyboard and with that any spelling suggestions.
        hideBar()
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
     - (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
     {
     if ([textField isKindOfClass:[RangeField class]]) {
     return [(RangeField *) textField checkString:string];
     }
     return YES;
     }
     */
    
    private func check(string: String) -> Bool {
        //If there is no set of allowed characters nothing is allowed
        guard let allowed = allowedCharacters else { return false }
        
        return string.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
    
    
    /*
     * These methods checks the textfields whole text and compares with the range.
     * May be called by the delegate's
     * - (BOOL)textFieldShouldEndEditing:(UITextField *)textField
     * or
     * - (BOOL)textFieldShouldReturn:(UITextField *)textField
     * Return NO in order to keep this textfield in focus and not resign first responder status
     * Text can then be highlighted and changed.
     *
     * example:
     
     - (BOOL)textFieldShouldEndEditing:(UITextField *)textField
     {
     if ([textField isKindOfClass:[RangeField class]]) {
     return ([(RangeField *) textField checkRangeAndAlert:YES] == NSOrderedSame);
     }
     return YES;
     //If YES is returned, textfieldDidEndEditing will be called
     }
     
     - (BOOL)textFieldShouldReturn:(UITextField *)textField
     {
     
     return [textField resignFirstResponder]; //This in turn calls textFieldShouldEndEditing.
     
     }
     
     
     */
    
    public func checkRangeAndAlert(_ showAlert: Bool) -> ComparisonResult?
    {
        let result = verifyStringValueWithinRange()
        
        if (result != .orderedSame) && showAlert {
            //Show Alert
            delegateWarningFor(result)
        }
        
        return result
    }
    
    private func delegateWarningFor(_ result: ComparisonResult?) {
        
        let currStr: String = text ?? "No value"
        
        var warning: String = "Value is within range"
        
        if let result = result {
            
            switch result {
            case .orderedDescending:
                //Too low
                
                switch rangeType {
                case .floatingPoint:
                    warning = String(format: RangeField.floatStringMin, Float(currStr) ?? 0, minValue.floatValue)
                    break;
                case .integer:
                    warning = String(format: RangeField.intStringMin, Int(currStr) ?? 0, minValue.intValue)
                    break;
                default:
                    warning = "Character value is too low"
                    break;
                }
                break
                
            case .orderedAscending:
                //Too high
                
                switch rangeType {
                case .floatingPoint:
                    warning = String(format: RangeField.floatStringMax, Float(currStr) ?? 0, maxValue.floatValue)
                    break;
                case .integer:
                    warning = String(format: RangeField.intStringMax, Int(currStr) ?? 0, maxValue.intValue)
                    break;
                default:
                    warning = "Character value is too high"
                    break
                }
                break
                
            default:
                //All good, shouldn't come here
                break
            }
            
        } else {
            warning = currStr + " is not a valid number."
        }
        
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
        rangeDelegate?.presentAlertFor(self,
                                       message: warning,
                                       changeAction: changeValueAction,
                                       cancelAction: cancelAction)
    }
    
    /* returns
     * OrderedDescending if below range
     * OrderedSame if within range
     * OrderedAscending if above range
     * nil if nan
     */
    private func verifyStringValueWithinRange() -> ComparisonResult?
    {
        //First check, return if nothing is entered
        //Might be the case if field is active when view hides.
        //Must approve this in case 0 is below minvalue
        guard (text?.count ?? 0 > 0) else { return .orderedSame }
        
        //For characters no comparison can be made
        guard (rangeType != .character) else { return .orderedSame }
        
        //make NSNumber of string
        let valueToCheck = NSNumber(value: Double(text ?? ".") ?? .nan)
        
        //Next for errouneous input, such as "56.-7653" or "..8.", return nil
        guard !(valueToCheck.doubleValue.isNaN) else { return nil }
        
        /*
         NSOrderedAscending if the value of aNumber is greater than the receiver’s,
         NSOrderedSame if they’re equal, and
         NSOrderedDescending if the value of aNumber is less than the receiver’s.
         */
        
        //compare low
        let lowResult = minValue.compare(valueToCheck)
        if (lowResult == .orderedDescending) { return lowResult }
        
        //compare high
        let highResult = maxValue.compare(valueToCheck)
        if (highResult == .orderedAscending) { return highResult }
        
        //it is within range!
        return .orderedSame;
        
    }
    
    //MARK: - Return values from the string
    
    /* returns empty string if no text set */
    public var value: Any? {
        switch rangeType {
        case .floatingPoint:
            return Float(text ?? "a") ?? .nan
        case .integer:
            return Int(text ?? "a") ?? Double.nan
        case .character:
            return text ?? ""
        }
    }
    
    
    //MARK: - Text Field Delegate
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        //Just call the delegate
        rangeDelegate?.rangeFieldDidBeginEditing?(self)
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        //Check length
            //Allow deletion (string length 0)
            if ((text?.count ?? 0) + string.count > maxLength) {
                return false
            }

        return check(string: string)
    }
    
    public override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //This in turn calls textFieldShouldEndEditing.
        guard textField.resignFirstResponder() else { return false }
        
        if let tf = (textField as? ChainedField) {
            tf.jumpToNext()
        }
        
        return true
    }
    
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        if let tf = (textField as? RangeField) {
            return tf.checkRangeAndAlert(true) == .orderedSame
        }
        return true
        //When true is returned, textfieldDidEndEditing will be called
    }
    
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        //Call the delegate and give the new value
        var number: NSNumber? = nil
        
        switch rangeType {
        case .floatingPoint:
            if let floatValue = self.value as? Float {
                number = NSNumber(value: floatValue)
            }
            break
        case .integer:
            if let intValue = self.value as? Int {
                number = NSNumber(value: intValue)
            }
        case .character:
            //Can't return as NSNumber
            break;
        }
        
        //Take into account a deleted figure!! return nil
        if (text?.count == 0) { number = nil }//(as 0 might be returned from self.value)
        //nil will also be returned from Character or Time Type rangeFields
        
        rangeDelegate?.rangeField?(self, didReturn: number)
        
    }
}
