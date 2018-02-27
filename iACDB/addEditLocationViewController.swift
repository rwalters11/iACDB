//
//  addEditLocationViewController.swift
//  iACDB
//
//  Created by Richard Walters on 07/01/2017.
//  Copyright © 2017 Richard Walters. All rights reserved.
//

// Import Apple frameworks
import UIKit
import CoreData
import CoreLocation

// Import 3rd party frameworks
import Alamofire
import SwiftyJSON

class addEditLocationViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    
    // Holder for value passed in by segue
    var inLocation: String = ""
    var editedLocation: String? = nil
    
    var editLock: Bool = false
    
    var freqTally: Float = 0
    
    @IBOutlet weak var txtLocationName: UITextField!
    
    @IBOutlet weak var txtLocationLatitude: UITextField!
    
    @IBOutlet weak var txtLocationLongitude: UITextField!
    
    @IBOutlet weak var btnLock: UIBarButtonItem!
    @IBAction func btnLock(_ sender: UIBarButtonItem) {
        
        // Toggle edit lock on text fields.
        toggleEditLock(inController: self)

    }
    
    @IBOutlet weak var txtFreqGround: UITextField!
    
    @IBOutlet weak var txtFreqTower1: UITextField!
    @IBOutlet weak var txtFreqTower2: UITextField!
    
    @IBOutlet weak var txtFreqDirector: UITextField!
    
    @IBOutlet weak var txtFreqApproach1: UITextField!
    @IBOutlet weak var txtFreqApproach2: UITextField!
    
    // Collection of all the text fields
    @IBOutlet var txtFields: [UITextField]!
    
    @IBAction func txtFieldsEndEdit(_ sender: UITextField) {
        
        textFieldDidEndEditing(sender)
    }
    
    // Delete button
    @IBOutlet weak var btnDelete: UIButton!
    @IBAction func btnDelete(_ sender: UIButton) {
        
        let message = "Confirm delete ?"
        
        let alertController = UIAlertController(title: "iACDB", message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // Create the actions
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
            
            // Do nothing
        }
        
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive) {
            UIAlertAction in
            
            self.tbgLocationsManager(mode: "delete", inLocation: self.txtLocationName.text!, editedLocation: nil)
        }
        
        // Add the actions
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        // Show the alert
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBOutlet weak var swSmallAirfield: UISwitch!
    @IBAction func swSmallAirfield(_ sender: UISwitch) {
        
    }
    
    @IBOutlet weak var stkGround: UIStackView!
    @IBOutlet weak var stkTower2: UIStackView!
    @IBOutlet weak var stkDirector: UIStackView!
    @IBOutlet weak var stkApproach1: UIStackView!
    @IBOutlet weak var stkApproach2: UIStackView!
    
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the title
        self.navigationItem.title = inLocation
        
        // Configure the delete button
        btnDelete.backgroundColor = .clear
        btnDelete.layer.cornerRadius = 5
        btnDelete.layer.borderWidth = 1
        btnDelete.layer.borderColor = UIColor.lightGray.cgColor
        
        // Hide Delete button if adding New Location
        if inLocation == "New Location" {
            self.btnDelete.isHidden = true
        }
        
        // Test for "" & get data for editing
        if !inLocation.isEmpty && inLocation != "New Location" {
            
            // Get context for CoreData
            let moc = getContext()
            
            // Setup NSFetchResultController for table (entity)
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntLocations")
            
            // Setup sorts
            let fetchSort = NSSortDescriptor(key: "location", ascending: true)
            fetchRequest.sortDescriptors = [fetchSort]
            
            // Setup predicate
            let predicate = NSPredicate(format: "location == %@", inLocation)
            fetchRequest.predicate = predicate
            
            // Perform the fetch
            do {
                
                if let result = try moc.fetch(fetchRequest) as? [EntLocations] {
                    
                    let loc = result[0]
                    
                    self.txtLocationName.text = loc.location
                    self.txtLocationLatitude.text = String(loc.latitude)
                    self.txtLocationLongitude.text = String(loc.longitude)
                    
                    self.txtFreqGround.text = String(format:"%03.3f",loc.freqGround)
                    self.txtFreqTower1.text = String(format:"%03.3f",loc.freqTower1)
                    self.txtFreqTower2.text = String(format:"%03.3f",loc.freqTower2)
                    self.txtFreqDirector.text = String(format:"%03.3f",loc.freqDirector)
                    self.txtFreqApproach1.text = String(format:"%03.3f",loc.freqApproach1)
                    self.txtFreqApproach2.text = String(format:"%03.3f",loc.freqApproach2)
                    
                    freqTally = loc.freqGround + loc.freqTower2 + loc.freqDirector + loc.freqApproach1 + loc.freqApproach2
                }
                
            }catch let error as NSError {
                rwPrint(inFunction: #function, inMessage:"Unable to perform fetch of Locations: \(error.localizedDescription)")
            }
        }
        
        // Set Small Airfield switch On/Off
        if freqTally > 0 {
            
            swSmallAirfield.setOn(false, animated: true)
        }else{
            swSmallAirfield.setOn(true, animated: true)
        }
        
        // Customise display of Frequency fields
        setSmallAirfield()
        
        // Suppress display of zero value fields (edit)
        blankZeroFields()
        
        // Set initial text field editing status
        toggleEditLock(inController: self)
    }
    
    // Do Add/Edit/Delete as View disappears - triggered by Back button
    override func viewWillDisappear(_ animated: Bool) {
        
        // Take action depending on the inLocation title
        switch inLocation {
            
            case "":
                // Do nothing
                break
            
            // New Location
            case "New Location":
                
                // Return if not validated
                if !validateLocation() {return}
                
                tbgLocationsManager(mode: "add", inLocation: txtLocationName.text!, editedLocation: nil)
            
                break
            
            // Existing Location
            default:
                
                // Return if not validated
                if !validateLocation() {return}
                
                // If editedLocation isnot nil it's an edit
                guard let _ = editedLocation else {return}
                
                tbgLocationsManager(mode: "edit", inLocation: inLocation, editedLocation: editedLocation)
                
                break
        }
    }
    
    // Validate the Added/Edited Location data
    func validateLocation() -> Bool {
        
        // If Location name is empty skip
        if (txtLocationName.text?.isEmpty)! { return false}
        
        var validated: Bool = false
        
        // Capitalise name
        txtLocationName.text = txtLocationName.text?.capitalized
        
        validated = true
        
        return validated
    }
    
    // Validate Lat/Long coordinate
    func latlongValidation(sCoordinate: String, inType: String) -> Bool {
        
        var valid: Bool = false
        
        let coordinate = Float(sCoordinate)!
        
        switch inType {
            
            case "Lat":
            
                if coordinate > -90 && coordinate < 90 { valid = true }
            
            case "Long":
            
                if coordinate > -180 && coordinate < 180 { valid = true }
            
        default:
            break
        }
        
        
        return valid
    }

    // Validate the frequency is between 108 * 137 MHz
    func frequencyValidation(sFrequency: String) -> Bool {
        
        // Empty field - skip validation
        if sFrequency.isEmpty { return true }
        
        var valid: Bool = false
        
        let frequency = Float(sFrequency)!
        
        // Frequency range for VHF comms
        if frequency >= 108 && frequency <= 137 { valid = true }
        
        return valid
    }
    
    /*
     * Function to handle sending & receiving of data to Locations Manager on TBG Server
     */
    func tbgLocationsManager(mode: String, inLocation: String, editedLocation: String?) {
        
        //***********   Network connectivity checking
        
        // Check network connection
        let netStatus = currentReachabilityStatus()
        if netStatus == .notReachable
        {
            rwPrint(inFunction: #function, inMessage: "Network unavailable")
            
            let message = "No data connection"
            
            // Tell user
            showAlert(inTitle: "iACDB", inMessage: message)
            
            return
        }
        
        // Setup the parameters for the web request
        
        var postValues: [String: String]? = nil
        
        switch mode {
            
            case "add":
                
                postValues = ["mode":       "add",
                              "location":   inLocation,
                              "tower1":     txtFreqTower1.text!,
                              "tower2":     txtFreqTower2.text!,
                              "ground":     txtFreqGround.text!,
                              "director":   txtFreqDirector.text!,
                              "approach1":  txtFreqApproach1.text!,
                              "approach2":  txtFreqApproach2.text!
                            ]
            break
            
            case "edit":
                
                postValues = ["mode":       "edit",
                              "location":   inLocation,
                              "newlocation":editedLocation!,
                              "tower1":     txtFreqTower1.text!,
                              "tower2":     txtFreqTower2.text!,
                              "ground":     txtFreqGround.text!,
                              "director":   txtFreqDirector.text!,
                              "approach1":  txtFreqApproach1.text!,
                              "approach2":  txtFreqApproach2.text!
                            ]
            break
            
            case "delete":
                

                postValues = ["mode": "delete", "location": inLocation]
                
            break
            
        default:
            break
        }
        
        //********** Send the request to the server
        
        // Display network activity indicator in status bar
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Set destination url & value to send
        let url: String = "https://tbgweb.dyndns.info/iacdb/iosLocationsEditor.php"
        
        // Do asynchronous call to server using Alamofire library
        Alamofire.request(url, method: .post, parameters: postValues)
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
                
                let locationsCount = json
                
                //**********   Test returned count
                if locationsCount! > 0
                {
                    // Sync the remote DB to CoreData to reflect changes
                    

                    
                    rwPrint(inFunction: #function, inMessage: "Location update complete")
                }else{
                    rwPrint(inFunction: #function, inMessage: "Location update failed")
                }
        }
    }
    
    
    // MARK: - UITextField Delegates
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        switch textField.tag {
            
        // Location
        case 1:
            // Test for new location
            if inLocation != "" {
                
                // If the passed in location and the text field are different it is an edit
                if inLocation != txtLocationName.text!
                {
                    editedLocation = txtLocationName.text!
                }
            }
            break
            
        // Latitude
        case 2:
            
            // Validate the latitude
            let result = latlongValidation(sCoordinate: textField.text!, inType: "Lat")
            
            // If invalid ...
            if !result {
                
                // Tell the user
                showAlert(inTitle: "iACDB", inMessage: "Invalid latitude")
                
                // Change font colour to red
                textField.textColor = UIColor.red
                
            }
            
        // Longitude
        case 3:
            
            // Validate the longitude
            let result = latlongValidation(sCoordinate: textField.text!, inType: "Long")
            
            // If invalid ...
            if !result {
                
                // Tell the user
                showAlert(inTitle: "iACDB", inMessage: "Invalid longitude")
                
                // Change font colour to red
                textField.textColor = UIColor.red
                
            }
            
        // Frequencies
        case 4-9:
            
            // Validate the frequency
            let result = frequencyValidation(sFrequency: textField.text!)
            
            // If invalid ...
            if !result {
                
                // Tell the user
                showAlert(inTitle: "iACDB", inMessage: "Invalid frequency")
                
                // Change font colour to red
                textField.textColor = UIColor.red
                
            }
            
        default: break
            
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder();
        return true;
    }
    
    /*
     *
     *  Function to toggle the enable/disable of editing the text fields
     *
     */
    func toggleEditLock(inController: addEditLocationViewController) {
        
        switch editLock {
            
        case true:
            editLock = false
            btnLock.title = "Lock"
        case false:
            editLock = true
            btnLock.title = "Unlock"
        }
        
        for textField in inController.txtFields {
            
            textField.isEnabled = !editLock
            btnDelete.isEnabled = !editLock
        }
        
        txtLocationName.becomeFirstResponder()
    }
    
    /*
     *  Function to suppress display of zero value fields - looks better
     */
    func blankZeroFields() {
        
        for textField in self.txtFields {
            
            if textField.text?.first == "0" {
                textField.text = ""
            }
        }
    }
    
    /*
 *
 */
    func setSmallAirfield() {
        
        switch swSmallAirfield.isOn {
            
        case true:
            stkGround.isHidden = true
            stkTower2.isHidden = true
            stkDirector.isHidden = true
            stkApproach1.isHidden = true
            stkApproach2.isHidden = true
            
        case false:
            stkGround.isHidden = false
            stkTower2.isHidden = false
            stkDirector.isHidden = false
            stkApproach1.isHidden = false
            stkApproach2.isHidden = false
        }
    }

}
