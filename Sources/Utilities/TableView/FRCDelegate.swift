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

        // Do nothing if the view is not in the hierarchy (avoids LayoutOutsideViewHierarchy
        // warnings). Mark tableViewNeedsFullReload so that when the view becomes visible
        // again — either via viewWillAppear or the next in-hierarchy batch — we resync
        // the table view with the FRC before opening a new beginUpdates block.
        // Without this resync, a silently-skipped section deletion leaves the table view
        // with a stale section count, causing NSInternalInconsistencyException at the
        // next endUpdates().
        guard viewIsInHierarchy() else {
            tableViewNeedsFullReload = true
            return
        }

        // If a previous batch was skipped while off-screen, resync the table view now,
        // before opening the new beginUpdates block.
        if tableViewNeedsFullReload {
            tableView.reloadData()
            tableViewNeedsFullReload = false
        }

        // Snapshot all current section UUIDs before the FRC mutates its sections.
        // isCollapsed(_:) uses this cache during the callback batch to avoid querying
        // the FRC mid-update (which can crash if a section becomes empty).
        isProcessingFRCChanges = true
        pendingUpdateIndexPaths.removeAll()
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
            // Collect updates to apply after endUpdates(). The FRC provides the post-change
            // index path, which is invalid inside a beginUpdates/endUpdates batch when sections
            // have shifted — applying reloadRows here with a shifted index path causes
            // NSInternalInconsistencyException. Deferring to after endUpdates() is always safe.
            guard let indexPath = indexPath,
                  !isCollapsed(indexPath.section) else { return }
            pendingUpdateIndexPaths.append(indexPath)
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

        // Flush row updates collected during the batch. These use post-change index paths
        // from the FRC, which are valid now (after endUpdates) but would have caused
        // NSInternalInconsistencyException if applied inside the batch.
        if !pendingUpdateIndexPaths.isEmpty {
            tableView.reloadRows(at: pendingUpdateIndexPaths, with: .none)
            pendingUpdateIndexPaths.removeAll()
        }

        // Clear the snapshot now that the batch is complete
        isProcessingFRCChanges = false
        sectionUuidSnapshot.removeAll()
    }
}


