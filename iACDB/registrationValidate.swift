//
//  registrationValidate.swift
//  iACDB
//
//  Created by Richard Walters on 17/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//
//  Custom class to take a registration string and validate its format and content against
//  the known patterns for ICAO Countrys

import UIKit

class registrationValidator {
    
    // MARK: Properties
    
    static var vPrefixes = [_ICAOPrefix]()                      // Civil Registration prefix data
    static var vMilitary = [_MilData]()                         // Military Registration pattern data
    
    typealias rv = registrationValidator                        // Create a shorthand for this class name
    
    // MARK: Initialisation
    
    // Constructor - Registration only
    init() {
        
        // Populate the validator with the array of information
        populatePrefixes()
    }
    
    // Internal function to do the validation
    public func validateRegistration(unvRegistration: String) -> _ICAOValidationResult{
        
        // Setup result defaults
        var retResult = _ICAOValidationResult()
        retResult.vReturn = unvRegistration
        
        // Test for empty string
        if unvRegistration.isEmpty { return retResult }
        
        // Trim the leading and trailing whitespace (if any)
        let trimmedRegistration: String? = unvRegistration.trim()
        
        // Default return string
        retResult.vReturn = trimmedRegistration!
        
        // Loop through array of ICAO Civil prefixes
        for rvp in rv.vPrefixes {
            
            // Get regex to use
            let regex = try! NSRegularExpression(pattern: rvp.Pattern , options: [])
            
            // Get the number of matches
            let matches = regex.matches(in: trimmedRegistration!, options: [], range: NSRange(location: 0, length: (trimmedRegistration?.characters.count)!))
            
            // If positive we have a match
            if matches.count > 0
            {
                retResult.vValid = true
                
                debugPrint("Reg: \(trimmedRegistration!) matched to: \(rvp.Country)")
                
                return retResult
            }
        }
        
        // Loop through array of Military prefixes
        for rvp in rv.vMilitary {
            
            // Get regex to use
            let regex = try! NSRegularExpression(pattern: rvp.Pattern , options: [])
            
            // Get the number of matches
            let matches = regex.matches(in: trimmedRegistration!, options: [], range: NSRange(location: 0, length: (trimmedRegistration?.characters.count)!))
            
            // If positive we have a match
            if matches.count > 0
            {
                retResult.vValid = true
                
                debugPrint("Reg: \(trimmedRegistration!) matched to: \(rvp.Country)")
                
                // if match break out of For and return
                return retResult
            }
        }
        
        return retResult
    }
    
    // Internal function to fill the prefix/pattern information
    private func populatePrefixes()
    {
        
        // Create the data to populate the array using regular expressions
        let data = [
            
            // Civil
            
            _ICAOPrefix(Prefix: "YA",   Country: "Afghanistan",        Pattern: "^YA-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ZA",   Country: "Albania",            Pattern: "^ZA-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ZA",   Country: "Albania",            Pattern: "^ZA-H[A-Z]{2}$"),        // Helicopters
            _ICAOPrefix(Prefix: "7T",   Country: "Algeria",            Pattern: "^7T-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "C3",   Country: "Andorra",            Pattern: "^C3-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "D2",   Country: "Angola",             Pattern: "^D2-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "VP-A", Country: "Anguilla",           Pattern: "^VP-A[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "V2",   Country: "Antigua",            Pattern: "^V2-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "LV",   Country: "Argentina",          Pattern: "^LV-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "LQ",   Country: "Argentina",          Pattern: "^LQ-[A-Z]{3}$"),         // Official Use
            _ICAOPrefix(Prefix: "EK",   Country: "Armenia",            Pattern: "^EK-[1][0-9]{4}$"),
            _ICAOPrefix(Prefix: "P4",   Country: "Aruba",              Pattern: "^P4-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "VH",   Country: "Australia",          Pattern: "^VH-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "OE",   Country: "Austria",            Pattern: "^OE-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "4K",   Country: "Azerbaijan",         Pattern: "^4K-AZ[1-9][0-9]{0,2}$"),
            _ICAOPrefix(Prefix: "4K",   Country: "Azerbaijan",         Pattern: "^4K-[1][0-9]{4}$"),
            
            _ICAOPrefix(Prefix: "C6",   Country: "Bahamas",            Pattern: "^C6-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "A9C",  Country: "Bahrain",            Pattern: "^A9C-[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "S2",   Country: "Bangladesh",         Pattern: "^S2-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "8P",   Country: "Barbados",           Pattern: "^8P-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "EW",   Country: "Belarus",            Pattern: "^EW-[1][0-9]{4}$"),
            _ICAOPrefix(Prefix: "EW",   Country: "Belarus",            Pattern: "^EW-[1-9][0-9]{2}[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "OO",   Country: "Belgium",            Pattern: "^OO-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "OO",   Country: "Belgium",            Pattern: "^OO-[A-Z][0-9]{2}$"),    // Microlights
            _ICAOPrefix(Prefix: "V3",   Country: "Belize",             Pattern: "^V3-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "TY",   Country: "Benin",              Pattern: "^TY-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "VP-B", Country: "Bermuda",            Pattern: "^VP-B[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "A5",   Country: "Bhutan",             Pattern: "^A5-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "CP",   Country: "Bolivia",            Pattern: "^CP-[1][0-9]{3}$"),
            _ICAOPrefix(Prefix: "T9",   Country: "Bosnia",             Pattern: "^T9-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "A2",   Country: "Botswana",           Pattern: "^A2-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "PP",   Country: "Brazil",             Pattern: "^PP-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "PR",   Country: "Brazil",             Pattern: "^PR-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "PT",   Country: "Brazil",             Pattern: "^PT-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "PU",   Country: "Brazil",             Pattern: "^PU-[A-Z]{3}$"),         // Microlights
            _ICAOPrefix(Prefix: "VP-L", Country: "British Virgin Islands",        Pattern: "^VP-L[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "V8",   Country: "Brunei",             Pattern: "^V8-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "V8",   Country: "Brunei",             Pattern: "^V8-[A-Z]{2}[1-9]$"),
            _ICAOPrefix(Prefix: "V8",   Country: "Brunei",             Pattern: "^V8-[0-9]{3}$"),
            _ICAOPrefix(Prefix: "LZ",   Country: "Bulgaria",           Pattern: "^LZ-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "XT",   Country: "Burkina Faso",       Pattern: "^XT-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9U",   Country: "Burundi",            Pattern: "^9U-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "XU",   Country: "Kampochea",          Pattern: "^XU-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "TJ",   Country: "Cameroon",           Pattern: "^TJ-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "C",    Country: "Canada",             Pattern: "^CF-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "C",    Country: "Canada",             Pattern: "^C-F[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "C",    Country: "Canada",             Pattern: "^C-G[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "C",    Country: "Canada",             Pattern: "^C-I[A-Z]{3}$"),          // Ultralights
            _ICAOPrefix(Prefix: "D4",   Country: "Cape Verde",         Pattern: "^D4-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "VP-C", Country: "Cayman Islands",     Pattern: "^VP-C[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "TL",   Country: "Central African Republic",     Pattern: "^TL-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "TT",   Country: "Mali",               Pattern: "^TT-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "CC",   Country: "Chile",              Pattern: "^CC-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "B",    Country: "China",              Pattern: "^B-[1][0-9]{3}$"),
            _ICAOPrefix(Prefix: "B",    Country: "China (Taiwan)",     Pattern: "^B-[1][0-9]{4}$"),
            _ICAOPrefix(Prefix: "B-H",  Country: "Hong Kong",          Pattern: "^B-H[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "B-K",  Country: "Hong Kong",          Pattern: "^B-K[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "B-L",  Country: "Hong Kong",          Pattern: "^B-L[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "B-M",  Country: "Macau",              Pattern: "^B-M[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "HJ",   Country: "Colombia",           Pattern: "^HJ-[1][0-9]{3}[A-Z]$"),
            _ICAOPrefix(Prefix: "HK",   Country: "Colombia",           Pattern: "^HK-[1][0-9]{3}[A-Z]$"),   // Microlights
            _ICAOPrefix(Prefix: "D6",   Country: "Comoros",            Pattern: "^D6-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "TN",   Country: "Congo",              Pattern: "^TN-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "E5",   Country: "Cook Islands",       Pattern: "^E5-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9Q",   Country: "Congo DR",           Pattern: "^9Q-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "TI",   Country: "Costa Rica",         Pattern: "^TI-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9A",   Country: "Croatia",            Pattern: "^9A-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9A",   Country: "Croatia",            Pattern: "^9A-[H][A-Z]{2}$"),        // Helicopters
            _ICAOPrefix(Prefix: "CU",   Country: "Cuba",               Pattern: "^CU-T[0-9]{4}$"),
            _ICAOPrefix(Prefix: "5B",   Country: "Cyprus",             Pattern: "^5B-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "OK",   Country: "Czech Republic",     Pattern: "^OK-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "OK",   Country: "Czech Republic",     Pattern: "^OK-[A-Z]{3}\\s[0-9]{2}$"),// Microlights
            _ICAOPrefix(Prefix: "OK",   Country: "Czech Republic",     Pattern: "^OK-[0-9]{4}$"),           // Gliders
            _ICAOPrefix(Prefix: "OKA",  Country: "Czech Republic",     Pattern: "^OKA-[0-9]{3}$"),          // Gliders
            
            _ICAOPrefix(Prefix: "OY",   Country: "Denmark",            Pattern: "^5B-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "OY",   Country: "Denmark",            Pattern: "^OY-H[A-Z]{2}$"),          // Helicopters
            _ICAOPrefix(Prefix: "J2",   Country: "Djibouti",           Pattern: "^J2-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "J7",   Country: "Dominica",           Pattern: "^J7-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "HI",   Country: "Dominican Republic", Pattern: "^HI-100[A-Z]{2}$"),
            
            _ICAOPrefix(Prefix: "HC",   Country: "Ecuador",            Pattern: "^HC-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "SU",   Country: "Egypt",              Pattern: "^SU-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "YS",   Country: "El Salvador",        Pattern: "^YS-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "3C",   Country: "Equatorial Guinea",  Pattern: "^3C-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "E3",   Country: "Eritrea",            Pattern: "^E3-[A-Z]{4}$"),
            _ICAOPrefix(Prefix: "ES",   Country: "Estonia",            Pattern: "^ES-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ET",   Country: "Ethiopia",           Pattern: "^ET-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "VP-F", Country: "Falkland Islands",   Pattern: "^VP-F[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "OY",   Country: "Faroe Islands",      Pattern: "^OY-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "OY",   Country: "Faroe Islands",      Pattern: "^OY-H[A-Z]{2}$"),          // Helicopters
            _ICAOPrefix(Prefix: "OY",   Country: "Faroe Islands",      Pattern: "^OY-X[A-Z]{2}$"),          // Gliders
            _ICAOPrefix(Prefix: "DQ",   Country: "Fiji Islands",       Pattern: "^DQ-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "OH",   Country: "Finland",            Pattern: "^OH-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "F",    Country: "France",             Pattern: "^F-[A-Z]{4}$"),
            _ICAOPrefix(Prefix: "F",    Country: "France",             Pattern: "^F-C[A-Z]{3}$"),           // Gliders
            _ICAOPrefix(Prefix: "F",    Country: "France",             Pattern: "^F-O[A-Z]{3}$"),           // Overseas Territories
            _ICAOPrefix(Prefix: "F",    Country: "France",             Pattern: "^F-P[A-Z]{3}$"),           // Homebuilt
            _ICAOPrefix(Prefix: "F",    Country: "France",             Pattern: "^F-W[A-Z]{3}$"),           // Test and Delivery
            _ICAOPrefix(Prefix: "F-OG", Country: "French West Indies", Pattern: "^F-OG[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "F",    Country: "France",             Pattern: "^F-[A-Z]{4}$"),
            
            _ICAOPrefix(Prefix: "TR",   Country: "Gabon",              Pattern: "^TR-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "C5",   Country: "Gambia",             Pattern: "^C5-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "4L",   Country: "Georgia",            Pattern: "^4L-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "4L",   Country: "Georgia",            Pattern: "^4L-[1-9][0-9]{4}$"),
            _ICAOPrefix(Prefix: "D",    Country: "Germany",            Pattern: "^D-[A-Z]{4}$"),
            _ICAOPrefix(Prefix: "D",    Country: "Germany",            Pattern: "^D-[1-9][0-9]{3}$"),       // Gliders
            _ICAOPrefix(Prefix: "9G",   Country: "Ghana",              Pattern: "^9G-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "VP-G", Country: "Gibraltar",          Pattern: "^VP-G[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "SX",   Country: "Greece",             Pattern: "^SX-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "J3",   Country: "Grenada",            Pattern: "^J3-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "TG",   Country: "Guatemala",          Pattern: "^TG-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "2",    Country: "Guernsey",           Pattern: "^2-[A-Z]{4}$"),
            
            _ICAOPrefix(Prefix: "3X",   Country: "Guinea",             Pattern: "^3X-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "J5",   Country: "Guinea Bissau",      Pattern: "^J5-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "8R",   Country: "Guyana",             Pattern: "^8R-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "HH",   Country: "Haiti",              Pattern: "^HH-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "HR",   Country: "Honduras",           Pattern: "^HR-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "HA",   Country: "Hungary",            Pattern: "^HA-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "TF",   Country: "Iceland",            Pattern: "^TF-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "TF",   Country: "Iceland",            Pattern: "^TF-[1-9][0-9]{2}$"),      // Microlights
            _ICAOPrefix(Prefix: "VT",   Country: "India",              Pattern: "^VT-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "VT",   Country: "India",              Pattern: "^VT-H[A-Z]{2}$"),          // Helicopters
            _ICAOPrefix(Prefix: "PK",   Country: "Indonesia",          Pattern: "^PK-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "EP",   Country: "Iran",               Pattern: "^EP-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "YI",   Country: "Iraq",               Pattern: "^YI-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "EI",   Country: "Ireland",            Pattern: "^EI-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "M",    Country: "Isle of Man",        Pattern: "^M-[A-Z]{4}$"),
            _ICAOPrefix(Prefix: "I",    Country: "Italy",              Pattern: "^I-[A-Z]{4}$"),
            _ICAOPrefix(Prefix: "TU",   Country: "Ivory Coast",        Pattern: "^TU-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "6Y",   Country: "Jamaica",            Pattern: "^6Y-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "JA",   Country: "Japan",              Pattern: "^JA-[0-9]{3}[1-9]$"),
            _ICAOPrefix(Prefix: "JA",   Country: "Japan",              Pattern: "^JA-[0-9]{2}[1-9][A-Z]$"),
            _ICAOPrefix(Prefix: "JA",   Country: "Japan",              Pattern: "^JA-[0-9][1-9][A-Z]{2}$"),
            _ICAOPrefix(Prefix: "JA",   Country: "Japan",              Pattern: "^JA-[A-Z][0-9]{3}$"),      // Balloons
            _ICAOPrefix(Prefix: "ZJ",   Country: "Jersey",             Pattern: "^ZJ-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "JY",   Country: "Jordan",             Pattern: "^JY-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "UP",   Country: "Kazakhstan",         Pattern: "^UP-[A-Z]{3}[0-9]{2}$"),
            _ICAOPrefix(Prefix: "5Y",   Country: "Kenya",              Pattern: "^5Y-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "T3",   Country: "Kiribati",           Pattern: "^T3-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "P",    Country: "North Korea",        Pattern: "^P-[5-9][0-9]{2}$"),
            _ICAOPrefix(Prefix: "HL",   Country: "South Korea",        Pattern: "^HL-[1-9][0-9]{3}$"),
            _ICAOPrefix(Prefix: "9K",   Country: "Kuwait",             Pattern: "^9K-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "EX",   Country: "Kyrgyzstan",         Pattern: "^EX-[1-9][0-9]{2}$"),
            _ICAOPrefix(Prefix: "EX",   Country: "Kyrgyzstan",         Pattern: "^EX-[1-9][0-9]{4}$"),
            
            _ICAOPrefix(Prefix: "RDPL", Country: "Laos",               Pattern: "^RDPL-[1-9][0-9]{4}$"),
            _ICAOPrefix(Prefix: "YL",   Country: "Latvia",             Pattern: "^YL-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "OD",   Country: "Lebanon",            Pattern: "^OD-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "7P",   Country: "Lesotho",            Pattern: "^7P-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "A8",   Country: "Liberia",            Pattern: "^A8-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "5A",   Country: "Libya",              Pattern: "^5A-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "LY",   Country: "Lithuania",          Pattern: "^LY-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "LX",   Country: "Luxembourg",         Pattern: "^LX-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "LX",   Country: "Luxembourg",         Pattern: "^LX-H[A-Z]{2}$"),          // Helicopters
            
            _ICAOPrefix(Prefix: "Z3",   Country: "Macedonia",          Pattern: "^Z3-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "Z3",   Country: "Macedonia",          Pattern: "^Z3-H[A-Z]{2}$"),          // Helicopters
            _ICAOPrefix(Prefix: "5R",   Country: "Madagascar",         Pattern: "^5R-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "7Q",   Country: "Malawi",             Pattern: "^7Q-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9M",   Country: "Malaysia",           Pattern: "^9M-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "8Q",   Country: "Maldives",           Pattern: "^8Q-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "TZ",   Country: "Mali",               Pattern: "^TZ-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9H",   Country: "Malta",              Pattern: "^9H-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "V7",   Country: "Marshall Islands",   Pattern: "^V7-[0-9]{3}[1-9]$"),
            _ICAOPrefix(Prefix: "5T",   Country: "Mauritania",         Pattern: "^5T-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "3B",   Country: "Mauritius",          Pattern: "^3B-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "XA",   Country: "Mexico",             Pattern: "^XA-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "XB",   Country: "Mexico",             Pattern: "^XB-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "XC",   Country: "Mexico",             Pattern: "^XC-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "V6",   Country: "Micronesia",         Pattern: "^V6-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ER",   Country: "Moldova",            Pattern: "^ER-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ER",   Country: "Moldova",            Pattern: "^ER-[1-9][0-9]{4}$"),
            _ICAOPrefix(Prefix: "3A",   Country: "Monaco",             Pattern: "^3A-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "3A",   Country: "Monaco",             Pattern: "^3A-H[A-Z]{2}$"),          // Helicopters
            _ICAOPrefix(Prefix: "JU",   Country: "Mongolia",           Pattern: "^JU-[1-9][0-9]{3}$"),
            _ICAOPrefix(Prefix: "4O",   Country: "Montenegro",         Pattern: "^4O-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "VP-M", Country: "Monserrat",          Pattern: "^VP-M[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "CN",   Country: "Morroco",            Pattern: "^CN-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "C9",   Country: "Mozambique",         Pattern: "^C9-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "XY",   Country: "Myanmar",            Pattern: "^XY-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "XZ",   Country: "Myanmar",            Pattern: "^XZ-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "V5",   Country: "Namibia",            Pattern: "^V5-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "C2",   Country: "Nauru",              Pattern: "^C2-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9N",   Country: "Nepal",              Pattern: "^9N-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "PH",   Country: "Neterlands",         Pattern: "^PH-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "PH",   Country: "Neterlands",         Pattern: "^PH-[1-9][A-Z][1-9]$"),    // Microlights
            _ICAOPrefix(Prefix: "PH",   Country: "Neterlands",         Pattern: "^PH-[1-9][0-9]{2}$"),      // Motor Gliders
            _ICAOPrefix(Prefix: "PH",   Country: "Neterlands",         Pattern: "^PH-[1-9][0-9]{3}$"),      // Gliders
            _ICAOPrefix(Prefix: "PJ",   Country: "Curacao",            Pattern: "^PJ-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "ZK",   Country: "New Zealand",        Pattern: "^ZK-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ZL",   Country: "New Zealand",        Pattern: "^ZL-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ZM",   Country: "New Zealand",        Pattern: "^ZM-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "YN",   Country: "Nicaragua",          Pattern: "^YN-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "5U",   Country: "Niger",              Pattern: "^5U-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "5N",   Country: "Nigeria",            Pattern: "^5N-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "LN",   Country: "Norway",             Pattern: "^LN-[A-Z]{3}$"),
            
            
            _ICAOPrefix(Prefix: "A4O",  Country: "Oman",               Pattern: "^A4O-[A-Z]{2}$"),
            
            _ICAOPrefix(Prefix: "AP",   Country: "Pakistan",           Pattern: "^AP-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "SU-Y", Country: "Palestine",          Pattern: "^SU-Y[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "HP",   Country: "Panama",             Pattern: "^HP-[1-9][0-9]{3}[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "P2",   Country: "Papa New Guinea",    Pattern: "^P2-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ZP",   Country: "Paraguay",           Pattern: "^ZP-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "OB",   Country: "Peru",               Pattern: "^5U-[1-9][0-9]{3}$"),
            _ICAOPrefix(Prefix: "RP-C", Country: "Philippines",        Pattern: "^RP-C[0-9]{4}$"),
            _ICAOPrefix(Prefix: "SP",   Country: "Poland",             Pattern: "^SP-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "CR",   Country: "Portugal",           Pattern: "^CR-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "CS",   Country: "Portugal",           Pattern: "^CS-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "A7",   Country: "Qatar",              Pattern: "^A7-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "F-OD", Country: "Reunion Island",     Pattern: "^F-OD[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "YR",   Country: "Romania",            Pattern: "^YR-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "YR",   Country: "Romania",            Pattern: "^YR-[1-9][0-9]{3}$"),      // Gliders
            _ICAOPrefix(Prefix: "RA",   Country: "Russia",             Pattern: "^RA-[0-9]{5}$"),
            _ICAOPrefix(Prefix: "RA",   Country: "Russia",             Pattern: "^RA-[0-9]{4}[A-Z]$"),
            _ICAOPrefix(Prefix: "RF",   Country: "Russia",             Pattern: "^RF-[0-9]{5}$"),           // State owned a/c
            _ICAOPrefix(Prefix: "9XR",  Country: "Rwanda",             Pattern: "^9XR-[A-Z]{2}$"),
            
            
            _ICAOPrefix(Prefix: "VQ-H", Country: "Ascension",          Pattern: "^VQ-H[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "V4",   Country: "St Kitts & Nevis",   Pattern: "^V4-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "J6",   Country: "Saint Lucia",        Pattern: "^J6-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "J8",   Country: "St Vincent & Grenadines",  Pattern: "^J8-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "5W",   Country: "Samoa",              Pattern: "^5W-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "T7",   Country: "San Marino",         Pattern: "^T7-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "T7",   Country: "San Marino",         Pattern: "^T7-[0-9]{3}$"),           // Microlights
            _ICAOPrefix(Prefix: "S9",   Country: "Sao Tom & Prncipe",  Pattern: "^S9-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "HZ",   Country: "Saudi Arabia",       Pattern: "^HZ-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "HZ",   Country: "Saudi Arabia",       Pattern: "^HZ-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "HZ",   Country: "Saudi Arabia",       Pattern: "^HZ-[A-Z]{2}[0-9]$"),
            _ICAOPrefix(Prefix: "HZ",   Country: "Saudi Arabia",       Pattern: "^HZ-[A-Z]{3}[0-9]{1,2}$"),
            _ICAOPrefix(Prefix: "6V",   Country: "Senegal",            Pattern: "^6V-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "6W",   Country: "Senegal",            Pattern: "^6W-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "YU",   Country: "Serbia",             Pattern: "^YU-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "S7",   Country: "Seychelles",         Pattern: "^S7-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9L",   Country: "Sierra Leone",       Pattern: "^9L-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9V",   Country: "Singapore",          Pattern: "^9V-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "OM",   Country: "Slovakia",           Pattern: "^OM-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "S5",   Country: "Slovenia",           Pattern: "^S5-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "S5",   Country: "Slovenia",           Pattern: "^S5-H[A-Z]{2}$"),          // Helicopters
            _ICAOPrefix(Prefix: "H4",   Country: "Solomon Islands",    Pattern: "^H4-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "6O",   Country: "Somalia",            Pattern: "^6O-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ZS",   Country: "South Africa",       Pattern: "^ZS-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ZT",   Country: "South Africa",       Pattern: "^ZT-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ZU",   Country: "South Africa",       Pattern: "^ZU-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "EC",   Country: "Spain",              Pattern: "^EC-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "EC",   Country: "Spain",              Pattern: "^EC-[0-9]{3}$"),           // Test and Delivery
            _ICAOPrefix(Prefix: "4R",   Country: "Sri Lanka",          Pattern: "^4R-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "ST",   Country: "Sudan",              Pattern: "^ST-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "PZ",   Country: "Surinam",            Pattern: "^PZ-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "3D",   Country: "Swaziland",          Pattern: "^3D-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "SE",   Country: "Sweden",             Pattern: "^SE-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "HB",   Country: "Switzerland",        Pattern: "^HB-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "YK",   Country: "Syria",              Pattern: "^YK-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "F-OH", Country: "Tahiti",             Pattern: "^F-OH[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "EY",   Country: "Tajikistan",         Pattern: "^EY-[0-9]{4}$"),
            _ICAOPrefix(Prefix: "5H",   Country: "Tanzania",           Pattern: "^5H-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "HS",   Country: "Thailand",           Pattern: "^HS-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "5V",   Country: "Togo",               Pattern: "^5V-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "A3",   Country: "Tonga",              Pattern: "^A3-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9Y",   Country: "Trinidad & Tobago",  Pattern: "^9Y-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "TS",   Country: "Tunisia",            Pattern: "^TS-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "TC",   Country: "Turkey",             Pattern: "^TC-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "EZ",   Country: "Turkmenistan",       Pattern: "^EZ-[A-Z][0-9]{3}$"),
            _ICAOPrefix(Prefix: "VQ-T", Country: "Turks & Caicos",     Pattern: "^VQ-T[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "T2",   Country: "Tuvalu",             Pattern: "^T2-[A-Z]{3}$"),
            
            _ICAOPrefix(Prefix: "5X",   Country: "Uganda",             Pattern: "^5X-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "UR",   Country: "Ukraine",            Pattern: "^UR-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "UR",   Country: "Ukraine",            Pattern: "^UR-[0-9]{5}$"),
            _ICAOPrefix(Prefix: "A6",   Country: "UAE",                Pattern: "^A6-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "G",    Country: "UK",                 Pattern: "^G-[A-Z]{4}$"),
            _ICAOPrefix(Prefix: "G",    Country: "UK",                 Pattern: "^G-[0-9]{1,2}-[0-9]{1,2}$"),  //Test and Delivery
            _ICAOPrefix(Prefix: "4U",   Country: "United Nations",     Pattern: "^4U-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "N",    Country: "USA",                Pattern: "^N-[0-9]{1,5}$"),
            _ICAOPrefix(Prefix: "N",    Country: "USA",                Pattern: "^N-[0-9]{1,4}[A-Z]$"),
            _ICAOPrefix(Prefix: "N",    Country: "USA",                Pattern: "^N-[0-9]{1,3}[A-Z]{2}$"),
            _ICAOPrefix(Prefix: "CX",   Country: "Uruguay",            Pattern: "^CX-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "UK",   Country: "Uzbekistan",         Pattern: "^UK-[0-9]{5}$"),
            
            _ICAOPrefix(Prefix: "YJ",   Country: "Vanuatu",            Pattern: "^YJ-[A-Z]{2}[0-9]{1,2}$"),
            _ICAOPrefix(Prefix: "HV",   Country: "Vatican City",       Pattern: "^HV-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "YV",   Country: "Venezuela",          Pattern: "^YV-[0-9]{4}$"),
            _ICAOPrefix(Prefix: "YV",   Country: "Venezuela",          Pattern: "^YV-[0-9]{4}[A-P]$"),
            _ICAOPrefix(Prefix: "YV",   Country: "Venezuela",          Pattern: "^YV-[A-Z]{3}[1-9]$"),
            _ICAOPrefix(Prefix: "VN",   Country: "Vietnam",            Pattern: "^VN-[0-9]{4}$"),
            _ICAOPrefix(Prefix: "VN",   Country: "Vietnam",            Pattern: "^VN-A[0-9]{3}$"),
            
            _ICAOPrefix(Prefix: "7O",   Country: "Yemen",              Pattern: "^7O-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "9J",   Country: "Zambia",             Pattern: "^9J-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "CX",   Country: "Uruguay",            Pattern: "^CX-[A-Z]{3}$"),
            _ICAOPrefix(Prefix: "Z",    Country: "Zimbabwe",           Pattern: "^Z-[A-Z]{3}$")
            
            // Military
            
        ]
        
        // Populate the array with data
        rv.vPrefixes = data
        
        debugPrint("Registration Validator loaded with \(rv.vPrefixes.count) civil entries")
        
        let mdata = [
            
            _MilData(Country: "Belgian Air Force",  Pattern: "^[A-Z]{2}-[0-9]{2}$"),
            _MilData(Country: "Luftwaffe",          Pattern: "^[0-9]{2}\\+[0-9]{2}$"),
            _MilData(Country: "UK Royal Air Force", Pattern: "^[A-Z]{2}[0-9]{3}$"),
            _MilData(Country: "USAF",               Pattern: "^[0-9]{2}-[0-9]{4,6}$"),
            _MilData(Country: "United States Navy", Pattern: "^[0-9]{6}$")
            
            
        ]
        
        rv.vMilitary = mdata
        
        debugPrint("Registration Validator loaded with \(rv.vMilitary.count) military entries")    }
    
    
}

struct _MilData {
    
    let Country:        String                  // Country to whom pattern belongs
    let Pattern:        String                  // Regex pattern for checking validity
}

struct _ICAOPrefix {
    
    let Prefix:         String                 // ICAO Prefix
    let Country:        String                 // Country to whom prefix belongs
    let Pattern:        String                 // Regex pattern for checking validity
    
}

struct _ICAOValidationResult {
    
    var vReturn:    String                      // Registration passed back
    var vValid:     Bool                        // Validated or not
    
    init(){                                     // Instantiate with default value
        
        vReturn = ""
        vValid = false
    }
}
