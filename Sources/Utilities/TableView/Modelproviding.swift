//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-07-21.
//

import Foundation
@preconcurrency import CoreData


//Provides the model for the UITableView
public protocol ModelProviding: AnyObject {
    
    func uuid(for section:Int) -> String
    
    func numberOfSections() -> Int
    func rowsIn(section: Int) -> Int
    
    //TODO: associated types and generics instead of Any
    func modelFor(row: Int, section: Int) -> Any //To be implemented by each class
    func standardModelFor(row: Int, section: Int) -> Any //Default implementation providing an object from array or FRC
    func modelForHeader(section: Int) -> Any
    func modelForFooter(section: Int) -> Any
    
    func headerTitle(_ section: Int) -> String?
    
    func canEdit(row: Int, section: Int) -> Bool
    func delete(row: Int, section: Int)
    func insertAt(row: Int, section: Int)
    func move(from:IndexPath, to:IndexPath)
    
    func searchPredicate(for searchText:String) -> NSPredicate
    func filterModel(searchText:String?)
}


///Provides the model when the Model is an Array
///For sections use array of arrays.
public protocol ArrayModelProviding: ModelProviding {

    associatedtype CellModel: Equatable
    
    var modelArray:[[CellModel]] { get set }
    var filteredArray:[[CellModel]] { get set }

    func newObject() -> CellModel?
}

public extension ArrayModelProviding {
    
    func numberOfSections() -> Int {
        return filteredArray.count
    }
    
    func rowsIn(section: Int) -> Int {
        return filteredArray[section].count
    }
    
    func standardModelFor(row: Int, section: Int) -> Any {
        return filteredArray[section][row]
    }
    
    func delete(row: Int, section: Int) {
        let removedObject = filteredArray[section].remove(at: row)
        //Try to find in the original array
        if let index = modelArray[section].firstIndex(of: removedObject) {
            //This will be wrong if we have several equal instances of the Model and it is not the first that is removed
            modelArray[section].remove(at: index)
        }
    }
    
    func insertAt(row: Int, section: Int) {
        //Create a new "entity" and insert
        guard let newObject = newObject() else { return }
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
    
    func move(from: IndexPath, to: IndexPath) {
        //TBD
    }
    
    func filterModel(searchText: String?) {
        
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
            filteredArray.append(array.filter() {
                predicate.evaluate(with: $0)
            })
        }
    }
}


