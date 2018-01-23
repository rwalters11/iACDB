//
//  iACDBCacheSync.swift
//  iACDB
//
//  Created by Richard Walters on 20/01/2017.
//  Copyright © 2017 Richard Walters. All rights reserved.
//

// Library of functions to support the local Cache of Locations & Aircraft

import UIKit
import CoreData
import CoreLocation

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON

// MARK: Cache Sync Functions

/*
 *
 * Function to synchronise the CoreData Aircraft cache to the TBGweb server
 *
 */
func syncAircraft2RemoteDB(inController: spotListTableViewController) {
    
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
            {
                
                //**********   Sync the cache by downloading and overwriting
                // Populate the Locations cache from the TBGweb server
                _ = populateAircraftCache(inLocalCacheCount: cachedAircraftCount, inController: inController)
                
                rwPrint(inFunction: #function, inMessage: "Aircraft sync complete")
            }else{
                rwPrint(inFunction: #function, inMessage: "Aircraft in sync")
            }
    }
}

/*
 *
 * Function to synchronise the CoreData Locations cache to the TBGweb server
 *
 */
func syncLocations2RemoteDB() {
    
    var cachedLocationsCount: Int = 0
    var remoteLocationsCount: Int = 0
    
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
            
            rwPrint(inFunction: #function, inMessage: "Locations sync aborted - WiFi connection required")
            return
        }
        
    }
    
    //**********   Get cache count from CoreData
    
    // Get the container from the AppDelegate
    let moc = getContext()
    
    // Create a Fetch Request
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntLocations")
    
    // Execute Fetch request
    do {
        // Execute Fetch Request
        let fetchedLocations = try moc.fetch(fetchRequest) as! [EntLocations]
        
        // Get the count of the cached Locations
        cachedLocationsCount = fetchedLocations.count
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for Locations.")
    }
    
    //**********   Get count of Locations from remote DB
    
    // Display network activity indicator in status bar
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    // Set destination url & value to send
    let url: String = "https://tbgweb.dyndns.info/iacdb/iosLocationCount.php"
    
    // Do asynchronous call to server using Alamofire library
    Alamofire.request(url, method: .post)
        .validate()
        .responseJSON { response in
            
            // check for errors
            guard response.result.error == nil else {
                
                // got an error in getting the data, need to handle it
                rwPrint(inFunction: #function, inMessage: "error calling POST on Locations data request")
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
            
            remoteLocationsCount = json
            
            //**********   Compare cache to remote DB
            if cachedLocationsCount != remoteLocationsCount
            {
                
                //**********   Sync the cache by downloading and overwriting
                // Populate the Locations cache from the TBGweb server
                _ = populateLocationsCache(inLocalCacheCount: cachedLocationsCount)
                
                rwPrint(inFunction: #function, inMessage: "Locations sync complete")
            }else{
                rwPrint(inFunction: #function, inMessage: "Locations in sync")
            }
    }
}

// MARK: Helper Functions

/*
 *
 *  Function to populate the Locations cache from the main DB
 *
 */
func populateLocationsCache(inLocalCacheCount: Int) -> Int
{
    // Get user defaults
    //let defaults = tbgUserDefaults.sharedInstance
    let defaults = UserDefaults.standard
    
    // Bug fix: 20/01/2017 - test for local cache count = 0 added.
    // Test for 1st run of App or data deleted ( count = 0) and user preference regarding load/sync on startup
    if inLocalCacheCount > 0 && defaults.bool(forKey: "loadLocationsCacheOnStartup") == false { return 0 }
    
    // Check network connection
    let netStatus = currentReachabilityStatus()
    if netStatus == .notReachable
    {
        rwPrint(inFunction: #function, inMessage: "Network unavailable")
        return 0
    }
    
    var cacheCount: Int = 0
    
    // Get an array of valid locations from the ACDB server passing in delegate completion handler
    afPopulateLocations(completionHandler: { success, json -> Void in
        
        if (success) {
            
            rwPrint(inFunction: #function, inMessage: "Locations data returned successfully from async call")
            
            // Clear the Locations cache after download of new data
            _ = entityDeleteAllData(inEntity: "EntLocations")
            
            let moc = getContext()
            
            // Assign returned data to SwiftyJSON object
            let data = JSON(json!)
            
            // Iterate through array of Dictionary's
            for (_, object) in data {
                
                // Create a new Location
                let addLocation = EntLocations(context: moc)
                
                // Get the location information from json
                addLocation.location = object["Location"].stringValue
                
                addLocation.latitude = Float(object["Latitude"].stringValue)!
                addLocation.longitude = Float(object["Longitude"].stringValue)!
                
                addLocation.iOS = Int16(object["iOS"].stringValue)!
                
            }
            
            // Save the locations added
            do {
                // Do the save
                try moc.save()
                
                // Set the value of the number of records downloaded
                cacheCount = data.count
                
                rwPrint(inFunction: #function, inMessage: "\(cacheCount) locations saved to CoreData")
                
            } catch let error as NSError {
                rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
            }
            
        } else
        {
            rwPrint(inFunction: #function, inMessage: "No data returned from async call")
        }
    })
    
    // Return the count of Locations cached to caller
    return cacheCount
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
            
            let moc = getContext()
            
            // Assign returned data to SwiftyJSON object
            let data = JSON(json!)
            
            
            
            // Iterate through array of Dictionary objects
            for (_, object) in data {
                
                //recordCounter += 1
                
                // Create a new spot
                let addAircraft = EntAircraft(context: moc)
                
                // Get the location information from json
                addAircraft.acRegistration = object["Registration"].stringValue
                
                //print(String(recordCounter))
                
                addAircraft.acType = object["Type"].stringValue
                addAircraft.acSeries = object["Series"].stringValue
                
                addAircraft.acOperator = object["Operator"].stringValue
                
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
                try moc.save()
                
                // Set the value of the number of records downloaded
                cacheCount = data.count
                
                rwPrint(inFunction: #function, inMessage: "\(cacheCount) aircraft saved to CoreData")
                
                
                
                // Dismiss the loading screen once complete
                inController?.removeLoadingScreen()
                
                // Reload the tableview after the cache is loaded to correctly display aircraft details
                inController?.tableView.reloadData()
                
            } catch let error as NSError {
                rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
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
            
            aircraftDetails.acType = fetchedAircraft.acType!
            aircraftDetails.acSeries = fetchedAircraft.acSeries!
            aircraftDetails.acOperator = fetchedAircraft.acOperator!
        }
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for entity \(entity).")
    }
    
    return aircraftDetails
    
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

/*
 *
 * Function to get the Locations info from the TBGweb server asynchronously using Alamofire
 *
 */

func afPopulateLocations(completionHandler:  @escaping (Bool, [[String: String]]?) -> ())
{
    
    // Display network activity indicator in status bar
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    // Set destination url & value to send
    let url: String = "https://tbgweb.dyndns.info/iacdb/iosLoadLocations.php"
    
    // Do asynchronous call to server using Alamofire library
    Alamofire.request(url, method: .post)
        .validate()
        .responseJSON { response in
            
            // check for errors
            guard response.result.error == nil else {
                
                // got an error in getting the data, need to handle it
                rwPrint(inFunction: #function, inMessage: "error calling POST on Locations data request")
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
