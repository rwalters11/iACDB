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
    
    var acImageAvailable: Bool                      // True if image available
    var acImage:          UIImage?                  // Latest image (if exists)
    
    
    
    // MARK: Initialisation
    
    // Constructor - Registration only
    init(inRegistration: String) {
        
        self.acRegistration = inRegistration        // Assign registration
        
        self.acType=""                              // Set defaults for the rest
        self.acSeries=""
        self.acOperator=""
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
        self.acImage=nil
    }
    
    func setImage(inImage: UIImage)
    {
        self.acImage = inImage
    }
    
}
