//
//  infoAircraft.swift
//  iACDB
//
//  Created by Richard Walters on 03/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//

import UIKit

// Custom class to hold info on an individual aircraft

class infoAircraft {
    
    // MARK: Properties
    
    var acRegistration:   String                    // Registration
    var acType:           String                    // Type
    var acSeries:         String                    // Series
    var acOperator:       String                    // Operator
    var acConstructor:    String                    // Constructor
    var acFuselage:       String                    // Fuselage
    var acModeS:          String                    // Mode S
    var recordNum:        Int16                     // Record Number
    var acDelivery:       String                    // Delivery Date as string in format "mm/YY" as held in ACDB on server
    
    var acImageAvailable: Bool                      // True if image available
    var acImage:          UIImage?                  // Latest image (if exists)
    
    // MARK: Initialisation
    
    // Constructor - Registration only
    init?(inRegistration: String) {
        
        if inRegistration.isEmpty { return nil }
        
        self.acRegistration = inRegistration        // Assign registration
        
        self.acType=""                              // Set defaults for the rest
        self.acSeries=""
        self.acOperator=""
        self.acConstructor=""
        self.acFuselage=""
        self.acModeS=""
        self.recordNum=0
        self.acDelivery=""
        
        self.acImageAvailable=false
        self.acImage=nil
    }
    
    // Constructor - All values with optional image
    init(inRegistration: String, inType: String, inSeries: String, inOperator: String, inMarker: Bool ){
        
        self.acRegistration = inRegistration
        
        self.acType = inType
        self.acSeries = inSeries
        self.acOperator = inOperator
        self.acImageAvailable=inMarker
        
        self.acConstructor=""
        self.acFuselage=""
        self.acModeS=""
        self.recordNum=0
        self.acDelivery=""
        self.acImage=nil
    }
    
    func setImage(inImage: UIImage)
    {
        self.acImage = inImage
    }
    
    // Function to recieve a Date type and assign it converted to a string as mm/YY as held in ACDB server
    func setDeliveryDate(inDate: Date)
    {
        let dFormatter = DateFormatter()
        dFormatter.locale = Locale(identifier: "en_GB")
        dFormatter.dateFormat = "MM/yy"
        
        self.acDelivery = dFormatter.string(from: inDate)
    }
    
    // Function to convert ACDB style date (mm/yy) to standard date for setting DatePicker value
    // Returns converted date or nil
    func getDeliveryDate() -> Date?
    {
        // Extract month & year from ACDB string
        let dateString = "01/" + self.acDelivery
        
        // Calculate date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        dateFormatter.locale = Locale(identifier: "en_GB")
        guard let returnDate = dateFormatter.date(from: dateString) else
        {
            // Return gregorian date
            return nil
        }
        
        // Return gregorian date
        return returnDate
    }
}
