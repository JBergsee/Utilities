//
//  Protocols.swift
//  TheBestTableViewController
//
//  Created by Johan Nyman on 2022-07-05.
//

import Foundation
import UIKit

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

//Provides the model when the Model is an Array
public protocol ArrayModelProviding: ModelProviding {
    var modelArray:[[CellModel]] { get set }
    var filteredArray:[[CellModel]] { get set }
    func searchPredicate(for searchText:String) -> NSPredicate
    func newObject() -> CellModel
}

public extension ArrayModelProviding {
    
    func numberOfSections() -> Int {
        return filteredArray.count
    }
    
    func rowsIn(section: Int) -> Int {
        return filteredArray[section].count
    }
    
    func modelFor(row: Int, section: Int) -> CellModel {
        return filteredArray[section][row]
    }
    
    mutating func delete(row: Int, section: Int) {
        let removedObject = filteredArray[section].remove(at: row)
        //Try to find in the original array
        if let index = modelArray[section].firstIndex(of: removedObject) {
            //This will be wrong if we have several equal instances of the Model and it is not the first that is removed
            modelArray[section].remove(at: index)
        }
    }
    
    mutating func insertAt(row: Int, section: Int) {
        //Create a new "entity" and insert
        let newObject = newObject()
        filteredArray[section].insert(newObject, at: row)
        //Insert in original array as well
        if row == 0 {
            modelArray[section].insert(newObject, at: 0)
        } else {
            //Try to find place in original array
            if let index = modelArray[section].firstIndex(of: filteredArray[section][row]) {
                //This will be wrong if we have several equal instances of the Model and it is not the first that was supposed to be used
                modelArray[section].insert(newObject, at: index)
            }
        }
    }
    
    mutating func move(from: IndexPath, to: IndexPath) {
        //TBD
    }
    
    mutating func filterModel(searchText: String?) {
        
        //reset the filtered array
        filteredArray = modelArray
        
        guard let searchText = searchText,
              !searchText.isEmpty else {
                  return
              }
        
        filteredArray = []
        // Filter the arrays using NSPredicate
        let predicate = searchPredicate(for: searchText)
        modelArray.forEach { array in
            filteredArray.append(array.filter() { predicate.evaluate(with: $0) })
        }
    }
    
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

