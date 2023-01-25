//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-07-29.
//

import UIKit

///The tableView or the ModelProvider
public protocol CollapseControllingDelegate: AnyObject {
    func toggleSection(_ section: Int, for header: CollapseControlling?)
    func isCollapsed(_ section: Int) -> Bool
}

///Normally a UITableViewHeaderFooterView
public protocol CollapseControlling: AnyObject {
    var collapseButton: UIView? { get }
    var section: Int { get set }
    var isCollapsed: Bool { get }
    ///Should be declared weak in implementation
    var delegate: CollapseControllingDelegate? { get set }
    
    func setCollapsed(_ collapsed: Bool, animated: Bool)
}
