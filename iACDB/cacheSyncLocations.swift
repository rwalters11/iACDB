//
//  cacheSyncLocations.swift
//  iACDB
//
//  Created by Richard Walters on 06/02/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//
// Library of functions to support the local Cache of Locations

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

// MARK: AlamoFire Server Requests

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

