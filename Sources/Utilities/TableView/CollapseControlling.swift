//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-07-29.
//

import UIKit

//The tableView or the ModelProvider
public protocol CollapseControllingDelegate {
    func toggleSection(_ section: Int, for header:CollapseControlling?)
}

//Normally a UITableViewHeaderFooterView
public protocol CollapseControlling {
    var collapseButton: UIView? { get }
    var section: Int { get set }
    var delegate: CollapseControllingDelegate? { get set }
    
    func setCollapsed(_ collapsed: Bool, animated: Bool)
}
