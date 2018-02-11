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

class newAircraftTableViewController: UITableViewController,  NSFetchedResultsControllerDelegate  {
    
    // Setup controller to manage our data NSFetched results style
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var segControl: UISegmentedControl!
    @IBAction func segControl(_ sender: UISegmentedControl) {
        
        // Sort the Fetched Results Controller according to the button segment selected
        sortFRC(inSegment: segControl.selectedSegmentIndex)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        // Display an Edit button in the navigation bar
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Sync of CoreData cache
        syncNewAircraft2RemoteDB()
        
        // Setup the initial sort & display order for the FRC
        sortFRC(inSegment: 2)
        
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
        
        // let cell = tableView.cellForRow(at: indexPath)  as! locationsTableViewCell
        
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
