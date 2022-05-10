//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-05-06.
//

import Foundation
import UIKit

public protocol PopoverPresenting {
    func showPopoverFor(textfield:UITextField,
                        tableViewDelegate:UITableViewDelegate,
                        tableViewDataSource:UITableViewDataSource,
                        permitTouch:Bool)
}

extension PopoverPresenting {
    func showPopoverFor(textfield:UITextField,
                        tableViewDelegate:UITableViewDelegate,
                        tableViewDataSource:UITableViewDataSource,
                        permitTouch:Bool) {
        
    }
}
