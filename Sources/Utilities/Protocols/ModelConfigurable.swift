//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-06-30.
//

import UIKit

public protocol ModelConfigurable {
    //Configure the view of the table view cell, collection view cell, header/footer, or other.
    func configureWith(model: Any)
}
