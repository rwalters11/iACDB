//
//  addSpotViewController2.swift
//  iACDB
//
//  Created by Richard Walters on 29/01/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//
// Version 2
// Using Eureka library as base for form.

// Import Apple frameworks
import UIKit
import CoreData
import CoreLocation
import Eureka

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON

class addSpotViewController2: FormViewController, CLLocationManagerDelegate{
    
    @IBOutlet weak var btnCance2SpotList: UIBarButtonItem!
    @IBOutlet weak var btnCancel2Details: UIBarButtonItem!
    
    // MARK: - Properties
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    // Create a reference to the Phone Location Manager
    let locationManager = CLLocationManager()
    
    // Accessory for Registration keyboard
    let toolbar = addSpot_ToolbarSubClass()
    
    // Values for data passed in by segue from Details View
    var inRegistration: String! = ""
    var inTypeSeries: String! = ""
    
    var nearestLocation = ""
    
    var returnSpot: infoSpot = infoSpot(inStatus: spotStatus.Placeholder)
    
    // Instantiate registration validator
    let rv = registrationValidator()
    
    // Value of registration field from Eureka form
    var frmRegValue: String!
    
    // MARK: - Load

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create form using Eureka
        setupForm()
        
        // MARK: - Location Services
        
        // Setup the Phone Location Manager
        locationManager.requestAlwaysAuthorization()
        
        // Test for Location Services turned on
        if CLLocationManager.locationServicesEnabled() {
            
            // Assign delegate
            locationManager.delegate = self
            
        }
        
        // Test for access to Location Services authorised
        switch CLLocationManager.authorizationStatus()
        {
        case .authorizedAlways, .authorizedWhenInUse:
            
            locationManager.startMonitoringSignificantLocationChanges()
            
            // Ask Location Manager for latest location
            locationManager.requestLocation()
            
        case .restricted, .denied:
            
            showAlert(inTitle: "iACDB", inMessage: "Turn on Location Services to match nearest airfield", inViewController: self)
        default:
            break
            
        }
        
        // MARK: - Cancel Buttons
        
        // Setup Cancel buttons
        
        // Change title of btn from IB value
        btnCancel2Details.title = "Cancel"
        
        // Hide one of the buttons - they unwind segue to different view controllers
        if inRegistration != "" {
            
            self.navigationItem.rightBarButtonItems![0].title = ""
        }else{
            self.navigationItem.rightBarButtonItems![1].title = ""
        }
        
        // MARK: - Custom Keyboard Bar
        
        // Add custom accessory on top of system keyboard for Registration field
        
        toolbar.barStyle = UIBarStyle.default
        toolbar.sizeToFit()
        
        let dashButton = UIBarButtonItem(title: "\"-\"", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.dashButtonTapped(button:)))
        dashButton.width = 75
        
        let plusButton = UIBarButtonItem(title: "\"+\"", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.plusButtonTapped(button:)))
        plusButton.width = 75
        
        let gDashButton = UIBarButtonItem(title: "\"G-\"", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.gDashButtonTapped(button:)))
        gDashButton.width = 75
        
        toolbar.setItems([dashButton, plusButton, gDashButton], animated: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Get aircraft details if not empty
        if let reg = inRegistration {
            
            self.getAircraftDetails(reg: reg)
            
        }
        
    }
    
    // Do the preparation for showing the next view (going forwards)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier!
        {
            
        // Unwind segue from Add button to Spot List adding spot
        case "btnAdd2SpotList":
            
            let frmValues = getFormValues()
            var errorCheck = false
            
            let regText = frmValues["frmRegistration"] as! String
            
            // Error checking
            
            if (regText == "") { errorCheck = true }
            
            // MARK: - Validation
            
            // Perform validation if switched on
            if defaults.bool(forKey: "validateRegistrations") {
                
                let validatedReg = rv.validateRegistration(unvRegistration: regText) as _ICAOValidationResult
                returnSpot.setRegistration(inRegistration: validatedReg.vReturn)
                
                // Reg fails validation so error's - except when  reg field is blank
                if (validatedReg.vValid == false && regText != "")
                {
                    errorCheck = true
                    
                    showAlert(inTitle: "iACDB Error", inMessage: "Invalid registration", inViewController: self)
                }
                
            }else{
                // Use unvalidated registration
                returnSpot.setRegistration(inRegistration: regText)
            }
            
            // If errors are false update status so it gets added as a spot
            if (errorCheck == false)
            {
                // Add data from fields to Spot
                returnSpot.setLocation(inLocation: frmValues["frmLocation"] as! String)
                returnSpot.setName(inName: defaults.string(forKey: "name")!)
                
                // Empty fields from Eureka forms return nil so check
                if let notes = frmValues["frmNotes"] as? String
                {
                    if !notes.isEmpty { returnSpot.setNotes(inNotes: notes) }
                }
                
                // Add Spot to CoreData
                saveSpot(spot: returnSpot)
                
                // Move status to 'Waiting' which triggers upload to server
                returnSpot.setStatus(inStatus: .Waiting)
            }
            
        // Unwind segue to Spot List from Cancel button
        case "btnCancel2SpotList": break
            // Do nothing
            
        case "btnCancel2Details": break
            // Do nothing
            
        default: break
            // Do nothing
        }
    }
    
    // Function to add dash character to Registration field when accessoryView tapped
    @objc func dashButtonTapped(button:UIBarButtonItem) {
        
       editFrmRegistration(newValue: "-")
        UIDevice.current.playInputClick()
    }
    
    // Function to add plus character to Registration field when accessoryView tapped
    @objc func plusButtonTapped(button:UIBarButtonItem) {
        
        editFrmRegistration(newValue: "+")
        UIDevice.current.playInputClick()
    }
    
    // Function to add G- characters to Registration field when accessoryView tapped
    @objc func gDashButtonTapped(button:UIBarButtonItem) {
        
        editFrmRegistration(newValue: "G-")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: - Form
    func setupForm()
    {
        // Create sections and rows for Eureka form
        form
            +++ Section("Spot")
        
                // Registration
            <<< TextRow() {row in
                row.title = "Registration"
                row.placeholder = "Registration"
                row.tag = "frmRegistration"
                
                // Populate registration if passed in
                row.value = inRegistration
                row.cell.textField.becomeFirstResponder()
                }.onChange { row in
                    
                    // Get aircraft details if not empty
                    if let reg = row.value {
                        
                        self.getAircraftDetails(reg: reg)
                    }
                    
                }.cellUpdate {cell, row in
                    
                    // Customise behaviour for the registration text box
                    cell.textField.autocapitalizationType = .allCharacters              // All capitals
                    cell.textField.autocorrectionType = UITextAutocorrectionType.no     // No predictive text
                    cell.textField.inputAccessoryView = self.toolbar                    // Custom keyboard accessory bar for registrations
                }
            
                // Date
            <<< DateRow() {
                $0.title = "Date"
                $0.value = Date()
                $0.maximumDate = Date()
                $0.tag = "frmDate"
                }.cellUpdate {cell, row in
                    
                    // Set style of date display after any updates
                    row.dateFormatter?.locale = Locale(identifier: "en_GB")
                    row.dateFormatter?.dateStyle = .short
                    
                }.cellSetup {cell, row in
                    
                    // Set style of date picker and display on initial load
                    cell.datePicker.locale = Locale(identifier: "en_GB")
                    row.dateFormatter?.locale = Locale(identifier: "en_GB")
                    row.dateFormatter?.dateStyle = .short
                }
        
                // Locations
            <<< PickerInputRow<String>(){
                $0.title = "Location"
                
                // Load picker with locations
                $0.options = getLocationPickerData()
                
                $0.value = $0.options.first
                $0.tag = "frmLocation"
                }
            
            +++ Section("Notes")
            
            <<< TextAreaRow() {
                $0.title = "Notes"
                $0.placeholder = ""
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
                $0.tag = "frmNotes"
            }
            
            +++ Section("Details")
            
                // Type
            <<< LabelRow() {
                $0.title = "Type"
                $0.value = ""
                $0.tag = "frmType"
                }
            
                // Operator
            <<< LabelRow() {
                $0.title = "Operator"
                $0.value = ""
                $0.tag = "frmOperator"
                }
        
        // Enables smooth scrolling on navigation to off-screen rows
        animateScroll = true
        // Leaves 20pt of space between the keyboard and the highlighted row after scrolling to an off screen row
        rowKeyboardSpacing = 20
        

    }
    
    // Function to extract values from the form
    func getFormValues() -> [String:Any?]
    {
        //Gets the values of all rows which have a tag assigned as tag:value dictionary
        let formValuesDictionary = form.values()
        
        return formValuesDictionary
        
    }
    
    // Function to update form registration value
    func editFrmRegistration(newValue: String)
    {
        // Get row
        let row = self.form.rowBy(tag: "frmRegistration") as! TextRow
        
        if let _ = row.cell.textField.text {
            
            row.cell.textField.text? += newValue
            
        }else{
            
            row.cell.textField.text = newValue
            
        }
    }
    
    // MARK: - CoreData
    
    // Function to get locations list from CoreData and return an array
    func getLocationPickerData() -> [String]
    {
        // Get the container from the AppDelegate
        let moc = getContext()
        
        let entity = "EntLocations"
        
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "location", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Array to hold return values
        var returnedLocations: [String] = []
        
        do {
            // Execute Fetch Request
            let records = try moc.fetch(fetchRequest) as! [EntLocations]
            
            for record in records {
                
                returnedLocations.append(record.location!)
            }
            
        } catch {
            rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for entity \(entity).")
        }
        
        return returnedLocations
        
    }
    
    func getAircraftDetails(reg: String) {
        
        if !self.defaults.bool(forKey: "showAircraftDetails") { return }
        
        // Get the details from the cache if exists
        let aircraftDetails = getAircraftDetailsFromCache(inRegistration: reg)
        
        // Update the fields if valid or clear
        if !aircraftDetails.acType.isEmpty {
            
            let rowT = self.form.rowBy(tag: "frmType") as! LabelRow
            rowT.cell.textLabel?.text = aircraftDetails.acType + "-" + aircraftDetails.acSeries
            //rowT.updateCell()
            
            let rowO = self.form.rowBy(tag: "frmOperator") as! LabelRow
            rowO.cell.textLabel?.text = aircraftDetails.acOperator
            //rowO.updateCell()
            
        }else{
            
            let rowT = self.form.rowBy(tag: "frmType") as! LabelRow
            rowT.cell.textLabel?.text = ""
            
            let rowO = self.form.rowBy(tag: "frmOperator") as! LabelRow
            rowO.cell.textLabel?.text = ""
        }
    }
    
    // MARK: - Location Manager delegates
    
    // Called every time the Location Manager notifys a location change
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        
        guard let locValue:CLLocationCoordinate2D = manager.location?.coordinate else {
            
            return
        }
        
        rwPrint(inFunction: #function, inMessage:"locations = \(locValue.latitude) \(locValue.longitude)")
        
        // Get the nearest location in the DB to the device's geo position
        nearestLocation = getNearestLocation(inLocation: locations[0])
        
        // Set the form value if other than an empty string is returned
        if !nearestLocation.isEmpty {
            
            let rowP = form.rowBy(tag: "frmLocation") as! PickerInputRow<String>
            rowP.value = self.nearestLocation
            rowP.updateCell()
            
        }
        
    }
    
    // Called if a Location Manager fails
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        rwPrint(inFunction: #function, inMessage:"Error while updating location " + error.localizedDescription)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
