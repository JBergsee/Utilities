//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-07-28.
//

import UIKit
import CoreData


//MARK: - Fetched Results controller delegate standard implementation
public extension NSFetchedResultsControllerDelegate where Self: GenericTableViewController {
    
    /*
     For changes in the underlying model that is NOT already done by the user, such as giving new sortIndexes...
     
     Assume self has a property 'tableView' -- as is the case for an instance of a UITableViewController subclass -- and a method configureCell:atIndexPath: which updates the contents of a given cell
     with information from a managed object at the given index path in the fetched results controller.
     */
    
    
    //Start updates
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        guard !_changeIsUserDriven else { return }
        //Do nothing if the user is rearranging the table
        
        //Testing if it is in the hierarchy
        //        guard view.window != nil,
        //              view.superview != nil,
        //              isViewLoaded else {
        //
        //                  Log.debug(message: "Not in hierarchy!", in: .functionality)
        //                  return //Do nothing if the view is not in the hierarchy. (Avoids LayoutOutsideViewHierarchy warnings)
        //              }
        
        tableView.beginUpdates()
    }
    
    //Insert or remove a whole section
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        
        guard !_changeIsUserDriven else { return }
        //Do nothing if the user is rearranging the table
        
        switch(type) {
        case .insert:
            //Add the new section in the open sections model
            /*
             [self.openSections insertObject:[NSNumber numberWithBool:YES] atIndex:sectionIndex];
             */
            //And add the new section in the table
            tableView.insertSections(IndexSet([sectionIndex]),
                                     with:.automatic)
            break
            
        case .delete:
            //Remove the section from the open sections model
            /*
             [self.openSections removeObjectAtIndex:sectionIndex];
             */
            //And remove the section from the table
            tableView.deleteSections(IndexSet([sectionIndex]),
                                     with:.automatic)
            break
            
        default:
            break
        }
    }
    
    //Insert, delete, move or change an object
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        guard !_changeIsUserDriven else { return }
        //Do nothing if the user is rearranging the table
        
        switch(type) {
            
        case .insert:
            tableView.insertRows(at: [newIndexPath!],
                                 with:.automatic)
            break;
            
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            
            break;
            
        case .update:
            _ = tableView.cellForRow(at: indexPath!)
            //Should be enough to redraw the cell...
            //But is not enough when the change is taking place and the view is not attached to a window.
            //Therefore, a reload should be added to the viewWillAppear: of this viewController.
            break
            
        case .move:
            tableView.deleteRows(at: [indexPath!],
                                 with:.automatic)
            tableView.insertRows(at: [newIndexPath!],
                                 with:.automatic)
            break
            
        @unknown default:
            Log.fault(message: "Switch ended up in unknown default.", in: .functionality)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        guard !_changeIsUserDriven else { return }
        //Do nothing if the user is rearranging the table
        
        //        guard view.window != nil else {
        //            return
        //            //Do nothing if the view is not in the hierarchy. (Avoids LayoutOutsideViewHierarchy warnings)
        //        }
        
        tableView.endUpdates()
    }
}


