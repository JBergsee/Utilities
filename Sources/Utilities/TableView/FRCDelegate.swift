//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-07-28.
//

import UIKit
@preconcurrency import CoreData
import JBLogging


//MARK: - Fetched Results controller delegate standard implementation
extension GenericTableViewController: NSFetchedResultsControllerDelegate {
    
    private func viewIsInHierarchy() -> Bool {
        return view.window != nil &&
        view.superview != nil &&
        isViewLoaded
    }

    //Start updates
    @objc open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        //Do nothing if the user is rearranging the table
        guard !_changeIsUserDriven else { return }

        // Do nothing if the view is not in the hierarchy.
        // (Avoids LayoutOutsideViewHierarchy warnings and crashes on flight deletions.)
        // isProcessingFRCChanges tracks whether beginUpdates was called so that
        // controllerDidChangeContent only calls endUpdates when there is a matching open batch.
        guard viewIsInHierarchy() else { return }

        // Snapshot all current section UUIDs before the FRC mutates its sections.
        // isCollapsed(_:) uses this cache during the callback batch to avoid querying
        // the FRC mid-update (which can crash if a section becomes empty).
        isProcessingFRCChanges = true
        let count = modelProvider?.numberOfSections() ?? 0
        for i in 0..<count {
            sectionUuidSnapshot[i] = modelProvider?.uuid(for: i)
        }

        tableView.beginUpdates()
    }
    
    //Insert or remove a whole section
    @objc open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                               didChange sectionInfo: NSFetchedResultsSectionInfo,
                               atSectionIndex sectionIndex: Int,
                               for type: NSFetchedResultsChangeType) {

        guard !_changeIsUserDriven else { return }
        guard isProcessingFRCChanges else { return }
        
        switch(type) {
        case .insert:
            // add in the open/closed dictionary
            addSection(newIndex: sectionIndex)

            //Add the new section in the table
            tableView.insertSections(IndexSet([sectionIndex]),
                                     with:.automatic)
            break
            
        case .delete:
            // remove from the open/closed dictionary
            removeSection(sectionIndex)

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
        guard isProcessingFRCChanges else { return }

        //Will crash if the section is closed so check before deleting/inserting:
        
        switch(type) {
            
        case .insert:
            guard let newIndexPath = newIndexPath,
                  !isCollapsed(newIndexPath.section) else { return }
            
            tableView.insertRows(at: [newIndexPath],
                                 with:.automatic)
            break;
            
        case .delete:
            
            guard let indexPath = indexPath,
                  !isCollapsed(indexPath.section) else { return }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            break;
            
            
        case .update:
            guard let indexPath = indexPath else { return }
            
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
            //Should be enough to redraw the cell...
            //But is not enough when the change is taking place and the view is not attached to a window.
            //Therefore, a reload should be added to the viewWillAppear: of this viewController.
            
            //HOWEVER, note that a reloadData in viewWillAppear may cause crashes when the iPad is rotated,
            //so test this carefully!
            break
            
        case .move:
            guard let indexPath = indexPath,
                  let newIndexPath = newIndexPath,
                  !isCollapsed(indexPath.section),
                  !isCollapsed(newIndexPath.section) else { return }
            
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

        // Only call endUpdates if beginUpdates was actually called (i.e. view was in hierarchy).
        // This prevents an unmatched endUpdates when the view left the hierarchy mid-batch.
        guard isProcessingFRCChanges else { return }

        tableView.endUpdates()

        // Clear the snapshot now that the batch is complete
        isProcessingFRCChanges = false
        sectionUuidSnapshot.removeAll()
    }
}


