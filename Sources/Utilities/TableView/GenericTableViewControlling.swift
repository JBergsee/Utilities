//
//  Protocols.swift
//  TheBestTableViewController
//
//  Created by Johan Nyman on 2022-07-05.
//

import Foundation
import UIKit


public protocol GenericTableViewControlling {

    var modelProvider: ModelProviding? { get set }
    var delegate: GenericTableViewDelegate? { get set }
}
    
    
public protocol GenericTableViewDelegate {
    
    var cellIdentifier:String { get }
    var headerIdentifier:String { get }
    var footerIdentifier:String { get }
    
    var searchPlaceHolder: String { get }
    
    func headerHeight(section: Int) -> CGFloat
    func footerHeight(section: Int) -> CGFloat
}

