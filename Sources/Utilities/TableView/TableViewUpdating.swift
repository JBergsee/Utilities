//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-11-28.
//

import UIKit
import JBLogging

@objc public protocol TableViewUpdating {
    
    ///To be called during initialization of the UITableviewController, i.e during viewDidLoad
    func installUpdater()
    ///The text to display when the tableview is pulled down
    var updateText: String { get }
    ///The action to perform for the actual update
    func performUpdate()
    ///Call endUpdate when the update has finished
    func endUpdate()
}

extension UITableViewController: TableViewUpdating {

    @objc open var updateText: String {
        "Override with suitable text"
    }
    
    @objc open func installUpdater() {
        let refreshControl = UIRefreshControl()
        let attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)]
        refreshControl.attributedTitle = NSAttributedString(string: updateText, attributes: attributes)
        refreshControl.addTarget(self, action: #selector(performUpdate), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc open func performUpdate() {
        Log.fault(message: "performUpdate must be overridden by \(Self.self)", in: .functionality)
        // Do nothing by default, but call end update
        endUpdate()
    }
    
    @objc open func endUpdate() {
        //Stop the refresh control
        refreshControl?.endRefreshing()
    }
}
