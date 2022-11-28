//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-07-28.
//

import UIKit
import CoreData


//MARK: - Fetched Results controller delegate standard implementation
extension GenericTableViewController: NSFetchedResultsControllerDelegate {
    
    //Start updates
    @objc open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
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
    @objc open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        
        guard !_changeIsUserDriven else { return }
        //Do nothing if the user is rearranging the table
        
        switch(type) {
        case .insert:
            //Add the new section in the table
            tableView.insertSections(IndexSet([sectionIndex]),
                                     with:.automatic)
            break
            
        case .delete:
            //Remove the section from the table
            tableView.deleteSections(IndexSet([sectionIndex]),
                                     with:.automatic)
            break
            
        default:
            break
        }
    }
    
    //Insert, delete, move or change an object
    @objc open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        guard !_changeIsUserDriven else { return }
        //Do nothing if the user is rearranging the table
        
        switch(type) {
            
        case .insert:
            guard let newIndexPath = newIndexPath else {
                return
            }
            
            tableView.insertRows(at: [newIndexPath],
                                 with:.automatic)
            break;
            
        case .delete:
            guard let indexPath = indexPath else { return }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            break;
            
            
        case .update:
            guard let indexPath = indexPath else { return }
            
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
            //Should be enough to redraw the cell...
            //But is not enough when the change is taking place and the view is not attached to a window.
            //Therefore, a reload should be added to the viewWillAppear: of this viewController.
            break
            
        case .move:
            guard let indexPath = indexPath,
                  let newIndexPath = newIndexPath else { return }
            
            tableView.deleteRows(at: [indexPath],
                                 with:.automatic)
            tableView.insertRows(at: [newIndexPath],
                                 with:.automatic)
            break
            
        @unknown default:
            Log.fault(message: "Switch ended up in unknown default.", in: .functionality)
        }
    }
    
    @objc open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        guard !_changeIsUserDriven else { return }
        //Do nothing if the user is rearranging the table
        
        //        guard view.window != nil else {
        //            return
        //            //Do nothing if the view is not in the hierarchy. (Avoids LayoutOutsideViewHierarchy warnings)
        //        }
        
        tableView.endUpdates()
    }
}


