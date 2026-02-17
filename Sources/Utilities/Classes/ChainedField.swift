//
//  ChainedField.swift
//  
//
//  Created by Johan Nyman on 2022-03-08.
/* This implementation uses the ideas explained here:
 * (Second solution with subclassed UITextField that can be chained together in IB!)
 * http://stackoverflow.com/questions/1347779/how-to-navigate-through-textfields-next-done-buttons
 */
//

import UIKit

@objc
open class ChainedField: UITextField {

    @IBOutlet public weak var nextField: UIResponder?
        
    /*
    In IB, change your UITextFields to use the ChainedField class.
    Next, also in IB, set the delegate for each of the ChainedFields (which is right where you put the code for the delegate method - textFieldShouldReturn).
    The beauty of this design is that now you can simply right-click on any textField and assign the nextField outlet to the next object you want to be the next responder.

    Moreover, you can do cool things like loop the textFields so that after the last one looses focus, the first one will receive focus again.
     */

    public override func awakeFromNib()
    {
        super.awakeFromNib()

        //automatically assign the returnKeyType of the ChainedField to a UIReturnKeyNext if there is a nextField assigned
        //one less thing to manually configure in IB.
        if (nextField != nil) {
            returnKeyType = .next
        } else if (returnKeyType == .default) {
            returnKeyType = .done
        } //Otherwise set in IB
    }

    public func jumpToNext() {
        nextField?.becomeFirstResponder()
    }

    /* To implement in the textFields delegate: */
    @objc public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        assertionFailure("No, program should not come here. Wrong delegate for chained text field: \(self)")

        guard textField.resignFirstResponder() else { return false }
        
        if let chainedField = (textField as? ChainedField) {
            chainedField.jumpToNext()
        }
        //Extension for buttons (TBD)
    //    if ([(ChainedField *) textField.nextField isKindOfClass:[UIButton class]]) {
    //        dispatch_async(dispatch_get_current_queue(),
    //                       ^ { [[textField nextField] sendActionsForControlEvents: UIControlEventTouchUpInside]; }); }
      
        return true
    }
}
