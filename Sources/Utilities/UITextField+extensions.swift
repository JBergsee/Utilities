//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-03-08.
//

import Foundation
import UIKit

public extension UITextField {
    
    //Convenience function to hide the bar above the keyboard
    func hideBar()
    {
        let bar = self.inputAssistantItem
        bar.leadingBarButtonGroups = []
        bar.trailingBarButtonGroups = []
        self.autocorrectionType = .no
    }
}
