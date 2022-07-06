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
    
    open func modelForFooter(section: Int) -> Any {
        return "Footer \(section)"
    }
    
    open func canEdit(row: Int, section: Int) -> Bool {
        return true
    }
    
}

/*   TILL FRCMODELPROVIDER
 //If we have nothing we're not searching...
 if ([searchText isEqualToString:@""]) {
 
 //Reset the fetch request
 self.fetchedResultsController.fetchRequest.predicate = [self fetchPredicate];
 
 } else {
 
 NSLog(@"Searching for '%@'", searchText);
 
 //Make a predicate for the search
 NSPredicate * searchPredicate = [self searchPredicateForString:searchText];
 NSArray * predicates = [NSArray arrayWithObjects:searchPredicate, [self fetchPredicate], nil];
 NSCompoundPredicate * predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
 self.fetchedResultsController.fetchRequest.predicate = predicate;
 
 }
 
 //Perform the actual search (or reset if searchText is nil or empty string):
 [self performNewFetch];
 
 */
