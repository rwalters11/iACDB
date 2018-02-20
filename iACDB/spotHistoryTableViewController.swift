//
//  spotHistoryTableViewController.swift
//  iACDB
//
//  Created by Richard Walters on 15/02/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//

import UIKit

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON

class spotHistoryTableViewController: UITableViewController {
    
    // Values passed in by segue
    var inRegistration: String!
    
    var arrayHistory = [spotHistory]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Set title
        self.navigationItem.title = inRegistration
        
        // Get the history data from the ACDB server
        getSpotHistoryFromRemoteDB(inRegistration: inRegistration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source & delegate functions
    
    // Update the section titles
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Spot History"
    }
    
    // Customise the section titles
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            
            // Create the custom header cell frame
            let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 20))
            returnedView.backgroundColor = .lightGray
            
            // Create the text label
            let label = UILabel(frame: CGRect(x: 10, y: 3, width: view.frame.size.width, height: 20))
            label.text = "Spot History"
            label.textColor = .white
            label.textAlignment = .center
            
            // Add the label to the view
            returnedView.addSubview(label)
            
            return returnedView
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return arrayHistory.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "spotHistoryCell", for: indexPath) as! spotHistoryTableViewCell

        cell.lblLocation.text = arrayHistory[indexPath.row].hLocation
        cell.lblDate.text = arrayHistory[indexPath.row].hLatest
        cell.lblCount.text = "(" + arrayHistory[indexPath.row].hCount + ")"

        return cell
    }
    
    // MARK: Data Retrieval Functions
    /*
     *
     * Function to control the fetching of Spot history from the TBGweb server
     *
     */
    func getSpotHistoryFromRemoteDB(inRegistration: String) {
        
        // Get user defaults
        let defaults = UserDefaults.standard
        
        //***********   Network connectivity checking
        
        // Check network connection
        let netStatus = currentReachabilityStatus()
        if netStatus == .notReachable
        {
            rwPrint(inFunction: #function, inMessage: "Network unavailable")
            return
        }
        
        // Check for WiFi connection
        if netStatus != .reachableViaWiFi
        {
            // If user wants cache updates via Wifi only then exit
            if defaults.bool(forKey: "cacheLoadWiFiOnly") {
                
                rwPrint(inFunction: #function, inMessage: "Spot History download aborted - WiFi connection required")
                return
            }
            
        }
        
        populateSpotHistoryTable(inRegistration: inRegistration)
    }
    
    
    // MARK: Helper Functions
    
    /*
     *
     *  Function to populate the Spot History tableView from the main DB
     *
     */
    func populateSpotHistoryTable(inRegistration: String)
    {
        // Check network connection
        let netStatus = currentReachabilityStatus()
        if netStatus == .notReachable
        {
            rwPrint(inFunction: #function, inMessage: "Network unavailable")
            return
        }
        
        // Get an array of Spot History from the ACDB server passing in delegate completion handler
        afPopulateSpotHistory(inRegistration: inRegistration, completionHandler: { success, json -> Void in
            
            if (success) {
                
                rwPrint(inFunction: #function, inMessage: "Spot History JSON data returned successfully from async call")
                 
                 // Assign returned data to SwiftyJSON object
                 let data = JSON(json!)
                
                 // Iterate through array of Dictionary's
                 for (_, object) in data {
                 
                 // Create a new Spot History item
                 let sho = spotHistory(json: object)
                 
                    self.arrayHistory.append(sho)
                 }
                    rwPrint(inFunction: #function, inMessage: "\(self.arrayHistory.count) spot history records retrieved")
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            } else
            {
                rwPrint(inFunction: #function, inMessage: "No data returned from async call")
            }
        })
        
        return
    }
    
    // MARK: AlamoFire Server Requests
    
    /*
     *
     * Function to get the Spot History from the TBGweb server asynchronously using Alamofire
     *
     */
    
    func afPopulateSpotHistory(inRegistration: String, completionHandler:  @escaping (Bool, [[String: String]]?) -> ())
    {
        // Encode registration for passing to server
        let uriRegistration = inRegistration.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        // Display network activity indicator in status bar
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Set destination url & value to send
        let url: String = "https://tbgweb.dyndns.info/iacdb/iosPopulateSpotHistory.php?registration=" + uriRegistration!
        
        // Do asynchronous call to server using Alamofire library
        Alamofire.request(url, method: .post)
            .validate()
            .responseJSON { response in
                
                // check for errors
                guard response.result.error == nil else {
                    
                    // got an error in getting the data, need to handle it
                    rwPrint(inFunction: #function, inMessage: "error calling POST on Spot History data request")
                    rwPrint(inFunction: #function, inMessage: "Error: \(String(describing: response.result.error))")
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    return completionHandler(false, nil)
                }
                
                // make sure we have got valid JSON as an array of key/value pairs of strings
                guard let json = response.result.value as? [[String: String]]! else {
                    
                    rwPrint(inFunction: #function, inMessage: "Didn't get valid JSON from server")
                    rwPrint(inFunction: #function, inMessage: "Error: \(String(describing: response.result.error))")
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    return completionHandler(false, nil)
                }
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return completionHandler(true, json)
        }
    }
}

// Custom class to hold info on an individual aircraft spot history
class spotHistory {
    
    // MARK: Properties
    
    var hLocation:        String                    // Location
    var hCount:           String                    // Number of times seen at Location
    var hLatest:          String                    // Latest Date for Location
    
    // MARK: Initialisation
    
    // Constructor - All values
    init(inLocation: String, inCount: String, inLatest: String ){

        self.hLocation = inLocation
        self.hCount = inCount
        self.hLatest = inLatest
    }
    
    // Constructor - From JSON object
    init(json:JSON){
        
        self.hLocation = json["Location"].stringValue
        self.hLatest = json["Latest"].stringValue
        self.hCount = json["Count"].stringValue
    }
}

