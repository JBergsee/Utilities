//
//  TheBestTableViewController.swift
//  TheBestTableViewController
//
//  Created by Johan Nyman on 2022-07-05.
//

import UIKit


/** Based on https://stackoverflow.com/questions/36507885/expand-collapse-uitableview-sections-with-a-backing-nsfetchedresultscontroller
 and even more https://github.com/jeantimex/CollapsibleTableSectionViewController
*/

//Might have to be an extension of the modelprovider directly! 
extension GenericTableViewController: CollapseControllingDelegate {
    
    public func toggleSection(_ section: Int, for header: CollapseControlling?) {
        
        tableView.beginUpdates()
        
        // Toggle collapse
        let sectionCollapsed = !isCollapsed(section)
        // Update the sections state
        sectionsState[modelProvider!.uuid(for: section)] = sectionCollapsed
        
        //Update view
        
        //Gather indexsets for affected rows
        let nbrOfRows = modelProvider!.rowsIn(section: section)
        var rowPaths = [IndexPath]()
        if nbrOfRows > 0 {
            for i in 0...nbrOfRows - 1 {
                rowPaths.append(IndexPath(row: i, section: section))
            }
            //delete or insert as applicable
            if (sectionCollapsed) {
                tableView.deleteRows(at: rowPaths, with: .bottom)
            } else {
                tableView.insertRows(at: rowPaths, with: .bottom)
            }
        }
        //update header
        header?.setCollapsed(sectionCollapsed, animated: true)
        
        tableView.endUpdates()
    }
}

open class GenericTableViewController: UITableViewController, GenericTableViewControlling {
    
    //Basis for the whole controller
    public weak var modelProvider: ModelProviding?
    public weak var delegate: GenericTableViewDelegate?
            
    //For FRC Delegate
    var _changeIsUserDriven: Bool = false
    
    //For searching
    //The searchcontroller
    private var searchController: UISearchController?
    
    //MARK: - View cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupSearch()
        tableView.sectionHeaderTopPadding = 0
    }
    
    //MARK: - Collapsing
    
    /// True for collapsed
    private var sectionsState = [String : Bool]()
    
    /// Default open is true, change to false in view did load if all sections should be closed by default
    public var defaultOpen = true
    
    public func isCollapsed(_ section: Int) -> Bool {
        let sectionId = modelProvider!.uuid(for: section)
        if sectionsState.index(forKey: sectionId) == nil {
            sectionsState[sectionId] = !defaultOpen //set default value if not set before
        }
        return sectionsState[sectionId]!
    }
    
    
    // MARK: - Table view data source
    
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return modelProvider!.numberOfSections()
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isCollapsed(section) ? 0 : modelProvider!.rowsIn(section: section)
    }
    
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: delegate?.cellIdentifier ?? "cell", for: indexPath)
        
        if let cell = cell as? ModelConfigurable {
            //Get the model
            let model = modelProvider!.modelFor(row: indexPath.row, section: indexPath.section)
            
            // Configure the cell...
            cell.configureWith(model: model)
        }
        
        return cell
    }
    
    //MARK: Headers and footers
    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return modelProvider?.headerTitle(section)
    }
    
    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: delegate?.headerIdentifier ?? "header")
        
        guard let header = cell?.contentView.subviews.first else {
            return nil
        }
        //Collapsible?
        if let collapseHeader = header as? CollapseControlling {
            collapseHeader.delegate = self //Or modelprovider if changed later on?
            collapseHeader.section = section
            collapseHeader.setCollapsed(isCollapsed(section), animated: false) //Do not animate at creation
        }
        //Configurable?
        if let configurableHeader = header as? ModelConfigurable {
            configurableHeader.configureWith(model: modelProvider!.modelForHeader(section: section))
        }
        return header
    }
    
    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: delegate?.footerIdentifier ?? "footer")
        guard let footer = cell?.contentView.subviews.first else {
            return nil
        }
        //Configurable?
        if let configurableFooter = cell?.contentView.subviews.first as? ModelConfigurable {
            configurableFooter.configureWith(model: modelProvider!.modelForFooter(section: section))
        }
        return footer
    }
    
    ///Return 0.0 to suppress header. Default is automaticDimension
    open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    ///Return 0.0 to suppress footer. Default is automaticDimension
    open override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    //MARK: - Rearranging
    
    open override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return modelProvider!.canEdit(row: indexPath.row, section: indexPath.section)
    }
    
    
    open override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data sorce
            modelProvider!.delete(row: indexPath.row, section: indexPath.section)
            //update view
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            modelProvider!.insertAt(row: indexPath.row, section: indexPath.section)
            tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }
    
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */

//MARK: - Search setup
    
    private func setupSearch() {
        
        searchController = UISearchController(searchResultsController: nil) //init with nil to display results in same window
        
        // Use the current view controller to update the search results.
        searchController?.searchResultsUpdater = self
        searchController?.obscuresBackgroundDuringPresentation = false // default is YES, set to NO if presenting in same controller as searching from.
        
        //This is the delegate
        searchController?.delegate = self
        
        //Always show the nav bar
        searchController?.hidesNavigationBarDuringPresentation = false //Default is true
        
        //Overrideable features
        setup(searchBar: searchController?.searchBar)
        install(searchController: searchController)
    }
    
    open func setup(searchBar: UISearchBar?) {
        
        guard let searchBar = searchBar else {
            return
        }
        
        searchBar.showsScopeBar = false
        searchBar.sizeToFit()
        
        //Set grayish so placeholder text is visible
        searchBar.searchTextField.backgroundColor = .secondarySystemBackground
        
        searchBar.placeholder = delegate?.searchPlaceHolder ?? "Search..."
        
        //Remove any suggestions
        let item = searchBar.inputAssistantItem
        item.leadingBarButtonGroups = []
        item.trailingBarButtonGroups = []
        searchBar.autocorrectionType = .no;
        
    }
    
    //May be overridden by subclasses
    open func install(searchController: UISearchController?) {
        guard let searchController = searchController else {
            return
        }
        
        // Install the search bar in the navigationitem
        navigationItem.searchController = searchController;
        definesPresentationContext = true //So the searchbar does not remain on screen if we go to another screen
        
        
        /** According Apple Dev Support
         Showing the search bar all the time is required in order to fix graphics bug in iOS 13... and 14...
         Setting to hide it here, as this is the original design, but overrides by subclasses to avoid the bug. */
        self.navigationItem.hidesSearchBarWhenScrolling = true
        /*
         https://stackoverflow.com/questions/55561082/tableview-first-cell-hidden-under-search-bar-when-returning-to-view
         */
        
        searchController.isModalInPresentation = true
        /* Correcting iOS 13 bug as described here:
         https://medium.com/@hacknicity/view-controller-presentation-changes-in-ios-13-ac8c901ebc4e
         */
        
        //Add a button for access!
        addSearchButton()
    }
    
    open func addSearchButton() {
        let searchButton = UIBarButtonItem(barButtonSystemItem: .search,
                                           target: self,
                                           action: #selector(showSearchBar))
        
        navigationItem.rightBarButtonItem = searchButton
        //(Could eventually use the array to add the search button with other items.)
    }
    
    @IBAction open func showSearchBar()
    {
        searchController?.searchBar.becomeFirstResponder()
    }
}


extension GenericTableViewController: UISearchControllerDelegate {
}


extension GenericTableViewController: UISearchResultsUpdating {
    
    open func updateSearchResults(for searchController: UISearchController) {
        
        //Get the search text
        var searchText = searchController.searchBar.text
        // strip out all the leading and trailing spaces
        searchText = searchText?.trimmingCharacters(in: .whitespaces)
        
        //actual search performed by model provider
        modelProvider?.filterModel(searchText: searchText)
        
        //update view
        tableView.reloadData() //Not required for FRC...?
    }
}

