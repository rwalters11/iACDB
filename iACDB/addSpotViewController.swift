//
//  addSpotViewController.swift
//  iACDB
//
//  Created by Richard Walters on 14/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//

// Import Apple frameworks
import UIKit
import CoreData
import CoreLocation

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON

class addSpotViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate, getCameraReturnProtocol  {
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    // Create a reference to the Phone Location Manager
    let locationManager = CLLocationManager()
    
    // Value for string passed in by segue from Details View
    var inRegistration: String!
    
    var nearestLocation = ""
    
    var returnSpot: infoSpot = infoSpot(inStatus: spotStatus.Placeholder)
    
    // Holder for value passed back from getCameraView
    var regFromCamera: String?
    
    @IBAction func btnCamera(_ sender: Any)
    {
        self.performSegue(withIdentifier: "getImage4Reg", sender: nil)
    }
    
    @IBOutlet weak var txtRegistration: UITextField!
    @IBOutlet weak var swShowDetails:   UISwitch!
    @IBOutlet weak var txtLocation:     UITextField!
    @IBOutlet weak var lblTypeSeries:   UILabel!
    @IBOutlet weak var lblOperator:     UILabel!
    @IBOutlet weak var locationPicker:  UIPickerView!
    @IBOutlet weak var txtNotes:        UITextView!
    
    static var locationPickerData: [String]=[String]()
    
    // Registration field text changes
    @IBAction func txtRegistrationChange(_ sender: UITextField) {
            
            getAircraftDetails()
    }
    
    // Focus moves away from Registration field
    @IBAction func txtRegistration(_ sender: Any) {
        
        let regText: String? = txtRegistration.text
        var errorCheck = false
        
        // Remove focus from registration field
        txtRegistration.resignFirstResponder()
        
        // Error checking
        
        if (regText?.isEmpty)! { errorCheck = true }
        
        // MARK: - Validation
        
        // Perform validation if switched on
        if defaults.bool(forKey: "validateRegistrations") {
        
            let validatedReg = rv.validateRegistration(unvRegistration: regText!) as _ICAOValidationResult
            returnSpot.setRegistration(inRegistration: validatedReg.vReturn)
            
            // Reg fails validation so error's - except when  reg field is blank
            if (validatedReg.vValid == false && regText?.isEmpty == false)
            {
                errorCheck = true
                
                showAlert(inTitle: "iACDB Error", inMessage: "Invalid registration", inViewController: self)
            }
            
        }else{
            // Use unvalidated registration
            returnSpot.setRegistration(inRegistration: regText!)
        }
        
        // If errors are false update status so it gets added as a spot
        if (errorCheck == false)
            {
                // Add location and user name to Spot
                returnSpot.setLocation(inLocation: txtLocation.text!)
                returnSpot.setName(inName: defaults.string(forKey: "name")!)
                
                // Move status on to show ready for further processing
                 returnSpot.setStatus(inStatus: .Waiting)
                
                // Add Spot to CoreData
                saveSpot(spot: returnSpot)
        }
    }
    
    // Handle Switch changes by user
    @IBAction func swShowDetailsChange(_ sender: UISwitch) {
        
        if swShowDetails.isOn == true {
            
            getAircraftDetails()
            
        }else{
            
            lblTypeSeries.text = ""
            lblOperator.text = ""
        }
        
        // Save the setting of the switch
        defaults.set(sender.isOn, forKey: "showAircraftDetails")
    }
    
    // Instantiate registration validator
    let rv = registrationValidator()
    
    override func viewDidLoad()
    {
        
        super.viewDidLoad()
        
        swShowDetails.setOn(defaults.bool(forKey: "showAircraftDetails"), animated: true)
        
        let color = UIColor.lightGray.cgColor
        txtNotes.layer.borderColor = color
        txtNotes.layer.borderWidth = 0.5
        txtNotes.layer.cornerRadius = 5
        
        // Hide the pickerView
        locationPicker.isHidden = true
        
        // Connect data
        locationPicker.delegate=self
        locationPicker.dataSource=self
        
        txtLocation.delegate = self
        //txtLocation.inputView = locationPicker
        
        txtRegistration.delegate = self
        
        txtRegistration.returnKeyType = .done
        
        self.txtNotes.isEditable = false
        
        // Populate picker with list of valid locations from the CoreData cache
        
            // Clear existing array
            addSpotViewController.locationPickerData.removeAll()
        
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
                
                    addSpotViewController.locationPickerData.append(record.location!)
                }
            
            } catch {
                rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for entity \(entity).")
            }
        
            self.locationPicker.reloadAllComponents()
        
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
        
        // Set focus to Registration field
        txtRegistration.becomeFirstResponder()
        
        // Populate the Registration field if value passed in
        guard inRegistration == nil else {
            
            txtRegistration.text = inRegistration
            
            // Remove focus from registration field
            txtRegistration.resignFirstResponder()
            
            getAircraftDetails()
            
            return
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Override the nearest location to use the current location in use (usually the last used) if the 'Use Nearest Location' setting is false
        
        if self.defaults.bool(forKey: "useNearestLocation") { return }
        
        // Get the current location (if set)
        let currentLocation = getCurrentLocation()
        
        if (!(txtLocation.text?.isEmpty)!) {
        
            setPicker2Index(inLocation: currentLocation, sender: "Did Appear")
        }
        
        // Set focus to Registration field
        txtRegistration.becomeFirstResponder()
    }
    
    // Delegate function for passing back data from getCameraView
    func setCameraRegistration(valueSent: String)
    {
        // Set the registration field to the return value from the camera
        txtRegistration.text = valueSent
    }
    
    // Do the preparation for showing the next view (going forwards)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier!
        {
            
        case "getImage4Reg":
            
            // Setup the delegation for the return of data from the camera View
            let svc = segue.destination as! getCameraViewController
            svc.delegate = self
            
            // Set the custom value of the Back Item text to be shown in the details view
            let backItem = UIBarButtonItem()
            backItem.title = "Scan"
            navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
            
        default: break
            // Do nothing
        }
    }
    
    // MARK: - Location Manager delegates
    
    // Called every time the Location Manager notifys a location change
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        rwPrint(inFunction: #function, inMessage:"locations = \(locValue.latitude) \(locValue.longitude)")
        
        // Get the nearest location in the DB to the device's geo position
        nearestLocation = getNearestLocation(inLocation: locations[0])
        
        // Set the picker if other than an empty string is returned
        if !nearestLocation.isEmpty {
            
            self.setPicker2Index(inLocation: self.nearestLocation, sender: "Location update")
        }
        
    }
    
    // Called if a Location Manager fails
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        rwPrint(inFunction: #function, inMessage:"Error while updating location " + error.localizedDescription)
    }
    
    /*
     *
     * Function to set the pickerView to a matching location
     *
     */
    func setPicker2Index(inLocation: String, sender: String) {
        
        // Check for empty string
        if inLocation.isEmpty { return }
        
        // Get the index of array element matching the current location
        let locationIndex = addSpotViewController.locationPickerData.index(of: inLocation)
        
        // Test for no match
        if locationIndex != nil {
            
            // Set the picker
            locationPicker.selectRow(locationIndex!, inComponent: 0, animated: true)
        }
        
        // Set the location text field
        DispatchQueue.main.async{
            
            self.txtLocation.text = inLocation
        }
        
        rwPrint(inFunction: #function, inMessage: sender)
    }
    
    // MARK: - PickerView delegates
    
    // The number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return addSpotViewController.locationPickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return addSpotViewController.locationPickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        txtLocation.text = addSpotViewController.locationPickerData[row]
        //locationPicker.isHidden = true
    }
    
    // MARK: - UITextField Delegates
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        textField.resignFirstResponder()
        
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        switch textField.tag {
            
            // Registration
            case 1:
                locationPicker.isHidden = true
            
            // Location
            case 2:
                locationPicker.isHidden = false
            
            
            default: break
        }
        
        return true;
    }
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        return true;
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        switch textField.tag {
            
        // Registration
        case 1:
            
            // Get & display the aircraft details if selected
            getAircraftDetails()
            
        // Location
        case 2:
            
            locationPicker.isHidden = true
            
        default: break
        }
        
        textField.resignFirstResponder()
        return true;
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        return true;
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        locationPicker.isHidden = true
        textField.resignFirstResponder()
        return true
    }
    
    func getAircraftDetails() {
        
        if !self.defaults.bool(forKey: "showAircraftDetails") { return }
        
        // Get the details from the cache if exists
        let aircraftDetails = getAircraftDetailsFromCache(inRegistration: txtRegistration.text!)
        
        // Update the fields if valid or clear
        if !aircraftDetails.acType.isEmpty {
        
            lblOperator.text = aircraftDetails.acOperator
            lblTypeSeries.text = aircraftDetails.acType + "-" + aircraftDetails.acSeries
        }else{
            lblOperator.text = ""
            lblTypeSeries.text = ""
        }
    }
    

}
