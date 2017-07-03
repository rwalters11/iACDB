//
//  aircraftTableViewController.swift
//  iACDB
//
//  Created by Richard Walters on 02/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//

// Import Apple frameworks
import UIKit
import CoreData

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON

class aircraftTableViewController: UITableViewController, NSFetchedResultsControllerDelegate , UISearchResultsUpdating {
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    // Setup controller to manage our data NSFetched results style
    var frc: NSFetchedResultsController<NSFetchRequestResult>!

    // Get context for CoreData
    let moc = getContext()
    
    // For searching our records carried by the FetchedResultsController
    var resultSearchController = UISearchController(searchResultsController: nil)
    
    // http Server communication
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    
    // On successful load
    override func viewDidLoad() {
        
        //Load parent class - required
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        // Initialise Core Data FetchResultsController
        frc = getFRC()
        
        // Pull out CoreData records
        fetch(frcToFetch: frc)
        
        // Initialise search controller after the core data
        self.resultSearchController.searchResultsUpdater = self
        self.resultSearchController.dimsBackgroundDuringPresentation = false
        self.resultSearchController.searchBar.sizeToFit()
        // Set to all upper case otherise it does not match values in CoreData or DB.
        self.resultSearchController.searchBar.autocapitalizationType = UITextAutocapitalizationType.allCharacters
        
        // Places the built-in SearchBar into the table header
        self.tableView.tableHeaderView = self.resultSearchController.searchBar
        
        // Makes the SearchBar stay in the current screen and not spill into the next screen
        definesPresentationContext = true
        
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
    
    // Function to form the Fetch Request
    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntAircraft")
        let sortDescriptor = NSSortDescriptor(key: "acRegistration", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Set limit to number of aircraft listed on screen
        //fetchRequest.fetchLimit = 120
        
        return fetchRequest
    }
    
    func getFRC() -> NSFetchedResultsController<NSFetchRequestResult> {
        
        frc = NSFetchedResultsController(fetchRequest: fetchRequest(), managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        return frc
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
            frc.fetchRequest.predicate = predicate
            
            
        }else {
            
            // reset to all
            frc = getFRC()
        }
        
        // Reload the frc
        fetch(frcToFetch: frc)
        
        // Refresh the tableView
        self.tableView.reloadData()
    }
        
    // Fetch an aircraft image from theTBGweb server asynchronously using Alamofire/AlamofireImage
    func loadImageFromURL(inRegistration: String, inIndexPath: IndexPath, completionHandler: @escaping (UIImage?, IndexPath) -> () ){
        
        // Set default image to be returned
        let defaultImage: UIImage? = nil
        
        let acRegistration = inRegistration
        
        // Make sure search string is properly escaped
        let expectedCharSet = NSCharacterSet.urlQueryAllowed
        let searchTerm = acRegistration.addingPercentEncoding(withAllowedCharacters: expectedCharSet)
        
        // Set destination url & value to send including requested image width
        let url: String = "http://tbgweb.dyndns.info/iacdb/iosGetLatestImage.php"
        let postValues: [String: String] = ["registration": searchTerm!, "w": "100"]
        
        // Request the image from the server
        Alamofire.request(url, method: .get, parameters: postValues)
            .validate()
            .responseImage { response in
            
                debugPrint(response)
                
                // check for errors
                guard response.result.error == nil else {
                    // got an error in getting the data, need to handle it
                    debugPrint("error calling POST on image request")
                    debugPrint(response.result.error!)
                    
                    return
                }
                
                // Check for valid image and return
                guard let responseImage = response.result.value else
                {
                    completionHandler(defaultImage, inIndexPath)
                    return
                }
                
        /* TESTING
                
                // Assign image to background array looping through array to match image to correct registration
                // This caches the image to prevent repetitive calls to server while page scrolls
                for aircraft in self.acData {
                    
                    if aircraft.acRegistration == acRegistration {
                        
                        aircraft.setImage(inImage: responseImage)
                    }
                    
                }
 
        */
                
                // Return to completion handler with image
                completionHandler(responseImage, inIndexPath)
        }
        
    }
    
    // Do the preparation for showing the next view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "acShowDetails") {
            
            // Set the class of the details View controller
            let svc = segue.destination as! aircraftDetailsViewController;
            
            let path = tableView.indexPathForSelectedRow
            let cell = tableView.cellForRow(at: path!) as! AircraftInfoTableViewCell
            
            // Pass the registration to the details view
            svc.inRegistration = (cell.lblRegistration.text)!
            
            // Set the custom value of the Back Item text to be shown in the details view
            let backItem = UIBarButtonItem()
            backItem.title = "List"
            navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
        }
    }
    
    // MARK: - Table view data source
    
    //Update the number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        // return the number of sections
        return 1
    }

    //Update the number of rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

            // return the number of rows
            let numberOfRowsInSection = frc.sections![section].numberOfObjects
            return numberOfRowsInSection
        
    }
    
    // Update the cells in the tableView from dataSource array
    override func tableView(_ tableView: UITableView, cellForRowAt IndexPath: IndexPath) -> UITableViewCell {
        
            // Get cell to update
            let cell = tableView.dequeueReusableCell(withIdentifier: "acListCell", for: IndexPath) as! AircraftInfoTableViewCell
        
            // CoreData NSFetchedResults style
            let aircraft = frc.object(at: IndexPath) as! EntAircraft
        
            // Clear image to make sure correct image is retrieved when page scrolls
            cell.imgAircraft?.image = nil

            // Assign values to cell components
            cell.lblRegistration?.text = aircraft.acRegistration
            cell.lblDetails?.text = aircraft.acType! + " - " + aircraft.acSeries!
            cell.lblOperator?.text = aircraft.acOperator
        
            // Set image to camera icon if image is available
            if aircraft.acImageAvailable {
                
                cell.imgAircraft?.image = UIImage(named: "Camera")
                
            }
        
        // Check network connection
        let netStatus = currentReachabilityStatus()
        
        // Check for WiFi connection & User wants images via WiFi only
        if netStatus != .reachableViaWiFi && defaults.bool(forKey: "imageLoadWiFiOnly") { return cell }
        
            // Make call to server if current image is nil and image available for registration
            if aircraft.acImageAvailable
                {
        
                    // Get image asynchronously from server passing in delegate completion handler to function
                        loadImageFromURL(inRegistration: aircraft.acRegistration!, inIndexPath: IndexPath, completionHandler: { (imageFromServer, retIndexPath) in
                        
                            // Get path to current cell
                            let cell2Update: AircraftInfoTableViewCell? = self.tableView?.cellForRow(at: IndexPath) as? AircraftInfoTableViewCell
                            
                            // Test for cell
                            if cell2Update != nil
                                {
                                    cell2Update?.imgAircraft?.image = imageFromServer
                                    cell2Update?.setNeedsLayout()
                                }
                        })
                }
        
            // Return the updated cell
            return cell
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
    
    // MARK: Functions
    


}
