//
//  cacheSyncNewAircraft.swift
//  iACDB
//
//  Created by Richard Walters on 11/02/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//
// Library of functions to support the local Cache of New Aircraft

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
 * Function to synchronise the CoreData Operators cache to the TBGweb server
 *
 */
func syncNewAircraft2RemoteDB() {
    
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
            
            rwPrint(inFunction: #function, inMessage: "New Aircraft sync aborted - WiFi connection required")
            return
        }
        
    }
    
    //**********   Get cache count from CoreData
    
    // Get the container from the AppDelegate
    let moc = getContext()
    
    // Create a Fetch Request
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntNewAircraft")
    
    // Execute Fetch request
    do {
        // Execute Fetch Request
        let fetchedNewAircraft = try moc.fetch(fetchRequest) as! [EntNewAircraft]
        
        // Get the count of the cached New Aircraft
        cachedAircraftCount = fetchedNewAircraft.count
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for New Aircraft.")
    }
    
    //**********   Get count of New Aircraft from remote DB
    
    // Display network activity indicator in status bar
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    // Set destination url & value to send
    let url: String = "https://tbgweb.dyndns.info/iacdb/iosNewAircraftCount.php"
    
    // Do asynchronous call to server using Alamofire library
    Alamofire.request(url, method: .get)
        .validate()
        .responseJSON { response in
            //.responseString { response in
            
            // check for errors
            guard response.result.error == nil else {
                
                // got an error in getting the data, need to handle it
                rwPrint(inFunction: #function, inMessage: "error calling POST on New Aircraft count request")
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
            
            //**********   Compare cache to remote DB
            if cachedAircraftCount != remoteAircraftCount
            //if true
            {
                //**********   Sync the cache by downloading and overwriting
                // Populate the New Aircraft cache from the TBGweb server
                _ = populateNewAircraftCache(inLocalCacheCount: cachedAircraftCount)
                
                rwPrint(inFunction: #function, inMessage: "New Aircraft sync complete")
            }else{
                rwPrint(inFunction: #function, inMessage: "New Aircraft in sync")
            }
    }
}

// MARK: Helper Functions

/*
 *
 *  Function to populate the Operators cache from the main DB
 *
 */
func populateNewAircraftCache(inLocalCacheCount: Int) -> Int
{
    // Get user defaults
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
    
    // Get an array of valid New Aircraft from the ACDB server passing in delegate completion handler
    afPopulateNewAircraft(completionHandler: { success, json -> Void in
        
        if (success) {
            
            rwPrint(inFunction: #function, inMessage: "New Aircraft data returned successfully from async call")
            
            // Clear the Locations cache after download of new data
            _ = entityDeleteAllData(inEntity: "EntNewAircraft")
            
            let moc = getContext()
            
            // Assign returned data to SwiftyJSON object
            let data = JSON(json!)
            
            // Initialise count of returned New Aircraft with a nil value - Bug Fix 11/02/2018
            //var nilCountInJSON = 0
            
            // Iterate through array of Dictionary's
            for (_, object) in data {
                
                // Create a New Aircraft entry
                let addNewAircraft = EntNewAircraft(context: moc)
                
                // Get the New Aircraft information from json
                addNewAircraft.registration = object["Registration"].stringValue
                
                addNewAircraft.count = Int16(object["Count"].stringValue)!
            }
            
            // Save the locations added
            do {
                // Do the save
                try moc.save()
                
                // Set the value of the number of records downloaded
                cacheCount = data.count
                
                rwPrint(inFunction: #function, inMessage: "\(cacheCount) New Aircraft saved to CoreData")
                
            } catch let error as NSError {
                rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
            }
            
        } else
        {
            rwPrint(inFunction: #function, inMessage: "No data returned from async call")
        }
    })
    
    // Return the count of New Aircraft cached to caller
    return cacheCount
}

// MARK: AlamoFire Server Requests

/*
 *
 * Function to get the New Aircraft info from the TBGweb server asynchronously using Alamofire
 *
 */

func afPopulateNewAircraft(completionHandler:  @escaping (Bool, [[String: String]]?) -> ())
{
    
    // Display network activity indicator in status bar
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    // Set destination url & value to send
    let url: String = "https://tbgweb.dyndns.info/iacdb/iosLoadNewAircraftCache.php"
    
    // Do asynchronous call to server using Alamofire library
    Alamofire.request(url, method: .post)
        .validate()
        .responseJSON { response in
            
            // check for errors
            guard response.result.error == nil else {
                
                // got an error in getting the data, need to handle it
                rwPrint(inFunction: #function, inMessage: "error calling POST on New Aircraft data request")
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

