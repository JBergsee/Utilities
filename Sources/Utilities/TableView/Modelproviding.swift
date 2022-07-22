//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-07-21.
//

import Foundation
import CoreData

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


//Provides the model when coming from a Fetched Results Controller and underlying core data.
//public protocol FRCModelProviding: ModelProviding, NSFetchedResultsControllerDelegate {
//    var fetchedResultsController: NSFetchedResultsController { get set }<NSFetchRequestResult>
//    var moc: NSManagedObjectContext { get set }
//    
//    //Fetch parameters
//    func fetchRequestWith(predicate: NSPredicate) -> NSFetchRequest<NSFetchRequestResult>
//    func fetchPredicate() -> NSPredicate
//    func searchPredicateFor(searchText: String) -> NSPredicate
//    //Must be same as first sort descriptor key path
//    //(Try String if KeyPath does not work)
//    func sectionNameKeyPath() -> KeyPath<Any, Any>
//    func initializeFetchedResultsController()
//    
//    func performNewFetch()
//    
//}
//
//public extension FRCModelProviding {
//    
//    func initializeFetchedResultsController() {
//        
//        
//        let request = fetchRequestWith(predicate:  fetchPredicate())
//        
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
//                                                              managedObjectContext: moc,
//                                                              sectionNameKeyPath: sectionNameKeyPath(), cacheName: nil)
//        fetchedResultsController.delegate = self
//        
//        //Perform fetch
//        performNewFetch()
//    }
//    
//    func performNewFetch() {
//        
//        do {
//            try fetchedResultsController.performFetch()
//        } catch {
//            Log.error(error, message: "Failed to initialize FetchedResultsController. Crashing to avoid further data corruption.", in: .functionality)
//            //Intentionally crash
//            abort()
//        }
//    }
//    
//    func numberOfSections() -> Int {
//        return 1 //fetchedResultsController.sections?.count
//    }
//    
//    func rowsIn(section: Int) -> Int {
//        return fetchedResultsController.sections[section].count
//    }
//    
//    func modelFor(row: Int, section: Int) -> CellModel {
//        return fetchedResultsController.sections[section][row]
//    }
//    
//}
