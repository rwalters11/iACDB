//
//  EntSpots+CoreDataProperties.swift
//  
//
//  Created by Richard Walters on 21/01/2017.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension EntSpots {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EntSpots> {
        return NSFetchRequest<EntSpots>(entityName: "EntSpots");
    }

    @NSManaged public var date: NSDate?
    @NSManaged public var location: String?
    @NSManaged public var registration: String?
    @NSManaged public var status: Int16
    
    // Calculate the derived value for the CoreData transient attribute we are going to use to group our tableView by Date.
    @NSManaged public var sectionDate: String?
    /*
    {
        
        // Create and cache the section identifier on demand.
        
        self.willAccessValueForKey("sectionDate")
        var tmp = self.primitiveValueForKey("sectionDate") as? String
        self.didAccessValueForKey("sectionDate")
        
        if tmp == nil {
            if let timeStamp = self.valueForKey("date") as? NSDate {
                /*
                 Sections are organized by month and year. Create the section
                 identifier as a string representing the number (year * 1000) + month;
                 this way they will be correctly ordered chronologically regardless
                 of the actual name of the month.
                 */
                let calendar  = NSCalendar.currentCalendar()
                let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: timeStamp)
                tmp = String(format: "%ld", components.year * 1000 + components.month)
                self.setPrimitiveValue(tmp, forKey: "sectionDate")
            }
        }
        return tmp
    }
 */
}
