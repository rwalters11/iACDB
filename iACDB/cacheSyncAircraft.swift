//
//  cacheSyncAircraft.swift
//  iACDB
//
//  Created by Richard Walters on 06/02/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//
// Library of functions to support the local Cache of Aircraft

import UIKit
import CoreData
import CoreLocation

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON

// Structures to hold GET/POST field names for server calls
struct MainDataTableFields
{
    let mdtRecordNum    : String = "RecordNumber"
    let mdtRegistration : String = "Registration"
    let mdtType         : String = "Type"
    let mdtSeries       : String = "Series"
    let mdtOperator     : String = "Operator"
    let mdtDeliveryDate : String = "DeliveryDate"
    let mdtName         : String = "AircraftName"
    let mdtConstructor  : String = "ConstructorsNumber"
    let mdtFuselage     : String = "FuselageNumber"
    let mdtFleetNum     : String = "FleetNumber"
    let mdtSoldAs       : String = "SoldAs"
    let mdtModeS        : String = "ModeS"
    let mdtRemarks      : String = "Remarks"
    let mdtImage        : String = "image"
    let mdtPrevReg1     : String = "PReg1"
    let mdtPrevReg2     : String = "PReg2"
    let mdtPrevReg3     : String = "PReg3"
    let mdtPrevReg4     : String = "PReg4"
    let mdtPrevReg5     : String = "PReg5"
    let mdtPrevReg6     : String = "PReg6"
    let mdtPrevReg7     : String = "PReg7"
    let mdtPrevReg8     : String = "PReg8"
}

struct HistoryTableFields
{
    let htRegistration  : String = "registration"
    let htLocation      : String = "location"
    let htDate          : String = "date"
    let htSeenBy        : String = "seenby"
    
}

enum NewAircraftReturnValues: String
{
    case new = "new_success"
    case newFailed = "new_failed"
    case duplicate = "duplicate"
    case updated = "update_success"
    case updateFailed = "update_failed"
}

// MARK: Cache Sync Functions

/*
 *
 * Function to synchronise the CoreData Aircraft cache to the TBGweb server
 *
 */
func syncAircraft2RemoteDB(inController: spotListTableViewController) {
    
    // Ensure function runs only once
    struct Temp { static var hasSynched = false }
    if Temp.hasSynched == false {
        
        Temp.hasSynched = true
        
    } else {
        
        return
    }
    
    var cachedAircraftCount: Int = 0
    var remoteAircraftCount: Int = 0
    
    // Get user defaults
    //let defaults = tbgUserDefaults.sharedInstance
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
            //if defaults.cacheLoadWifiOnly == true {
            
            rwPrint(inFunction: #function, inMessage: "Aircraft sync aborted - WiFi connection required")
            return
        }
        
    }
    
    //**********   Get cache count from CoreData
    
    // Get the context from the AppDelegate
    let moc = getContext()
    
    // Create a Fetch Request
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntAircraft")
    
    // Execute Fetch request
    do {
        // Execute Fetch Request
        let fetchedAircraft = try moc.fetch(fetchRequest) as! [EntAircraft]
        
        // Get the count of the cached Aircraft
        cachedAircraftCount = fetchedAircraft.count
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for Aircraft.")
    }
    
    //**********   Get count of Aircraft from remote DB
    
    // Display network activity indicator in status bar
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    // Set destination url & value to send
    let url: String = "https://tbgweb.dyndns.info/iacdb/iosAircraftCount.php"
    
    // Do asynchronous call to server using Alamofire library
    Alamofire.request(url, method: .post)
        .validate()
        .responseJSON { response in
            
            // check for errors
            guard response.result.error == nil else {
                
                // got an error in getting the data, need to handle it
                rwPrint(inFunction: #function, inMessage: "error calling POST on Aircraft data request")
                rwPrint(inFunction: #function, inMessage: "Error: \(String(describing: response.result.error))")
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return
            }
            
            // make sure we have got valid JSON as an array of key/value pairs of strings
            guard let json = response.result.value as? Int! else {
                
                rwPrint(inFunction: #function, inMessage: "Didn't get valid JSON from server")
                rwPrint(inFunction: #function, inMessage: "Error: \(String(describing: response.result.error))")
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            remoteAircraftCount = json
            
            //**********   Compare cache to remote DB and populate the cache if they differ or the user settings say do a refresh on startup
            if cachedAircraftCount != remoteAircraftCount
            //if true
            {
                
                //**********   Sync the cache by downloading and overwriting
                // Populate the Aircraft cache from the TBGweb server
                _ = populateAircraftCache(inLocalCacheCount: cachedAircraftCount, inController: inController)
                
                
            }else{
                rwPrint(inFunction: #function, inMessage: "Aircraft in sync")
            }
    }
}

/*
 *
 *  Function to populate the Aircraft cache from the main DB
 *
 */
func populateAircraftCache(inLocalCacheCount: Int, inController: spotListTableViewController?)
{
    // Get user defaults
    //let defaults = tbgUserDefaults.sharedInstance
    let defaults = UserDefaults.standard
    
    // Bug fix: 20/01/2017 - test for local cache count =0 added.
    // Test for 1st run of App or data deleted ( count = 0) and user preference regarding load/sync on startup
    if inLocalCacheCount > 0 && defaults.bool(forKey: "loadAircraftCacheOnStartup") == false { return }
    
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
        if defaults.bool(forKey: "cacheLoadWifiOnly") { return }
        
        // Ask user if they want to wait until they are connected to WiFi if aircraft cache is empty as it is a big download
        
        let message = "Do you want to wait until you are connected to WiFi before running this App for the first time"
        
        let alertController = UIAlertController(title: "iACDB", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        // Create the actions
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default) {
            UIAlertAction in
            
            populateAircraftCacheStage2(inController: inController!)
            
        }
        
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
            
        }
        
        // Add the actions
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        // Test for nil controller
        
        if let _ = inController {
            
            // Show the alert
            inController?.present(alertController, animated: true, completion: nil)
        }
        
    }else{
        
        populateAircraftCacheStage2(inController: inController)
    }
    
}

func populateAircraftCacheStage2(inController: spotListTableViewController?) {
    
    if let _ = inController {
        
        inController?.setLoadingScreen()
    }
    
    var cacheCount: Int = 0
    
    // Get aircraft information from the remote DB
    
    // Get an array of valid aircraft from the ACDB server passing in delegate completion handler
    afPopulateAircraftCache(completionHandler: { success, json -> Void in
        
        if (success) {
            
            //var recordCounter: Int = 0
            
            rwPrint(inFunction: #function, inMessage: "Aircraft cache data returned successfully from async call")
            
            // Clear the Locations cache after download of new data
            _ = entityDeleteAllData(inEntity: "EntAircraft")
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            //let moc = getContext()
            
            // Assign returned data to SwiftyJSON object
            let data = JSON(json!)
            
            // Perform lengthy data operation on background thread
            let container = appDelegate.persistentContainer
            container.performBackgroundTask() { (context) in
            
                // Iterate through array of Dictionary objects
                for (_, object) in data {
                    
                    // Create a new aircraft obj
                    let addAircraft = EntAircraft(context: context)
                    
                    // Get the registration information from json
                    addAircraft.acRegistration = object["Registration"].stringValue
                    
                    //print(String(recordCounter))
                    
                    addAircraft.acType = object["Type"].stringValue
                    addAircraft.acSeries = object["Series"].stringValue
                    
                    addAircraft.acOperator = object["Operator"].stringValue
                    
                    addAircraft.acConstructor = object["Constructors Number"].stringValue
                    addAircraft.acFuselage = object["Fuselage Number"].stringValue
                    addAircraft.acDelivery = object["Delivery Date"].stringValue
                    
                    addAircraft.acModeS = object["ModeS"].stringValue
                    
                    addAircraft.dbRecordNum = object["RecordNumber"].int16Value
                    
                    let acImageMarkerInt: Int = Int(object["Image"].stringValue)!
                    
                    // Convert mySQL value of 0 or 1 to true/false
                    var acImageMarker: Bool
                    
                    // Set image marker
                    if acImageMarkerInt == 0
                    {
                        acImageMarker = false
                    }else{
                        acImageMarker = true
                    }
                    // Set the Image available marker
                    addAircraft.acImageAvailable = acImageMarker
                }
                
                // Save the aircraft added
                do {
                    // Do the save
                    try context.save()
                    
                    // Set the value of the number of records downloaded
                    cacheCount = data.count
                    
                    rwPrint(inFunction: #function, inMessage: "\(cacheCount) aircraft saved to CoreData")
                    rwPrint(inFunction: #function, inMessage: "Aircraft sync complete")
                    
                    // Dismiss the loading screen once complete on main thread
                    DispatchQueue.main.async { inController?.removeLoadingScreen() }
                    
                    // Reload the tableview after the cache is loaded to correctly display aircraft details
                    DispatchQueue.main.async { inController?.tableView.reloadData() }
                    
                } catch let error as NSError {
                    rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
                }
            }
        } else
        {
            rwPrint(inFunction: #function, inMessage: "No data returned from async call")
        }
    })
    
    
}

/*
 *
 * Function to return the details of an aircraft from the cache given a registration
 *
 */
func getAircraftDetailsFromCache(inRegistration: String) -> infoAircraft {
    
    let aircraftDetails = infoAircraft(inRegistration: inRegistration)
    
    // Get the context from the AppDelegate
    let moc = getContext()
    
    // Assign the entity (Table)
    let entity = "EntAircraft"
    
    // Create a Fetch Request
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    
    // Add predicates
    fetchRequest.predicate = NSPredicate(format: "acRegistration = %@", inRegistration)
    
    // Execute Fetch request
    do {
        // Execute Fetch Request
        let fetchedAircraft = try moc.fetch(fetchRequest) as! [EntAircraft]
        
        if fetchedAircraft.count != 0{
            
            let fetchedAircraft = fetchedAircraft[0]
            
            rwPrint(inFunction: #function, inMessage:"Fetched aircraft: \(String(describing: fetchedAircraft.acRegistration)).")
            
            aircraftDetails?.acType = fetchedAircraft.acType!
            aircraftDetails?.acSeries = fetchedAircraft.acSeries!
            aircraftDetails?.acOperator = fetchedAircraft.acOperator!
            aircraftDetails?.acConstructor = fetchedAircraft.acConstructor!
            aircraftDetails?.acFuselage = fetchedAircraft.acFuselage!
            aircraftDetails?.acModeS = fetchedAircraft.acModeS!
            aircraftDetails?.acDelivery = fetchedAircraft.acDelivery!
            aircraftDetails?.recordNum = fetchedAircraft.dbRecordNum
            aircraftDetails?.acImageAvailable = fetchedAircraft.acImageAvailable
        }
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for entity \(entity).")
    }
    
    return aircraftDetails!
    
}

// MARK: AlamoFire Server Requests

/*
 *
 * Function to get the Aircraft cache data from the TBGweb server asynchronously using Alamofire
 *
 */

func afPopulateAircraftCache(completionHandler:  @escaping (Bool, [[String: String]]?) -> ())
{
    
    // Display network activity indicator in status bar
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    // Set destination url & value to send
    let url: String = "https://tbgweb.dyndns.info/iacdb/iosLoadAircraftCache.php"
    
    // Do asynchronous call to server using Alamofire library
    Alamofire.request(url, method: .post)
        .validate()
        .responseJSON { response in
            
            // check for errors
            guard response.result.error == nil else {
                
                // got an error in getting the data, need to handle it
                rwPrint(inFunction: #function, inMessage: "error calling POST on Aircraft data request")
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

// MARK: - Adding New Aircraft Record Functions

// Function to handle adding Aircraft Record to CoreData & Server DB
func addAircraft(inAircraft: infoAircraft) -> Bool
{
    var retValue: Bool = false
    
    // Stage 1 - Add record to Server
    retValue = addAircraft2RemoteDB(inAircraft: inAircraft)
    
    
    // Stage 2 - Add record to CoreData if success adding to server DB
    if retValue{
        
        retValue = addAircraftRecord2CoreData(inAircraft: inAircraft)
        
    }
    
    return retValue
}

// Function to add New Aircraft 2 Server DB
func addAircraft2RemoteDB(inAircraft: infoAircraft) -> Bool
{
    //***********   Network connectivity checking
    
    // Check network connection
    let netStatus = currentReachabilityStatus()
    if netStatus == .notReachable
    {
        rwPrint(inFunction: #function, inMessage: "Network unavailable")
        showNoNetworkAlert()
        return false
    }
    
    //**********   Add New Aircraft 2 remote DB
    
    // Display network activity indicator in status bar
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    let parameters = inAircraft.getURLParameterString()
    
    // Set destination url & value to send
    let url: String = "https://tbgweb.dyndns.info/iacdb/iosSubmitAircraftData.php" + parameters
    
    // ****** For Testing (adds record to test DB)
    //url += "&test=true"
    
    // Do asynchronous call to server using Alamofire library
    Alamofire.request(url, method: .get)
        .validate()
        .responseJSON { response in
            //.responseString { response in
            
            // check for errors
            guard response.result.error == nil else {
                
                // got an error in getting the data, need to handle it
                rwPrint(inFunction: #function, inMessage: "error calling POST on Aircraft add request")
                rwPrint(inFunction: #function, inMessage: "Error: \(String(describing: response.result.error))")
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return
            }
            
            // make sure we have got valid JSON as an array of key/value pairs of strings
            guard let json = response.result.value as? Dictionary<String, Any> else {
                
                rwPrint(inFunction: #function, inMessage: "Didn't get valid JSON from server")
                rwPrint(inFunction: #function, inMessage: "Error: \(String(describing: response.result.error))")
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            // Assign returned data to SwiftyJSON object
            let data = JSON(json)
            
            let status = data["status"].stringValue
            let eStatus = NewAircraftReturnValues(rawValue: status)
            
            switch eStatus {
                
            case .new?:
                rwPrint(inFunction: #function, inMessage: "Record #\(status) New Aircraft added to server")
                
            case .newFailed?:
                rwPrint(inFunction: #function, inMessage: "New Aircraft server add - failed")
                showAlert(inTitle: "Failed", inMessage: "Aircraft not uploaded\n\nServer error")
                
            case .duplicate?:
                rwPrint(inFunction: #function, inMessage: "New Aircraft server add - duplicate")
                showAlert(inTitle: "Duplicate", inMessage: "Aircraft not uploaded\n\nAlready exists")
                
            default:
                break
            }
    }
    
    return true
}

// Function to add new Aircraft to EntAircraft in CoreData
func addAircraftRecord2CoreData(inAircraft: infoAircraft) -> Bool
{
    // Default return value
    var retValue: Bool = false
    
    let moc = getContext()
        
        // Create a new aircraft obj
        let addAircraft = EntAircraft(context: moc)
        
        // Get the aircraft information
        addAircraft.acRegistration = inAircraft.acRegistration
        
        addAircraft.acType = inAircraft.acType
        addAircraft.acSeries = inAircraft.acSeries
        addAircraft.acOperator = inAircraft.acOperator
        addAircraft.acConstructor = inAircraft.acConstructor
        addAircraft.acFuselage = inAircraft.acFuselage
        addAircraft.acDelivery = inAircraft.acDelivery
        addAircraft.acModeS = inAircraft.acModeS
        
        addAircraft.dbRecordNum = inAircraft.recordNum
        
        addAircraft.acImageAvailable = inAircraft.acImageAvailable
    
    // Save the aircraft added
    do {
        // Do the save
        try moc.save()
        
        rwPrint(inFunction: #function, inMessage: "New aircraft saved to CoreData")
        
        retValue = true
        
    } catch let error as NSError {
        rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
    }
    
    return retValue
}

