//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-08-01.
//

import Foundation
@preconcurrency import CoreData
import JBLogging


///Provides the model when coming from a Fetched Results Controller and underlying core data.
public protocol FRCModelProviding: ModelProviding {
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> { get set }
    var moc: NSManagedObjectContext? { get set }
    
    ///Fetch parameters
    func fetchRequestWith(predicate: NSPredicate) -> NSFetchRequest<NSFetchRequestResult>
    func fetchPredicate() -> NSPredicate
    
    ///Must be same as first sort descriptor key path
    func sectionNameKeyPath() -> String //TODO: change to KeyPath
    
    ///Optional to translate fetchrequest section names to header titles
    func headerTitleFor(sectionName: String?) -> String?
    
    ///Make sure to call in ViewController setup code
    func initializeFetchedResultsController()
    
    ///Standard implementation to provide in modelFor(row: Int, section: Int) -> Any
    ///Provides the fetched object at the row in section.
    func standardModelFor(row: Int, section: Int) -> Any
    
    ///Standard implementation provided
    func performNewFetch()
    
}

//Model providing
@MainActor public extension FRCModelProviding {
    
    func numberOfSections() -> Int {
        fetchedResultsController.sections?.count ?? 0
    }
    
    func rowsIn(section: Int) -> Int {
        // For safety in case of empty array
        guard let sections = fetchedResultsController.sections,
              sections.count > section else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    func standardModelFor(row: Int, section: Int) -> Any {
        return fetchedResultsController.object(at: IndexPath(row: row, section: section))
    }
    
    func headerTitle(_ section: Int) -> String? {
        // For safety in case of empty array
        guard let sections = fetchedResultsController.sections,
              sections.count > section else {
            return nil
        }
        let sectionName = sections[section].name
        return headerTitleFor(sectionName: sectionName)
    }
    
    func delete(row: Int, section: Int) {
        fatalError() //TBD
    }
    
    func insertAt(row: Int, section: Int) {
        fatalError() //TBD
    }
    
    func move(from:IndexPath, to:IndexPath) {
        fatalError() //TBD
    }
    
    //MARK: - Searching
    
    func filterModel(searchText: String?) {
        
        if let searchText = searchText,
           !searchText.isEmpty {
            
            //Make a predicate for the search
            let sPredicate = searchPredicate(for: searchText)
            
            let fPredicate = fetchPredicate()
            
            let cPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sPredicate, fPredicate])
            
            fetchedResultsController.fetchRequest.predicate = cPredicate
            
        } else {
            
            //Reset the fetch request
            fetchedResultsController.fetchRequest.predicate = fetchPredicate()
        }
        //Perform the actual search (or reset if searchText is nil or empty string):
        performNewFetch()
    }
}

//Setting up fetches
public extension FRCModelProviding {
    
    func initializeFetchedResultsController() {
        
        let request = fetchRequestWith(predicate: fetchPredicate())
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: moc!,
                                                              sectionNameKeyPath: sectionNameKeyPath(), cacheName: nil)
        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
        
        //Perform fetch
        performNewFetch()
    }
    
    func performNewFetch() {
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            Log.error(error, message: "Failed to initialize FetchedResultsController. Crashing to avoid further data corruption.", in: .functionality)
            //Intentionally crash
            abort()
        }
    }
}
