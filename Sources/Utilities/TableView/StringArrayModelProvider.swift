//
//  ArrayModelProvider.swift
//  TheBestTableViewController
//
//  Created by Johan Nyman on 2022-07-05.
//

import Foundation

open class StringArrayModelProvider: ArrayModelProviding {
    
    public typealias CellModel = String
        
    public var modelArray: [[CellModel]]
    public var filteredArray:[[CellModel]]
    
    public init(model:[[CellModel]]?) {
        modelArray = model ?? []
        filteredArray = modelArray
    }
    
    open func newObject() -> String {
        return "New String"
    }
    
    //Search directly in the String
    open func searchPredicate(for searchText:String) -> NSPredicate {
        let textPredicate = NSPredicate(format: "SELF contains[cd] %@",searchText)
        return textPredicate
    }
    
    // Overrideable default implementations
    // (Protocol extensions cannot be ovverridden by subclasses to a class compliant with that protocol,
    // unless overridden in the class itself)
    open func uuid(for section:Int) -> String {
        return "\(section)"
    }
    
    open func modelForHeader(section: Int) -> Any {
        return ["Section \(section)", rowsIn(section: section)]
    }
    
    open func headerTitle(_ section: Int) -> String? {
        return "Section \(section)"
    }
    
    open func modelForFooter(section: Int) -> Any {
        return "Footer \(section)"
    }
    
    open func canEdit(row: Int, section: Int) -> Bool {
        return true
    }
    
}
