//
//  iACDBFunctionLibrary.swift
//  iACDB
//
//  Created by Richard Walters on 30/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//

//  Library of functions to support iACDB App

import UIKit
import CoreData
import CoreLocation

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON

/*
 * Function to register user defaults from settings bundle
 * Use in AppDelegate
 */
func registerDefaultsFromSettingsBundle()
{
    let settingsUrl = Bundle.main.url(forResource: "Settings", withExtension: "bundle")!.appendingPathComponent("Root.plist")
    let settingsPlist = NSDictionary(contentsOf:settingsUrl)!
    let preferences = settingsPlist["PreferenceSpecifiers"] as! [NSDictionary]
    
    var defaultsToRegister = Dictionary<String, Any>()
    
    for preference in preferences {
        guard let key = preference["Key"] as? String else {
            NSLog("Key not found")
            continue
        }
        defaultsToRegister[key] = preference["DefaultValue"]
    }
    UserDefaults.standard.register(defaults: defaultsToRegister)
}

/*
 *
 * Function to take a string and remove any whitespace, lowercase or non A-Z or non 0-9 characters
 *
 */
func cleanOCRResult(inResult: String) -> String {
    
    // Remove leading & trailing spaces
    var cleanedText: String = inResult.trim()
    
    // Use our custom string function to remove anything except A-Z, 0-9 & -
    
    var pattern = ""
    
    // Pass 1 - remove any line breaks
    pattern = "[\\n]"
    
    cleanedText.stringByRemovingRegexMatches(pattern: pattern)
    
    rwPrint(inFunction: #function, inMessage: "Pass 1 OCR text: \(cleanedText)")
    
    // Pass 2 - remove everything up to the first A-Z character
    pattern = "^.+?(?=[A-Z])"
    
    cleanedText.stringByRemovingRegexMatches(pattern: pattern)
    
    rwPrint(inFunction: #function, inMessage: "Pass 2 OCR text: \(cleanedText)")
    
    // Pass 3 - Remove everything except A-Z & 0-9 & -
    pattern = "[^A-Z0-9-]+"
    
    cleanedText.stringByRemovingRegexMatches(pattern: pattern)
    
    rwPrint(inFunction: #function, inMessage: "Pass 3 OCR text: \(cleanedText)")
    return cleanedText
}

/*
 *
 * Custom extension to remove characters from a String by applying a regex pattern
 *
 */
extension String {
    mutating func stringByRemovingRegexMatches(pattern: String, replaceWith: String = "") {
        do {
            //let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSMakeRange(0, self.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return
        }
    }
}

/*
 *
 *  Function to get the nearest location to the device's current geo position
 *
 */
func getNearestLocation(inLocation:CLLocation) -> String
{
    var nearestLocation = ""
    var nearestDistance: Double = 999999999           // Set to a high value so that the 1st location gets set
    var locationDistance: CLLocationDistance
    
    // Get the container from the AppDelegate
    let moc = getContext()
    
    let entity = "EntLocations"
    
    // Create Fetch Request
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    
    // Add Sort Descriptor
    let sortDescriptor = NSSortDescriptor(key: "location", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    do {
        // Execute Fetch Request
        let locations = try moc.fetch(fetchRequest) as! [EntLocations]
        
        // Iterate through locations
        for location in locations {
            
            switch location.location! {
                
            // Overfly location has 0 distance so exclude it
            case "Overfly":
                break
                
            default:
                
                // Calculate distance
                let locLatitude: Double = Double(location.latitude)
                let locLongitude: Double = Double(location.longitude)
                
                // Locations with a Latitude of 0 don't have their coordinates set in the DB yet.
                if locLatitude != 0 {
                    
                    // Create CLLocation from coordinates
                    let coordLocation = CLLocation(latitude: locLatitude, longitude: locLongitude)
                    
                    // Calculate the distance
                    locationDistance = inLocation.distance(from: coordLocation)
                    
                    rwPrint(inFunction: #function, inMessage:"Location: \(location.location!) is \(locationDistance) m")
                    
                    // Test location
                    if locationDistance < nearestDistance {
                        
                        nearestDistance = locationDistance
                        nearestLocation = location.location!
                    }
                }
            }
        }
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to fetch current locations")
    }
    
    rwPrint(inFunction: #function, inMessage:"Nearest location: \(nearestLocation)")
    
    return nearestLocation
}

/*
 *
 *  Function to get the current location
 *
 */
func getCurrentLocation() -> String
{
    var currentLocation: String = ""
    
    // Get the context from the AppDelegate
    let moc = getContext()
    
    // Assign the entity (Table)
    let entity = "EntLocations"
    
    // Create a Fetch Request
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    
    // Add predicates
    fetchRequest.predicate = NSPredicate(format: "current == YES")
    
    // Execute Fetch request
    do {
        // Execute Fetch Request
        let fetchedLocations = try moc.fetch(fetchRequest) as! [EntLocations]
        
        if fetchedLocations.count != 0{
            
            let fetchedLocation = fetchedLocations[0]
            
            rwPrint(inFunction: #function, inMessage:"Fetched current location: \(String(describing: fetchedLocation.location)).")
            
            currentLocation = fetchedLocation.location!
        }
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for entity \(entity).")
    }
    
    return currentLocation
    
}

/*
 *
 *  Function to set the current location
 *
 */
func setCurrentLocation(spot: infoSpot)
{
    // Reset the existing current location(s)
    resetCurrentLocations()
    
    // Extract the location from the spot class
    let latestLocation = spot.getLocation()
    
    // Get the context from the AppDelegate
    let moc = getContext()
    
    // Assign the entity (Table)
    let entity = "EntLocations"
    
    // Create a Fetch Request
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    
    // Add predicates
    fetchRequest.predicate = NSPredicate(format: "location = %@", latestLocation!)
    
    // Execute Fetch request
    do {
        // Execute Fetch Request
        let fetchedLocations = try moc.fetch(fetchRequest) as! [EntLocations]
        
        if fetchedLocations.count != 0{
            
            let fetchedLocation = fetchedLocations[0]
            
            rwPrint(inFunction: #function, inMessage:"Fetched location: \(String(describing: fetchedLocation.location)).")
            
            fetchedLocation.current = true
        }
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for entity \(entity).")
    }
    
    do {
        // Save changes
        try moc.save()
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to set current marker for \(String(describing: latestLocation)).")
    }
    
}

/*
 *
 * Function to reset the current Locations markers
 *
 */
func resetCurrentLocations() {
    
    // Get the container from the AppDelegate
    let moc = getContext()
    
    let entity = "EntLocations"
    
    // Create Fetch Request
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    
    // Add Sort Descriptor
    let sortDescriptor = NSSortDescriptor(key: "location", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    do {
        // Execute Fetch Request
        let records = try moc.fetch(fetchRequest) as! [EntLocations]
        
        for record in records {
            
            record.current = false
        }
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to reset current locations - update")
    }
    
    do {
        // Save changes
        try moc.save()
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to reset current locations - save")
    }
}

/*
 *
 * Function to update a spot in Coredata
 *
 */
func updateSpot(inSpot: infoSpot)
{
    // Get the context from the AppDelegate
    let moc = getContext()
    
    // Assign the entity (Table)
    let entity = "EntSpots"
    
    // Create a Fetch Request
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    
    // Add predicates
    fetchRequest.predicate = NSPredicate(format: "registration = %@", inSpot.getRegistration()! )
    
    // Get the spot to update
    do {
        // Execute Fetch Request
        let fetchedSpots = try moc.fetch(fetchRequest) as! [EntSpots]
        
        if fetchedSpots.count != 0{
            
            // Get the spot out of the array
            let fetchedSpot = fetchedSpots[0]
            
            rwPrint(inFunction: #function, inMessage:"Fetched spot for: \(String(describing: fetchedSpot.registration )).")
            
            // Update the spot status
            fetchedSpot.status = Int16(inSpot.getStatus().rawValue)
            
            // Update the Spot notes
            fetchedSpot.notes = inSpot.getNotes()
        }
        
    } catch {
        rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for entity \(entity).")
    }
    
    // Update the values
    do {
        // Do the update
        try moc.save()
        
        rwPrint(inFunction: #function, inMessage: "\(String(describing: inSpot.getRegistration())) updated in CoreData")
        
        
    } catch let error as NSError {
        rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
    }
}

/*
 *
 * Function to save spot details to CoreData
 *
 */
func saveSpot(spot: infoSpot) {
    
    // Get the container from the AppDelegate
    let moc = getContext()
    
    // Create a new spot
    let newSpot = EntSpots(context: moc)
    
    // Set the new spot values
    newSpot.registration = spot.getRegistration()               // Registration
    newSpot.location=spot.getLocation()                         // Location
    newSpot.status=Int16(spot.getStatus().rawValue)             // Status as it's enum integer value
    newSpot.date=Date() as NSDate?                              // Date/Time
    newSpot.sectionDate=Date().toiACDBDateString()              // Date in dd-mm-yyyy string format for section headers
    newSpot.notes = spot.getNotes()                             // Notes
    
    // Save the values
    do {
        // Do the save
        try moc.save()
        
        rwPrint(inFunction: #function, inMessage: "\(String(describing: newSpot.registration)) saved to CoreData")
        
        // Set the current location if the spot save is completed
        setCurrentLocation(spot: spot)
        
    } catch let error as NSError {
        rwPrint(inFunction: #function, inMessage:"Could not save. \(error), \(error.userInfo)")
    }
}






