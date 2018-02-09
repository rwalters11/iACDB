//
//  spotListTableViewController.swift
//  iACDB
//
//  Created by Richard Walters on 01/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//
// Import Apple frameworks

import UIKit
import CoreData
import Alamofire

class spotListTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // Setup controller to manage our data NSFetched results style
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    // View which contains the loading text and the spinner
    let loadingView = UIView()
    
    // Spinner shown during load
    let spinner = UIActivityIndicatorView()
    
    // Text shown during load
    let loadingLabel = UILabel()
    
    // Clear button action
    @IBAction func resetButton(_ sender: Any) {
        
        // Ask user if they want to clear all uploaded Spots ?
        
        let message = "This will remove all uploaded Spots from the App"
        
        let alertController = UIAlertController(title: "iACDB", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        // Create the actions
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
            
            // Do nothing
        }
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.destructive ) {
            UIAlertAction in
            
            // Remove spots from list which have been successfully uploaded to the server
            self.deleteUploadedCells()
        }
        
        // Add the actions
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
            
        // Show the alert
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    @IBOutlet weak var segControl: UISegmentedControl!
    @IBAction func segControl(_ sender: UISegmentedControl) {
        
        // Sort the Fetched Results Controller according to the button segment selected
        sortFRC(inSegment: segControl.selectedSegmentIndex)
    }
    
    // Unwind segue from Add Spot Screen - Cancel
    @IBAction func btnCancel(segue: UIStoryboardSegue) {
        
    }
    
    // Unwind segue from Add Spot Screen - Add
    @IBAction func btnAdd (segue: UIStoryboardSegue) {
        
    }
    
    override func viewDidLoad()
    {
        
        super.viewDidLoad()
        
        // Get ref to the network monitor
        let netMonitor = appDelegate.netMonitor!
        
        var networkStatus: String = "TBGweb server "
        
        // Start the listener
        netMonitor.listener = { status in
            
            // Take action depending on status 1st pass - identify status
            switch status {
                
            case .notReachable:
                networkStatus += "is not reachable"
                
            case .unknown:
                networkStatus += "status unknown"
                
            case .reachable(.ethernetOrWiFi):
                networkStatus += "is WiFi reachable"
                
            case .reachable(.wwan):
                networkStatus += "is reachable via mobile data"
            }
            
            print(networkStatus)
            
            // Take action depending on status - 2nd pass
            switch status {
                
                // Do nothing
            case .notReachable, .unknown:
                break
                
                // Trigger sync of CoreData caches
            case .reachable(.ethernetOrWiFi), .reachable(.wwan):
                
                syncAircraft2RemoteDB(inController: self)
                
                syncLocations2RemoteDB()
                syncTypes2RemoteDB()
                syncOperators2RemoteDB()
                
                break
            }
        }
        
        // Setup the initial sort & display order for the FRC
        sortFRC(inSegment: 0)
        
        // Add a long press gesture recognizer to trigger retry of uploads
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(spotListTableViewController.retryUpload))
        self.tableView.addGestureRecognizer(recognizer)
        
    }
    
    // Function to retry upload of Spot in response to long press gesture
    @objc func retryUpload(recognizer: UILongPressGestureRecognizer) {
        
        if recognizer.state == UIGestureRecognizerState.ended {
            
            // Identify cell
            let pressLocation = recognizer.location(in: self.tableView)
            if let pressedIndexPath = tableView.indexPathForRow(at: pressLocation) {
                
                // Get cell
                if let pressedCell = self.tableView.cellForRow(at: pressedIndexPath) as? spotInfoTableViewCell {
                    
                    // Using the accessibilityLabel as a holder for the status numeric value
                    let spStatus = Int(pressedCell.imgUploaded.accessibilityLabel!) ?? 0
    
                    // Start retry depending on status
                    switch spStatus
                    {
                        // Waiting, unknown or failed
                        case -1, 1, 3:
                        
                        // Get values
                        let tapRegistration = pressedCell.lblRegistration.text
                        let tapLocation = pressedCell.lblLocation.text
                        let tapDate = pressedCell.lblDayDate.text
                        
                        // Instantiate Spot using Registration
                        let retrySpot: infoSpot = infoSpot(inRegistration: tapRegistration!)
                        
                        // Assign values
                        retrySpot.setLocation(inLocation: tapLocation!)
                        retrySpot.setName(inName: defaults.string(forKey: "name")!)
                        retrySpot.setDate(inDate: tapDate!)
                        
                        // Move status on to show ready for further processing
                        retrySpot.setStatus(inStatus: .Waiting)
                        
                        // Placeholder, uploaded, uploading
                        case 0,2,4:
                            break
                        
                        default:
                            break
                        
                    }
                    
                }
            }
        }
    }
    
    // MARK: Fetched Results Controller Display Sorting & Grouping
    
    func sortFRC(inSegment: Int) {
        
        // Get context for CoreData
        let moc = getContext()
        
        // Setup NSFetchResultController for table (entity)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntSpots")
        
        // Construct the frc parameters
        
        switch inSegment {
            
        case 0: // No sections - List by Registration
            
            // Setup sorts
            let fetchSort = NSSortDescriptor(key: "registration", ascending: true)
            fetchRequest.sortDescriptors = [fetchSort]
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
            
        case 1: // Grouped into sections by Date
            
            // Setup sorts
            let fetchSort1 = NSSortDescriptor(key: "date", ascending: false)
            let fetchSort2 = NSSortDescriptor(key: "registration", ascending: true)
            fetchRequest.sortDescriptors = [fetchSort1, fetchSort2]
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: #keyPath(EntSpots.sectionDate), cacheName: nil)
            
        case 2:// Grouped into sections by Location
            
            // Setup sorts
            let fetchSort1 = NSSortDescriptor(key: "location", ascending: true)
            let fetchSort2 = NSSortDescriptor(key: "registration", ascending: true)
            fetchRequest.sortDescriptors = [fetchSort1, fetchSort2]
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: #keyPath(EntSpots.location), cacheName: nil)
            
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
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Refresh the tableView when navigating back to view
        self.tableView.reloadData()
    }
    
    
    
    // MARK: - Table view data source
    
    // Update the section titles
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        guard let sectionInfo = fetchedResultsController.sections?[section] else { fatalError("Unexpected Section")}
        
        switch segControl.selectedSegmentIndex {
            
        case 0:
            return "All"
            
        case 1,2:
            
            // Return the text created by the FRC
            return sectionInfo.name
            
        default:
            return nil
            
        }
        
    }
    
    // Customise the section titles
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let sectionInfo = fetchedResultsController.sections?[section] else { fatalError("Unexpected Section")}
        
        switch segControl.selectedSegmentIndex {
            
        case 0:
            return nil
            
        case 1,2:
        
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
    
    // Update the number of sections in table
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let sectionCount = fetchedResultsController.sections?.count else {
            return 0
        }
        return sectionCount
        
    }
    
    //Update the number of rows in each section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let sectionData = fetchedResultsController.sections?[section] else {
            return 0
        }
        return sectionData.numberOfObjects
        
    }
    
    // Update the cells in the tableView from CoreData
    override func tableView(_ tableView: UITableView, cellForRowAt IndexPath: IndexPath) -> UITableViewCell {
        
        // Get cell to update
        let cell = tableView.dequeueReusableCell(withIdentifier: "acSpotCell", for: IndexPath) as!spotInfoTableViewCell
        
        // Do the cell configuration in shared helper method
        configureCell(cell: cell , atIndexPath: IndexPath)
        
        // Return the updated cell
        return cell
    }
    
    // Delete row by swiping functionality
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            deleteCell(atIndexPath: indexPath)
        }
        
        // Update the tableView
        self.tableView.reloadData()
    }
    
    // MARK: -  FetchedResultsController Delegates to handle updating tableview when changes are made to the CoreData
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .automatic)
        default: break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
            
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath)
            {
                // Do the cell configuration in shared helper method
                configureCell(cell: cell as! spotInfoTableViewCell, atIndexPath: indexPath)
            }
            
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            
        default: break
        }
        
        // Refresh the tableView display
        self.tableView.reloadData()
    }
    
    /*
     *
     * Helper method to delete CoreData for this cells data
     *
     */
    func deleteCell(atIndexPath indexPath: IndexPath) {
        
        // Get the ManagedObjectContext from the App delegate
        let moc = getContext()
        
        // CoreData NSFetchedResults style
        let nsfSpot = fetchedResultsController.object(at: indexPath) as! EntSpots
        
        let stSpot: Int = Int(nsfSpot.status)
        
        // If spot not uploaded - check with user
        if stSpot != spotStatus.Uploaded.rawValue {
            
            let message = "Spot for: not yet uploaded. Do you want to delete it?"
            
            let alertController = UIAlertController(title: "iACDB", message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            // Create the actions
            let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel) {
                UIAlertAction in
                
                // Do nothing
                
            }
            
            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive) {
                UIAlertAction in
                
                // Do the deletion
                moc.delete(nsfSpot)
                
                // Save the changes
                do {
                    // Do the save
                    try moc.save()
                    
                } catch let error as NSError {
                    rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
                }
            }
            
            // Add the actions
            alertController.addAction(yesAction)
            alertController.addAction(noAction)
            
                
            // Show the alert
            self.present(alertController, animated: true, completion: nil)
            
        }else{
        
            // Do the deletion
            moc.delete(nsfSpot)
            
            // Save the changes
            do {
                // Do the save
                try moc.save()
                
            } catch let error as NSError {
                rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    /*
     *
     * Function to delete cells from CoreData whose records have been successfully uploaded
     *
     */
    func deleteUploadedCells() {
        
        // Get the ManagedObjectContext from the App delegate
        let moc = getContext()
        
        // Setup NSFetchResultController for table (entity)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntSpots")
        
        // Setup sort(s)
        let fetchSort = NSSortDescriptor(key: "registration", ascending: true)
        fetchRequest.sortDescriptors = [fetchSort]
        
        // Setup predicate(s) - flter
        let pStatus: Int16 = Int16(spotStatus.Uploaded.rawValue)
        let predicate = NSPredicate(format: "status == %i", pStatus)
        fetchRequest.predicate = predicate
        
        // Fetch the results that match
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [EntSpots]
        
        // Loop through the returned array and delete the items
        for object in resultData {
            moc.delete(object)
        }
        
        // Save the changes
        do {
            // Do the save
            try moc.save()
            
        } catch let error as NSError {
            rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
        }
        
        // Refresh the tableView
        self.tableView.reloadData()
        
    }
    
    /*
     *
     * Helper method to configure the table cell
     *
     */
    func configureCell(cell: spotInfoTableViewCell, atIndexPath indexPath: IndexPath)
    {
        // CoreData NSFetchedResults style
        let nsfSpot = fetchedResultsController.object(at: indexPath) as! EntSpots
        
        cell.lblRegistration.text = nsfSpot.registration
        cell.lblLocation.text = nsfSpot.location
        
        // Based on selected button segment
        switch segControl.selectedSegmentIndex {
            
            // Show day/date when grouped by Reg or Location
        case 0,2:
            cell.lblDayDate.text = nsfSpot.sectionDate
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, dd-MM-yyyy"
            
            cell.lblDayDate.text = formatter.string(from: nsfSpot.date! as Date)
            
            // Suppress day/date when grouped by Date
        case 1:
            cell.lblDayDate.text = ""
            break
            
        default:
            // Do nothing
            break
        }
        
        // Get the details from the cache if exists
        let aircraftDetails = getAircraftDetailsFromCache(inRegistration: nsfSpot.registration!)
        
        // Update the fields if valid
        if !aircraftDetails.acType.isEmpty {
            
            // Aircraft exists in cache
            cell.lblTypeSeries.text = aircraftDetails.acType + "-" + aircraftDetails.acSeries
            cell.lblTypeSeries.textColor = UIColor.darkGray
            cell.lblOperator.text = aircraftDetails.acOperator
            
        }else{
            
            // New
            cell.lblTypeSeries.text = "New"
            cell.lblTypeSeries.textColor = UIColor.green
            cell.lblOperator.text = ""
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
        
        let stSpot: Int = Int(nsfSpot.status)
        
        // Using the accessibilityLabel as a holder for the status numeric value
        cell.imgUploaded.accessibilityLabel = String(stSpot)
        
        // Set upload status icon
        switch stSpot
        {
        case -1:
            cell.imgUploaded.image = #imageLiteral(resourceName: "Unknown")
        case 1:
            cell.imgUploaded.image = #imageLiteral(resourceName: "WaitingToUpload")
        case 2:
            cell.imgUploaded.image = #imageLiteral(resourceName: "UploadedOK")
        case 3:
            cell.imgUploaded.image = #imageLiteral(resourceName: "UploadFailed")
        case 4:
            // Updating
            cell.imgUploaded.image = #imageLiteral(resourceName: "Updating")
            
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            activityIndicator.hidesWhenStopped = true
            activityIndicator.center = cell.imgUploaded.center
            activityIndicator.startAnimating()
            
        default:
            cell.imgUploaded.image = #imageLiteral(resourceName: "WaitingToUpload")
        }
    }
    
    // Do the preparation for showing the next view (going forwards)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier!
        {
        case "showACDetails":
            
            // Set the class of the details View controller
            let svc = segue.destination as! aircraftDetailsViewController2;
            
            let path = tableView.indexPathForSelectedRow
            let cell = tableView.cellForRow(at: path!) as! spotInfoTableViewCell
            
            // Pass the registration to the details view
            svc.inRegistration = (cell.lblRegistration.text)!
            svc.formDisabled = true
            
            // Set the custom value of the Back Item text to be shown in the Details view
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
            
            // Hide the Add Spot RH menu bar item
            svc.inMenuSpot = false
            
        case "showAddSpotForm":
            
            // Set the class of the AddSpot View controller
            let svc = segue.destination as! addSpotViewController2
            
            svc.inRegistration = ""
            
            let backItem = UIBarButtonItem()
            backItem.title = "Add"
            navigationItem.backBarButtonItem = backItem
            
        default: break
            // Do nothing
        }
    }
    
    // Set the activity indicator into the main view
    func setLoadingScreen() {
        
        // Sets the view which contains the loading text and the spinner
        let width: CGFloat = 120
        let height: CGFloat = 30
        let x = (self.tableView.frame.width / 2) - (width / 2)
        let y = (self.tableView.frame.height / 2) - (height / 2) - (self.navigationController?.navigationBar.frame.height)!
        loadingView.frame = CGRect(x:x, y:y, width:width, height:height)
        
        // Sets loading text
        self.loadingLabel.textColor = UIColor.gray
        self.loadingLabel.textAlignment = NSTextAlignment.center
        self.loadingLabel.text = "Loading..."
        self.loadingLabel.frame = CGRect(x:0, y:0, width:140, height:30)
        
        // Sets spinner
        self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        self.spinner.frame = CGRect(x:0, y:0, width:30, height:30)
        self.spinner.startAnimating()
        
        // Adds text and spinner to the view
        loadingView.addSubview(self.spinner)
        loadingView.addSubview(self.loadingLabel)
        
        self.tableView.addSubview(loadingView)
        
    }
    
    // Remove the activity indicator from the main view
    func removeLoadingScreen() {
        
        // Hides and stops the text and the spinner
        self.spinner.stopAnimating()
        self.loadingLabel.isHidden = true
        
    }
    
}

