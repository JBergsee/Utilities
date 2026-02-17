//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-05-06.
//

import Foundation
import UIKit
import JBLogging


@MainActor
public class PopoverPicker : NSObject {
    
    private var contentController = UITableViewController(style: .plain)
    private var textField: UITextField
    private var model: [String]
    
    private typealias popoverCheckedContinuation = CheckedContinuation<String?, Never>
    
    private unowned var viewController: UIViewController
    private var continuation: popoverCheckedContinuation?
    
    public init(tableViewController:UITableViewController, presentingViewController:UIViewController, textField:UITextField) {
        self.viewController = presentingViewController
        self.textField = textField
        self.model = [] //Not used in this case
        //Use the provided tableviewcontroller,
        self.contentController = tableViewController
        
        super.init()
        
        //Hook up self as delegate for the table view,
        // or the caller will await forever
        contentController.tableView.delegate = self
        
    }
    
    public init(presentingViewController:UIViewController, textField:UITextField, model:[String]) {
        
        self.viewController = presentingViewController
        self.textField = textField
        self.model = model
        
        super.init()
    
            //Make our own TableViewController
            /** Table view controllers can’t be guaranteed that its cell prototypes are loaded right after initialization time, until it appears on screen or is loaded from the storyboard.
             SO instead of programmatically creating it, it has to be loaded from storyboard. */
            let storyboard = UIStoryboard(name: "Views", bundle: .module)
            self.contentController = storyboard.instantiateViewController(withIdentifier: "PopoverTableView") as! UITableViewController
            contentController.tableView.dataSource = self
        
        
        //Hook up self as delegate for the table view,
        // or the caller will await forever
        contentController.tableView.delegate = self
    }
    
    public func pickString(presentationStyle: UIModalPresentationStyle = .popover) async -> String? {
        switch presentationStyle {
        case .fullScreen, .pageSheet, .formSheet, .currentContext, .overFullScreen, .overCurrentContext, .blurOverFullScreen, .custom:
            showModal(presentationStyle)
            break
        case .popover, .none, .automatic:
            showPopover()
            break
        @unknown default:
            Log.fault(message: "New presentation style in PopoverPresenter: \(presentationStyle)", in: .functionality)
            showPopover()
        }
        return await withCheckedContinuation({ (continuation: popoverCheckedContinuation) in
            self.continuation = continuation
            
        })
    }
    
    private func showModal(_ style: UIModalPresentationStyle) {
        // Present the table view controller using the provided style.
        contentController.modalPresentationStyle = style
        viewController.present(contentController, animated: true, completion: nil)
    }
    
    private func showPopover() {
        // Present the table view controller using the popover style.
        contentController.modalPresentationStyle = .popover
        viewController.present(contentController, animated: true, completion: nil)

        // Get the popover presentation controller and configure it.
        let presentationController = contentController.popoverPresentationController
        presentationController?.delegate = self
        presentationController?.permittedArrowDirections = [.left, .down]
        presentationController?.sourceView = viewController.view

        //Convert the rect coords to point at the textfield
        let rect = textField.convert(textField.bounds, to: viewController.view)
        presentationController?.sourceRect = rect;
    }
    
    
    private func preferredContentSizeFor(tableView:UITableView) -> CGSize {
        
        //Calculate how tall the view should be by multiplying
        //the individual row height by the total number of rows.
        let rowsCount = tableView.numberOfRows(inSection: 0)
        let singleRowHeight = tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.frame.size.height ?? 44.0
        let totalRowsHeight = CGFloat(rowsCount) * singleRowHeight
        
        //Calculate how wide the view should be by finding how
        //wide each string is expected to be
        var largestLabelWidth:CGFloat = 0.0
        
        for i in 0...rowsCount {
            let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0))
            let text = cell?.textLabel?.text
            //Checks size of text using the actual font of UITableViewCell's textLabel.
            let labelSize = text?.size(withAttributes:[.font: cell?.textLabel?.font as Any])
            
            if (labelSize?.width ?? 1.0 > largestLabelWidth) {
                largestLabelWidth = labelSize?.width ?? 1.0
            }
        }
        
        //Add a little padding to the width (and remove fractional size)
        let popoverWidth = ceil(largestLabelWidth + singleRowHeight);
        
        //Return the property to tell the popover container how big this view will be.
        return CGSize(width:popoverWidth, height:totalRowsHeight)
    }
}

//MARK: - Table view data source
extension PopoverPicker : UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        // Configure the cell...
        cell.textLabel?.text = model[indexPath.row]
        
        return cell
    }
}
//MARK: - Table view delegate
extension PopoverPicker : UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //Return the picked string
        continuation?.resume(returning: model[indexPath.row])
        continuation = nil
        
        //Dismiss popover
        viewController.presentedViewController?.dismiss(animated: true)
    }
}

//MARK: - Popover Delegate

extension PopoverPicker : UIPopoverPresentationControllerDelegate {
    
    public func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        
        if let contentController = popoverPresentationController.presentedViewController as? UITableViewController {
            //Setup size
            contentController.preferredContentSize = preferredContentSizeFor(tableView: contentController.tableView)
        }
    }
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        //The user tapped beside the popover
        
        //Cancel the selection, return nil
        continuation?.resume(returning: nil)
        continuation = nil
    }
}
