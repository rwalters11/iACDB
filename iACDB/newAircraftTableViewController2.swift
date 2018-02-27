//
//  newAircraftTableViewController2.swift
//  iACDB
//
//  Created by Richard Walters on 13/02/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//

// Import Apple frameworks
import UIKit
import CoreData

// Import 3rd party frameworks
import SwiftyJSON
import Kingfisher

class newAircraftTableViewController2: UITableViewController, NSFetchedResultsControllerDelegate , UISearchResultsUpdating, UISearchBarDelegate {
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    // Setup controller to manage our data NSFetched results style
    var frc: NSFetchedResultsController<NSFetchRequestResult>!
    
    var deleteNewAircraftIndexPath: IndexPath? = nil
    
    var returnedAircraft = infoAircraft(inRegistration: "")
    
    // Get context for CoreData
    let moc = getContext()
    
    // For searching our records carried by the FetchedResultsController
    var resultSearchController = UISearchController(searchResultsController: nil)
    
    // https Server communication
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    
    // Return segue from Aircraft Details after processing
    @IBAction func unwindToNewAircraftVC(segue:UIStoryboardSegue) {
        
        // True if Aircraft record created
        if (returnedAircraft != nil) {
            
            // Send aircraft to server
            if addAircraft(inAircraft: returnedAircraft!)
            {
            // If new aircraft successfully converted to aircraft record then remove from CoreData & FRC
            
            // TODO
            }
        }
    }
    
    // On successful load
    override func viewDidLoad() {
        
        //Load parent class - required
        super.viewDidLoad()
        
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        // Sync of CoreData cache
        syncNewAircraft2RemoteDB()
        
        // MARK: - Search Controller & SearchBar Setup
        
        // Initialise search controller after the core data
        self.resultSearchController.searchResultsUpdater = self
        
        self.resultSearchController.obscuresBackgroundDuringPresentation = false
        self.resultSearchController.searchBar.placeholder = "Search registrations"
        
        // Set to all upper case otherise it does not match values in CoreData or DB.
        self.resultSearchController.searchBar.autocapitalizationType = UITextAutocapitalizationType.allCharacters
        
        // New in iOS 11 you can embed the search bar in the navigation bar !
        if #available(iOS 11.0, *) {
            navigationItem.searchController = self.resultSearchController
        } else {
            // Fallback on earlier versions
            self.resultSearchController.searchBar.sizeToFit()
        }
        
        // Makes the SearchBar stay in the current screen and not spill into the next screen
        definesPresentationContext = true
        
        self.resultSearchController.searchBar.scopeButtonTitles = ["All", "Reg", "Hex"]
        self.resultSearchController.searchBar.delegate = self
        
        // Setup the initial fetched results controller
        sortFRC(searchPredicate: nil)
    }
    
    // MARK: - Fetched Results Controller
    
    // Updates the tableView with the search results as the user is typing ...
    func updateSearchResults(for searchController: UISearchController) {
        
        // Process the search string, removw leading and trailing spaces
        let searchText = searchController.searchBar.text!
        let trimmedSearchString = searchText.trimmingCharacters(in: NSCharacterSet.whitespaces)
        
        // If search string is not blank
        if !trimmedSearchString.isEmpty {
            
            // Form the search format
            let searchPredicate = NSPredicate(format: "registration BEGINSWITH %@", trimmedSearchString)
            
        sortFRC(searchPredicate: searchPredicate)
            
        }else {
            
            // reset to all
            sortFRC(searchPredicate: nil)
        }

    }
    
    // MARK: Fetched Results Controller Display Sorting & Grouping
    
    func sortFRC(searchPredicate: NSPredicate?) {
        
        let searchBar = self.resultSearchController.searchBar
        
        // Setup NSFetchResultController for table (entity)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntNewAircraft")
        let scopeIndex = searchBar.selectedScopeButtonIndex
        
        // Construct the frc parameters
        // Setup sorts
        let fetchSort = NSSortDescriptor(key: "registration", ascending: true)
        fetchRequest.sortDescriptors = [fetchSort]
        
        // Set limit to number of aircraft listed on screen
        //fetchRequest.fetchLimit = 10
        
        switch scopeIndex {
            
        case 1: // No sections - List Registrations
            
            // Form the search format
            let regString = "(Hex)"
            let regPredicate = NSPredicate(format: "NOT (registration CONTAINS %@)", regString)
            //fetchRequest.fetchLimit = 5
            
            if searchPredicate != nil {
                
                // Add the search filter(s)
                let multiplePredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [regPredicate, searchPredicate!])
                fetchRequest.predicate = multiplePredicate
                
            }else{
                
                fetchRequest.predicate = regPredicate
            }
            
        case 2: // No sections - List Hex Codes
            
            // Form the search format
            let regString = "(Hex)"
            let regPredicate = NSPredicate(format: "registration ENDSWITH %@", regString)
            //fetchRequest.fetchLimit = 7
            
            if searchPredicate != nil {
                
                // Add the search filter(s)
                let multiplePredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [regPredicate, searchPredicate!])
                fetchRequest.predicate = multiplePredicate
                
            }else{
                
                fetchRequest.predicate = regPredicate
            }

        case 0:// No sections - List All
            
            if searchPredicate != nil {
                
                // Add the passed in search filter
                fetchRequest.predicate = searchPredicate
            }
            
        default:
            break
        }
        
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        // Set this class to handle the events from the controller
        frc.delegate = self
        
        // Perform the fetch
        do {
            try frc.performFetch()
            
        }catch let error as NSError {
            rwPrint(inFunction: #function, inMessage:"Unable to perform fetch of Spots: \(error.localizedDescription)")
        }
        
        // Refresh the tableView
        self.tableView.reloadData()
    }
    
    // MARK: - SearchBar Delegates
    
    // Function to respond to user making scope bar selection
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        sortFRC(searchPredicate: nil)
    }
    
    // MARK: - Tableview Data Source & Delegates
    
    // Update the section titles
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch resultSearchController.searchBar.selectedScopeButtonIndex {
            
        case 0:
            return "All"
            
        case 1:
            return "Registration"
            
        case 2:
            return "Mode S"
            
        default:
            return nil
            
        }
        
    }
    
    // Customise the section titles
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let sectionInfo = frc.sections?[section] else { fatalError("Unexpected Section")}
        
        switch resultSearchController.searchBar.selectedScopeButtonIndex {
            
        case 0,1,2:
            return nil
            
        case 3:
            
            // Create the custom header cell frame
            let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 20))
            returnedView.backgroundColor = .lightGray
            
            // Create the text label
            let label = UILabel(frame: CGRect(x: 10, y: 7, width: view.frame.size.width, height: 20))
            label.text = sectionInfo.name
            label.textColor = .white
            
            // Add the label to the view
            returnedView.addSubview(label)
            
            return returnedView
            
        default:
            return nil
            
        }
    }
    
    //Update the number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let sectionCount = frc.sections?.count else {
            return 0
        }
        return sectionCount
    }
    
    //Update the number of rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let sectionData = frc.sections?[section] else {
            return 0
        }
        return sectionData.numberOfObjects
        
    }
    
    // Update the cells in the tableView from dataSource array
    override func tableView(_ tableView: UITableView, cellForRowAt IndexPath: IndexPath) -> UITableViewCell {
        
        // Get cell to update
        let cell = tableView.dequeueReusableCell(withIdentifier: "newACCell", for: IndexPath) as! newAircraftTableViewCell
        
        // CoreData NSFetchedResults style
        let nsfNewAircraft = frc.object(at: IndexPath) as! EntNewAircraft
        
        cell.lblRegHex.text = nsfNewAircraft.registration
        cell.lblCount.text = "(" + String(nsfNewAircraft.count) + ")"
        
        return cell
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            /*
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) {
                configureCell(cell, at: indexPath)
            }
             */
            break;
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     
        deleteNewAircraftIndexPath = indexPath
        confirmDelete(delIndexPath: indexPath)
        
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
 
    
    // MARK: Functions
    
    // Function to confirm deletion of a reg/hex
    func confirmDelete(delIndexPath: IndexPath) {
        
        // CoreData NSFetchedResults style
        let nsfNewAircraft = frc.object(at: delIndexPath) as! EntNewAircraft
        let registration: String = nsfNewAircraft.registration!
        
        let alert = UIAlertController(title: "Delete New Aircraft", message: "Are you sure you want to permanently delete \(registration)?", preferredStyle: .actionSheet)
        
        let DeleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: handleDeleteNewAircraft)
        let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelDeleteNewAircraft)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = self.view
        //alert.popoverPresentationController?.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleDeleteNewAircraft(alertAction: UIAlertAction!) -> Void {
        if let indexPath = deleteNewAircraftIndexPath {
            
            deleteNewAircraftIndexPath = nil
            
            // Fetch New Aircraft obj
            let objNewAC = frc.object(at: indexPath)
            
            // Delete from fetched results
            frc.managedObjectContext.delete(objNewAC as! NSManagedObject)
            
            // Delete from CoreData & server DB
            deleteNewAircraftCD(item: objNewAC as! EntNewAircraft)
            
        }
    }
    
    func cancelDeleteNewAircraft(alertAction: UIAlertAction!) {
        deleteNewAircraftIndexPath = nil
    }
    
    // Do the preparation for showing the next view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "newACShowDetails") {
            
            // Set the class of the details View controller
            let svc = segue.destination as! aircraftDetailsViewController2;
            
            let path = tableView.indexPathForSelectedRow
            let cell = tableView.cellForRow(at: path!) as! newAircraftTableViewCell
            
            // Pass the registration to the details view
            svc.inRegistration = (cell.lblRegHex.text)!
            svc.formDisabled = false
            svc.inSource = "New"
            
            // Set the custom value of the Back Item text to be shown in the details view
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
        }
    }

}
