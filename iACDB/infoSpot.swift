//
//  infoSpot.swift
//  iACDB
//
//  Created by Richard Walters on 13/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//

import UIKit

// 3rd Party Librarys
import Alamofire
import SwiftyJSON

// Enum for spot status - modified with "objc to allow use with CoreData
enum spotStatus: Int {
    case Placeholder    = 0
    case Waiting        = 1
    case Uploaded       = 2
    case UploadFailed   = 3
    case Updating       = 4
    case Unknown        = -1
}

// Custom encapsulated class to hold info on an aircraft spotted

class infoSpot {
    
    // MARK: Properties
    
    private var acRegistration:     String?                     // Registration
    private var spLocation:         String?                     // Location
    private var spStatus:           spotStatus                  // Status of upload to server
    private var spDateTime:         Date                        // Date and time at moment of instaniation
    private var spName:             String?                     // Name
    private var spNotes:            String?                     // Notes
    
    // MARK: Initialisation
    
    // Constructor - Registration only
    init(inRegistration: String, inLocation: String?) {
        
        self.acRegistration = inRegistration        // Assign registration
        
        self.spLocation = inLocation
        self.spStatus = .Waiting
        self.spDateTime = Date()                  // Now
        self.spName = "Jason"
        self.spNotes = ""
        
        upload2Server()
    
    }
    
    // Constructor - Placeholder
    init(inStatus: spotStatus) {
        
        self.acRegistration = nil
        self.spLocation = nil
        self.spDateTime = Date()                  // Now
        self.spName = "Jason"
        self.spNotes = ""
        self.spStatus = inStatus
    }
    
    // Get registration
    public func getRegistration() -> String? { return acRegistration! }
    
    // Get location
    public func getLocation() -> String? { return spLocation! }
    
    // Get spot status
    public func getStatus() -> spotStatus { return spStatus }
    
    // Get notes
    public func getNotes() -> String? { return spNotes }
    
    // Set spot status
    public func setStatus(inStatus: spotStatus)
    {
        // Assign status
        spStatus = inStatus
        
        // Update CoreData
        updateSpot(inSpot: self)
        
        // Take any actions
        switch inStatus {
            
            case .Waiting:                                      // Setting the status to waiting triggers the upload to the TBG server
                upload2Server()
            
            default:
                break
        }
        
    }
    
    // Set spot registration
    public func setRegistration(inRegistration: String)
    {
        acRegistration = inRegistration
    }
    
    // Set location
    public func setLocation(inLocation: String)
    {
        spLocation = inLocation
    }
    
    // Set User Name
    public func setName(inName: String)
    {
        spName = inName
    }
    
    // Set notes
    public func setNotes(inNotes: String)
    {
        spNotes = inNotes
    }

    // Function to request upload spot to server
    public func upload2Server()
    {
        self.setStatus(inStatus: .Updating)
        
        // Upload the spot to the server passing in delegate completion handler to function
        afPostSpot2Server(completionHandler: { success, json -> Void in
            
            if (success) {
                
                debugPrint ("Spot upload returned successfully from async call")
                
                // Assign returned data to SwiftyJSON object ( an integer 0 or 1 )
                let data = JSON(json!)
                
                if data > 0
                {
                    // Change the status of the spot
                    self.setStatus(inStatus: .Uploaded)
                
                }
                
            } else
            {
                print("No data returned from async call")
                self.setStatus(inStatus: .UploadFailed)
            }
            
        })
        
    }
    
    // Internal function to send the spot to the server and receive a success/fail as a JSON array
    private func afPostSpot2Server(completionHandler:  @escaping (Bool, Int?) -> ())
    {
        // Display network activity indicator in status bar
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Make sure search string is properly escaped
        let expectedCharSet = NSCharacterSet.urlQueryAllowed
        let searchTerm = self.acRegistration?.addingPercentEncoding(withAllowedCharacters: expectedCharSet)
        
        // Convert date to MySQL format - date only
        let mySQLDate = spDateTime.toMySQLString()
        
        // Set destination url & value to send
        let url: String = "http://tbgweb.dyndns.info/iacdb/iosUploadSpot.php"
        let postValues: [String: String] = ["registration": searchTerm!, "location": self.spLocation!, "date": mySQLDate, "seenby": self.spName!]
        
        // Do asynchronous call to server using Alamofire library
        Alamofire.request(url, method: .get, parameters: postValues)
            .validate()
            
            .responseJSON { response in
                
                // check for errors
                guard response.result.error == nil else {
                    // got an error in getting the data, need to handle it
                    print("error calling POST on spot upload")
                    print(response.result.error!)
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    return completionHandler(false, nil)
                }
                
                // make sure we have got valid JSON as an array of key/vale pairs of strings
                guard let json = response.result.value as? Int! else {
                    print("Didn't get valid JSON from server")
                    print("Error: \(String(describing: response.result.error))")
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    return completionHandler(false, nil)
                }
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return completionHandler(true, json)
        }
    }
}
