//
//  newAircraftTableViewController.swift
//  iACDB
//
//  Created by Richard Walters on 11/02/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//

import UIKit
import CoreData
import Alamofire

class newAircraftTableViewController: UITableViewController,  NSFetchedResultsControllerDelegate, UISearchResultsUpdating   {
    
    // Setup controller to manage our data NSFetched results style
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    // For searching our records carried by the FetchedResultsController
    var resultSearchController = UISearchController(searchResultsController: nil)
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var segControl: UISegmentedControl!
    @IBAction func segControl(_ sender: UISegmentedControl) {
        
        // Sort the Fetched Results Controller according to the button segment selected
        sortFRC(inSegment: segControl.selectedSegmentIndex)
    }
    
    @IBOutlet weak var btnSearch: UIBarButtonItem!
    @IBAction func btnSearch(_ sender: UIBarButtonItem) {
        
        // Places the built-in SearchBar into the table header
        self.tableView.tableHeaderView = self.resultSearchController.searchBar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        // Sync of CoreData cache
        syncNewAircraft2RemoteDB()
        
        // Setup the initial sort & display order for the FRC
        sortFRC(inSegment: 2)
        
        // Initialise search controller after the core data
        self.resultSearchController.searchResultsUpdater = self
        self.resultSearchController.dimsBackgroundDuringPresentation = false
        self.resultSearchController.searchBar.sizeToFit()
        // Set to all upper case otherise it does not match values in CoreData or DB.
        self.resultSearchController.searchBar.autocapitalizationType = UITextAutocapitalizationType.allCharacters
        
        // Makes the SearchBar stay in the current screen and not spill into the next screen
        definesPresentationContext = true
        
        
    }
    
    // Updates the tableView with the search results as the user is typing ...
    func updateSearchResults(for searchController: UISearchController) {
        
        // Process the search string, removw leading and trailing spaces
        let searchText = searchController.searchBar.text!
        let trimmedSearchString = searchText.trimmingCharacters(in: NSCharacterSet.whitespaces)
        
        // If search string is not blank
        if !trimmedSearchString.isEmpty {
            
            // Form the search format
            let predicate = NSPredicate(format: "acRegistration BEGINSWITH %@", trimmedSearchString)
            
            // Add the search filter
            fetchedResultsController.fetchRequest.predicate = predicate
            
            
        }else {
            
            // reset to all
            //fetchedResultsController = sortFRC(inSegment: 2)
        }
        
        // Reload the frc
        fetch(frcToFetch: fetchedResultsController)
        
        // Refresh the tableView
        self.tableView.reloadData()
    }
    
    // Function to update the contents of a FetchedResultsController
    func fetch(frcToFetch: NSFetchedResultsController<NSFetchRequestResult>)
    {
        do {
            try frcToFetch.performFetch()
        } catch {
            return
        }
    }
    
    // MARK: Fetched Results Controller Display Sorting & Grouping
    
    func sortFRC(inSegment: Int) {
        
        // Get context for CoreData
        let moc = getContext()
        
        // Setup NSFetchResultController for table (entity)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntNewAircraft")
        
        // Construct the frc parameters
        
        switch inSegment {
            
        case 0: // No sections - List Registrations
            
            // Setup sorts
            let fetchSort = NSSortDescriptor(key: "registration", ascending: true)
            fetchRequest.sortDescriptors = [fetchSort]
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
            
        case 1: // No sections - List Hex Codes
            
            // Setup sorts
            let fetchSort = NSSortDescriptor(key: "registration", ascending: true)
            fetchRequest.sortDescriptors = [fetchSort]
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
            
        case 2:// No sections - List All
            
            // Setup sorts
            let fetchSort = NSSortDescriptor(key: "registration", ascending: true)
            fetchRequest.sortDescriptors = [fetchSort]
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
            
        default:
            break
        }
        
        // Set this class to handle the events from the controller
        fetchedResultsController.delegate = self
        
        // Perform the fetch
        do {
            try fetchedResultsController.performFetch()
            
        }catch let error as NSError {
            rwPrint(inFunction: #function, inMessage:"Unable to perform fetch of Spots: \(error.localizedDescription)")
        }
        
        // Refresh the tableView
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    // Update the section titles
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        //guard let sectionInfo = fetchedResultsController.sections?[section] else { fatalError("Unexpected Section")}
        
        switch segControl.selectedSegmentIndex {
            
        case 0:
            return "Mode S"
            
        case 1:
            return "Registration"
            
        case 2:
            return "All"
            
        default:
            return nil
            
        }
        
    }
    
    // Customise the section titles
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let sectionInfo = fetchedResultsController.sections?[section] else { fatalError("Unexpected Section")}
        
        switch segControl.selectedSegmentIndex {
            
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let sectionCount = fetchedResultsController.sections?.count else {
            return 0
        }
        return sectionCount
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let sectionData = fetchedResultsController.sections?[section] else {
            return 0
        }
        return sectionData.numberOfObjects
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get cell to update
        let cell = tableView.dequeueReusableCell(withIdentifier: "newACCell", for: indexPath) as! newAircraftTableViewCell
        
        // CoreData NSFetchedResults style
        let nsfNewAircraft = fetchedResultsController.object(at: indexPath) as! EntNewAircraft
        
        cell.lblRegHex.text = nsfNewAircraft.registration
        cell.lblCount.text = "(" + String(nsfNewAircraft.count) + ")"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //let cell = tableView.cellForRow(at: indexPath)  as! newAircraftTableViewCell
        
    }
    
    // Override to set custom Delete confirmation button text
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        
        // CoreData NSFetchedResults style
        let nsfNewAircraft = fetchedResultsController.object(at: indexPath) as! EntNewAircraft
            
            return "Delete \(nsfNewAircraft.registration!)"
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // CoreData NSFetchedResults style
        //let nsfNewAircraft = fetchedResultsController.object(at: indexPath) as! EntNewAircraft
            
            return true
        
        // Return false if you do not want the specified item to be editable.
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete
        {
            // Get the ManagedObjectContext from the App delegate
            let moc = getContext()
            
            
            // Save the values
            do {
                // Do the save
                try moc.save()
                
            } catch let error as NSError {
                rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    // MARK: -  FetchedResultsController Delegates to handle updating tableview when changes are made to the CoreData
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        // 1
        switch type {
        case .insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .automatic)
        default: break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // 2
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        default: break
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier!
        {
            
        case "showLocationDetails":
            
            // Set the class of the addSpot View controller
            if let svc = segue.destination as? locationDetailViewController {
                
                let path = tableView.indexPathForSelectedRow
                let cell = tableView.cellForRow(at: path!) as! locationsTableViewCell
                
                // Pass Location to details view
                svc.inLocation = (cell.lblLocation.text)!
                
            }
            
            // Set the default value of the Back Item text to be shown in next view
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
            
        case "addEditFromLocationsListSegue":
            
            // Set the class of the addSpot View controller
            if let svc = segue.destination as? addEditLocationViewController {
                
                // Pass Location to details view
                svc.inLocation = "New Location"
                
                svc.editLock = true
                
            }
            
            // Set the default value of the Back Item text to be shown in next view
            let backItem = UIBarButtonItem()
            backItem.title = "Add"
            navigationItem.backBarButtonItem = backItem
            
        default: break
            // Do nothing
        }
        
        
    }
    
}
