//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-11-28.
//

import UIKit

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
    
    open func installUpdater() {
        let refreshControl = UIRefreshControl()
        let attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)]
        refreshControl.attributedTitle = NSAttributedString(string: updateText, attributes: attributes)
        refreshControl.addTarget(self, action: #selector(performUpdate), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc open func performUpdate() {
        fatalError("performUpdate must be overridden by \(Self.self)")
    }
    
    open func endUpdate() {
        //Stop the refresh control
        DispatchQueue.main.async {
            self.refreshControl?.endRefreshing()
        }
    }
}
