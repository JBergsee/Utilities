//
//  Protocols.swift
//  TheBestTableViewController
//
//  Created by Johan Nyman on 2022-07-05.
//

import Foundation
import UIKit

//The tableView or the ModelProvider
public protocol CollapseControllingDelegate {
    func toggleSection(_ section: Int, for header:CollapseControlling?)
}

public protocol CollapseControlling { //Normally a UITableViewHeaderFooterView
    var collapseButton: UIView? { get }
    var section: Int { get set }
    var delegate: CollapseControllingDelegate? { get set }
    
    func setCollapsed(_ collapsed: Bool, animated: Bool)
}

//Provides the model for the UITableView
public protocol ModelProviding {
    associatedtype CellModel: Equatable
    
    func uuid(for section:Int) -> String
    
    func numberOfSections() -> Int
    func rowsIn(section: Int) -> Int
    func modelFor(row: Int, section: Int) -> CellModel
    
    func modelForHeader(section: Int) -> Any
    func modelForFooter(section: Int) -> Any
    
    func canEdit(row: Int, section: Int) -> Bool
    mutating func delete(row: Int, section: Int)
    mutating func insertAt(row: Int, section: Int)
    mutating func move(from:IndexPath, to:IndexPath)
    
    mutating func filterModel(searchText:String?)
}


public protocol GenericTableViewControlling {

    associatedtype CellModel
    associatedtype ModelProvider: ModelProviding where ModelProvider.CellModel == CellModel

    var modelProvider: ModelProvider? { get set }
    var delegate: GenericTableViewDelegate? { get set }
}
    
    
public protocol GenericTableViewDelegate {
    
    var cellIdentifier:String { get }
    var headerIdentifier:String { get }
    var footerIdentifier:String { get }
    
    var searchPlaceHolderString: String { get }
    
    func headerHeight(section: Int) -> CGFloat
    func footerHeight(section: Int) -> CGFloat
}

