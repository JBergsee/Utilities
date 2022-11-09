//
//  Protocols.swift
//  TheBestTableViewController
//
//  Created by Johan Nyman on 2022-07-05.
//

import Foundation
import UIKit


public protocol GenericTableViewControlling: AnyObject {
    ///Should be declared weak in implementation
    var modelProvider: ModelProviding? { get set }
    ///Should be declared weak in implementation
    var delegate: GenericTableViewDelegate? { get set }
}
    
    
public protocol GenericTableViewDelegate: AnyObject {
    
    var cellIdentifier:String { get }
    ///Headers (and footers) can be defined in the same tableview as the cells.
    ///Set cell identifier of that cell as headerIdentifier.
    ///Make the Header/footer view a subview of the cell's ContentView
    var headerIdentifier:String { get }
    var footerIdentifier:String { get }
    
    var searchPlaceHolder: String { get }
}

