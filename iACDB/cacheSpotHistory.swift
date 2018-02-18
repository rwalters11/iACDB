//
//  cacheSpotHistory.swift
//  iACDB
//
//  Created by Richard Walters on 18/02/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//
// Library of functions to support the download of Spot History data

import UIKit
import CoreData
import CoreLocation

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON

// MARK: Cache Functions
/*
 *
 * Function to synchronise the CoreData Types cache to the TBGweb server
 *
 */
func cacheSpotHistoryFromRemoteDB() {
    
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
    
    _ = populateSpotHistoryCache()
    
}


// MARK: Helper Functions

/*
 *
 *  Function to populate the Types cache from the main DB
 *
 */
func populateSpotHistoryCache() -> Int
{
    // Check network connection
    let netStatus = currentReachabilityStatus()
    if netStatus == .notReachable
    {
        rwPrint(inFunction: #function, inMessage: "Network unavailable")
        return 0
    }
    
    var cacheCount: Int = 0
    
    // Get an array of Spot History from the ACDB server passing in delegate completion handler
    afPopulateSpotHistory(completionHandler: { success, json -> Void in
        
        if (success) {
            
            rwPrint(inFunction: #function, inMessage: "Spot History data returned successfully from async call")
            
            /*
            // Clear the Types cache after download of new data
            _ = entityDeleteAllData(inEntity: "EntTypes")
            
            let moc = getContext()
            
            // Assign returned data to SwiftyJSON object
            let data = JSON(json!)
            
            // Iterate through array of Dictionary's
            for (_, object) in data {
                
                // Create a new Type
                let addTypes = EntTypes(context: moc)
                
                // Get the type information from json
                addTypes.acType = object["Aircraft Type"].stringValue
                
            }
            */
            
            // Save the types added
            do {
                /*
                // Do the save
                try moc.save()
                
                // Set the value of the number of records downloaded
                cacheCount = data.count
                */
                
                rwPrint(inFunction: #function, inMessage: "\(cacheCount) Spot History records saved")
                
            } catch let error as NSError {
                rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
            }
            
        } else
        {
            rwPrint(inFunction: #function, inMessage: "No data returned from async call")
        }
    })
    
    // Return the count of Operators cached to caller
    return cacheCount
}

// MARK: AlamoFire Server Requests

/*
 *
 * Function to get the Spot History from the TBGweb server asynchronously using Alamofire
 *
 */

func afPopulateSpotHistory(completionHandler:  @escaping (Bool, [[String: String]]?) -> ())
{
    
    // Display network activity indicator in status bar
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    // Set destination url & value to send
    let url: String = "https://tbgweb.dyndns.info/iacdb/iosPopulateSpotHistory.php"
    
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
