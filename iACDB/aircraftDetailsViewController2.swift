//
//  aircraftDetailsViewController2.swift
//  iACDB
//
//  Created by Richard Walters on 04/02/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//
// Version 2
// Using Eureka library as base for form.

// Import Apple frameworks
import UIKit
import CoreData
import CoreLocation

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON
import Kingfisher
import Eureka

class aircraftDetailsViewController2: FormViewController{
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    // Accessory for Registration keyboard
    let toolbar = addSpot_ToolbarSubClass()
    
    // Unwind segue from Add Spot Screen - Cancel
    @IBAction func btnCancelFromAddSpot2Details(segue: UIStoryboardSegue) {
        
    }
    
    // Values passed in by segue
    var inRegistration: String!
    var inMenuSpot: Bool = true
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create form using Eureka
        setupForm()
        
        // Set title
        self.navigationItem.title = inRegistration
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Form
    func setupForm()
    {
        // Get the details from the cache if exists
        let aircraftDetails = getAircraftDetailsFromCache(inRegistration: inRegistration)
        
        // Create sections and rows for Eureka form
        form
            +++ Section("Aircraft")
            
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
                        
                        self.navigationItem.title = row.value
                    }
                    
                }.cellUpdate {cell, row in
                    
                    // Customise behaviour for the registration text box
                    cell.textField.autocapitalizationType = .allCharacters              // All capitals
                    cell.textField.autocorrectionType = UITextAutocorrectionType.no     // No predictive text
                    cell.textField.inputAccessoryView = self.toolbar                    // Custom keyboard accessory bar for registrations
            }
            
            // Type
            <<< TextRow() {
                $0.title = "Type"
                $0.value = aircraftDetails.acType
                $0.tag = "frmType"
            }
            
            // Series
            <<< TextRow() {
                $0.title = "Series"
                $0.value = aircraftDetails.acSeries
                $0.tag = "frmSeries"
            }
            
            // Operators
            <<< PickerInputRow<String>(){
                $0.title = "Operator"
                
                // Load picker with locations
                $0.options = getOperatorPickerData()
                
                //$0.value = $0.options.first
                $0.value = aircraftDetails.acOperator
                $0.tag = "frmOperator"
            }
            
            // Delivery
            <<< DateRow() {
                $0.title = "Delivery"
                $0.value = Date()
                $0.maximumDate = Date()
                $0.tag = "frmDelivery"
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
            
            // Constructor
            <<< TextRow() {
                $0.title = "Constructor"
                $0.value = ""
                $0.tag = "frmConstructor"
            }
            
            // Fuselage
            <<< TextRow() {
                $0.title = "Fuselage"
                $0.value = ""
                $0.tag = "frmFuselage"
            }
            
            +++ Section("Remarks")
            
            <<< TextAreaRow() {
                $0.title = "Remarks"
                $0.placeholder = ""
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
                $0.tag = "frmRemarks"
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
    
    // MARK: - Navigation

     // Do the preparation for showing the next view
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     
     if (segue.identifier == "showAddSpotFromDetails")
         {
         // Set the class of the details View controller
         let svc = segue.destination as! addSpotViewController2
         
         // Pass the registration to the Add Spot view
         svc.inRegistration = inRegistration
         ////svc.inTypeSeries = self.lblTypeSeries.text
         
         // Set the custom value of the Back Item text to be shown in the Add Spot view
         let backItem = UIBarButtonItem()
         backItem.title = "Add"
         navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
         }
    }
    
    // MARK: - CoreData
    
    // Function to get locations list from CoreData and return an array
    func getOperatorPickerData() -> [String]
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
            
            let rowT = self.form.rowBy(tag: "frmType") as! TextRow
            rowT.cell.textField?.text = aircraftDetails.acType
            
            let rowS = self.form.rowBy(tag: "frmSeries") as! TextRow
            rowS.cell.textField?.text = aircraftDetails.acSeries
            
            ////let rowO = self.form.rowBy(tag: "frmOperator") as! PickerInputRow
            ////rowO.cell.textLabel?.text = aircraftDetails.acOperator
            
        }else{
            
            let rowT = self.form.rowBy(tag: "frmType") as! TextRow
            rowT.cell.textField?.text = ""
            
            let rowS = self.form.rowBy(tag: "frmSeries") as! TextRow
            rowS.cell.textField?.text = ""
            
            ////let rowO = self.form.rowBy(tag: "frmOperator") as! PickerInputRow
            ////rowO.cell.textLabel?.text = ""
        }
    }
    
    // Function to compile and display the aircraft details - may be more than 1 aircraft with same registration !!
    func showAircraftData(acDetails: [EntAircraft]) {
        
        let aircraft = acDetails[0]
        
        ////lblTypeSeries.text = aircraft.acType! + "-" + aircraft.acSeries!
        
        // Make call to server if current image is nil and image available for registration
        if aircraft.acImageAvailable
        {
            // Make sure search string is properly escaped
            let expectedCharSet = NSCharacterSet.urlQueryAllowed
            let searchTerm = aircraft.acRegistration?.addingPercentEncoding(withAllowedCharacters: expectedCharSet)
            
            // Set destination url & value to send including requested image width
            let url = URL(string: "https://tbgweb.dyndns.info/iacdb/iosGetLatestImage.php?registration=" + searchTerm! + "&w=500")!
            
            // Setup Kingfisher Image Cacheing & retrieval resource using aircraft registration as the cache key
            let resource = ImageResource(downloadURL: url, cacheKey: aircraft.acRegistration! + "w500")
            
            // Display the image with loading indicator and corner radius
            let processor = RoundCornerImageProcessor(cornerRadius: 5)
            
            ////self.imgAircraft?.kf.indicatorType = .activity
            ////self.imgAircraft?.kf.setImage(with: resource, placeholder: nil, options: [.processor(processor)])
        }
    }

}
