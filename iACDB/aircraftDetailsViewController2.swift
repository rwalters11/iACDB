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
import Foundation
import UIKit
import CoreData
import CoreLocation

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON
import Kingfisher
import Eureka
import ImageRow

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
    
    var formDisabled: Condition = true
    
    var inMenuSpot: Bool = true
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the details from the cache if exists
        let aircraftDetails = getAircraftDetailsFromCache(inRegistration: inRegistration)

        // Create form using Eureka
        setupForm(aircraftDetails: aircraftDetails)
        
        getAircraftImage(aircraft: aircraftDetails)
        
        // Set title
        self.navigationItem.title = inRegistration
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Eureka Form Functions
    func setupForm(aircraftDetails: infoAircraft)
    {
        // Create sections and rows for Eureka form
        form
            +++ Section("Aircraft Details")
            
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
            
            // Image
            <<< ImageRow() { row in
                row.tag = "frmImage"
                }.cellUpdate { cell, row in
                    //cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height)
                    
                }.cellSetup({ (cell, row) in
                    row.cell.height = {
                        return 200
                    }
                })
            
            // Type
            <<< PickerInputRow<String>(){ row in
                row.title = "Type"
                
                // Load picker with Types
                row.options = getTypesPickerData()
                
                row.value = aircraftDetails.acType
                row.tag = "frmType"
                row.reload()
            }
            
            // Series
            <<< TextRow() {
                $0.title = "Series"
                $0.value = aircraftDetails.acSeries
                $0.tag = "frmSeries"
                }.cellUpdate {cell, row in
                    
                    // Customise behaviour for the registration text box
                    cell.textField.autocapitalizationType = .allCharacters              // All capitals
                    cell.textField.autocorrectionType = UITextAutocorrectionType.no     // No predictive text
            }
            
            // Operators
            <<< PickerInputRow<String>(){
                $0.title = "Operator"
                
                // Load picker with locations
                $0.options = getOperatorPickerData()
                
                $0.value = aircraftDetails.acOperator
                $0.tag = "frmOperator"
                $0.reload()
                
            }
            
            // Delivery
            <<< DateRow() {
                $0.title = "Delivery"
                
                // Test for nil return from conversion
                if let deliveryDate = ConvertACDB_Date(inDate: aircraftDetails.acDelivery)
                {
                    $0.value = deliveryDate
                }
                
                $0.maximumDate = Date()
                $0.tag = "frmDelivery"
                }.cellUpdate {cell, row in
                    
                    // Set style of date display after any updates
                    row.dateFormatter?.locale = Locale(identifier: "en_GB")
                    row.dateFormatter?.dateFormat = "MM/yy"
                    
                }.cellSetup {cell, row in
                    
                    // Set style of date picker and display on initial load
                    cell.datePicker.locale = Locale(identifier: "en_GB")
                    row.dateFormatter?.locale = Locale(identifier: "en_GB")
                    row.dateFormatter?.dateFormat = "MM/yy"
            }
            
            // Constructor
            <<< TextRow() {
                $0.title = "Constructor"
                $0.value = aircraftDetails.acConstructor
                $0.tag = "frmConstructor"
                }.cellUpdate {cell, row in
                    
                    // Customise behaviour for the registration text box
                    cell.textField.autocapitalizationType = .allCharacters              // All capitals
                    cell.textField.autocorrectionType = UITextAutocorrectionType.no     // No predictive text
            }
            
            // Fuselage
            <<< TextRow() {
                $0.title = "Fuselage"
                $0.value = aircraftDetails.acFuselage
                $0.tag = "frmFuselage"
                }.cellUpdate {cell, row in
                    
                    // Customise behaviour for the registration text box
                    cell.textField.autocapitalizationType = .allCharacters              // All capitals
                    cell.textField.autocorrectionType = UITextAutocorrectionType.no     // No predictive text
            }
            
            // Mode S
            <<< TextRow() {
                $0.title = "Mode S"
                $0.value = aircraftDetails.acModeS
                $0.tag = "frmModeS"
                }.cellUpdate {cell, row in
                    
                    // Customise behaviour for the registration text box
                    cell.textField.autocapitalizationType = .allCharacters              // All capitals
                    cell.textField.autocorrectionType = UITextAutocorrectionType.no     // No predictive text
            }
            
            +++ Section("Remarks")
            
            <<< TextAreaRow("Remarks") {
                $0.title = "Remarks"
                $0.placeholder = ""
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
                $0.tag = "frmRemarks"
        }
        
        // Enables smooth scrolling on navigation to off-screen rows
        animateScroll = true
        // Leaves 20pt of space between the keyboard and the highlighted row after scrolling to an off screen row
        rowKeyboardSpacing = 20
        
        enableFormFields(inSetting: formDisabled)
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
    
    // Function to get Operators list from CoreData and return an array
    func getOperatorPickerData() -> [String]
    {
        // Get the container from the AppDelegate
        let moc = getContext()
        
        let entity = "EntOperators"
        
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "acOperator", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Array to hold return values
        var returnedOperators: [String] = []
        
        do {
            // Execute Fetch Request
            let records = try moc.fetch(fetchRequest) as! [EntOperators]
            
            for record in records {
                
                returnedOperators.append(record.acOperator!)
                //print(record.acOperator!)
            }
            
        } catch {
            rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for entity \(entity).")
        }
        
        rwPrint(inFunction: #function, inMessage: "\(String(describing: returnedOperators.count)) operators returned for picker")
        
        return returnedOperators
        
    }
    
    // Function to get Types from CoreData and return an array
    func getTypesPickerData() -> [String]
    {
        // Get the container from the AppDelegate
        let moc = getContext()
        
        let entity = "EntTypes"
        
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "acType", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Array to hold return values
        var returnedTypes: [String] = []
        
        do {
            // Execute Fetch Request
            let records = try moc.fetch(fetchRequest) as! [EntTypes]
            
            for record in records {
                
                returnedTypes.append(record.acType!)
                //print(record.acType!)
            }
            
        } catch {
            rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for entity \(entity).")
        }
        
        rwPrint(inFunction: #function, inMessage: "\(String(describing: returnedTypes.count)) types returned for picker")
        return returnedTypes
    }
    
    // Function to retrieve details of an aircraft from CoreData
    func getAircraftDetails(reg: String) {
        
        if !self.defaults.bool(forKey: "showAircraftDetails") { return }
        
        // Get the details from the cache if exists
        let aircraftDetails = getAircraftDetailsFromCache(inRegistration: reg)
        
        // Update the fields if valid or clear
        if !aircraftDetails.acType.isEmpty {
            
            let rowT = self.form.rowBy(tag: "frmType") as! PickerInputRow<String>
            rowT.value = aircraftDetails.acType
            
            let rowS = self.form.rowBy(tag: "frmSeries") as! TextRow
            rowS.cell.textField?.text = aircraftDetails.acSeries
            
            let rowO = self.form.rowBy(tag: "frmOperator") as! PickerInputRow<String>
            rowO.value = aircraftDetails.acOperator
            
        }else{
            
            let rowT = self.form.rowBy(tag: "frmType") as! PickerInputRow<String>
            rowT.value = aircraftDetails.acType
            
            let rowS = self.form.rowBy(tag: "frmSeries") as! TextRow
            rowS.cell.textField?.text = ""
            
            let rowO = self.form.rowBy(tag: "frmOperator") as! PickerInputRow<String>
            rowO.value = ""
        }
    }
    
    // Function to compile and display the aircraft details - may be more than 1 aircraft with same registration !!
    func getAircraftImage(aircraft: infoAircraft) {
        
        let rowImage = self.form.rowBy(tag: "frmImage") as! ImageRow
        
        // Make call to server if current image is nil and image available for registration
        if aircraft.acImageAvailable
        {
            // Make sure search string is properly escaped
            let expectedCharSet = NSCharacterSet.urlQueryAllowed
            let searchTerm = aircraft.acRegistration.addingPercentEncoding(withAllowedCharacters: expectedCharSet)
            
            // Set destination url & value to send including requested image width
            let url = URL(string: "https://tbgweb.dyndns.info/iacdb/iosGetLatestImage.php?registration=" + searchTerm! + "&w=300")!
            
            // Setup Kingfisher Image Cacheing & retrieval resource using aircraft registration as the cache key
            let resource = ImageResource(downloadURL: url, cacheKey: aircraft.acRegistration + "w300")
            
            // Display the image with loading indicator and corner radius
            let processor = RoundCornerImageProcessor(cornerRadius: 5)
            
            let image = UIImage(named: "Updating")
            
            rowImage.baseCell.imageView?.kf.indicatorType = .activity
            rowImage.baseCell.imageView?.kf.setImage(with: resource, placeholder: image, options: [.processor(processor)], completionHandler: {
                (image, error, cacheType, imageUrl) in
                // image: Image? `nil` means failed
                // error: NSError? non-`nil` means failed
                // cacheType: CacheType
                //                  .none - Just downloaded
                //                  .memory - Got from memory cache
                //                  .disk - Got from disk cache
                // imageUrl: URL of the image
                
                // Test for error
                if let _ = error {
                    
                    rwPrint(inFunction: #function, inMessage: "Image retrieval failed")
                    rwPrint(inFunction: #function, inMessage: (error?.debugDescription)!)
                    
                    rowImage.baseCell.imageView?.kf.indicatorType = .none
                    return
                }
                
                // Test for image returned
                if let _ = image {
                    
                    rwPrint(inFunction: #function, inMessage: "Image retrieved by Kingfisher")
                    
                }else{
                    
                    rwPrint(inFunction: #function, inMessage: "Image not available")
                }
                
                rowImage.baseCell.imageView?.kf.indicatorType = .none
            })
            
        }

    }
    
    // Enable/Disable Eureka form fields
    func enableFormFields(inSetting: Condition)
    {
        // Iterate through form rows setting disabled and forcing evaluation
        for row in self.form.rows {
            row.disabled = inSetting
            row.evaluateDisabled()
        }
    }

}
