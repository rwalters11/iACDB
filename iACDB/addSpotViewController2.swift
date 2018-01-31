//
//  addSpotViewController2.swift
//  iACDB
//
//  Created by Richard Walters on 29/01/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//

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
    
    // MARK: - Properties
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    // Create a reference to the Phone Location Manager
    let locationManager = CLLocationManager()
    
    // Value for string passed in by segue from Details View
    var inRegistration: String!
    
    var nearestLocation = ""
    
    var returnSpot: infoSpot = infoSpot(inStatus: spotStatus.Placeholder)
    
    // Instantiate registration validator
    let rv = registrationValidator()
    
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
        
        // MARK: - Custom Keybaord Bar
        
        // Add custom accessory on top of system keyboard for Registration field
        let toolbar = addSpot_ToolbarSubClass()
        toolbar.barStyle = UIBarStyle.default
        toolbar.sizeToFit()
        
        let dashButton = UIBarButtonItem(title: "\"-\"", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.dashButtonTapped(button:)))
        dashButton.width = 75
        
        let plusButton = UIBarButtonItem(title: "\"+\"", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.plusButtonTapped(button:)))
        plusButton.width = 75
        
        let gDashButton = UIBarButtonItem(title: "\"G-\"", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.gDashButtonTapped(button:)))
        gDashButton.width = 75
        
        toolbar.setItems([dashButton, plusButton, gDashButton], animated: true)
        
        txtRegistration.inputAccessoryView = toolbar
    }
    
    // Function to add dash character to Registration field when accessoryView tapped
    @objc func dashButtonTapped(button:UIBarButtonItem) {
        
        // Dash cannot start an ICAO registration
        if txtRegistration.text?.count == 0 { return }
        
        txtRegistration.text = txtRegistration.text! + "-"
        UIDevice.current.playInputClick()
    }
    
    // Function to add plus character to Registration field when accessoryView tapped
    @objc func plusButtonTapped(button:UIBarButtonItem) {
        
        // Plus cannot start an ICAO or military registration
        if txtRegistration.text?.count == 0 { return }
        
        txtRegistration.text = txtRegistration.text! + "+"
        UIDevice.current.playInputClick()
    }
    
    // Function to add G- characters to Registration field when accessoryView tapped
    @objc func gDashButtonTapped(button:UIBarButtonItem) {
        
        // G- must start an ICAO registration for the UK
        if (txtRegistration.text?.count)! > 0 { return }
        
        txtRegistration.text = txtRegistration.text! + "G-"
        UIDevice.current.playInputClick()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: - Form Setup
    func setupForm()
    {
        // Create sections and rows for Eureka form
        
        form
            +++ Section("Spot")
            <<< TextRow() {
                $0.title = "Registration"
                $0.placeholder = "Registration"
                }
            
            <<< DateRow() {
                $0.title = "Date"
                $0.value = Date()
                $0.maximumDate = Date()
                }
        
            <<< PickerInputRow<String>("Picker Input Row"){
                $0.title = "Location"
                $0.options = []
                for i in 1...10{
                    $0.options.append("location \(i)")
                    }
                $0.value = $0.options.first
                }
            
            +++ Section("Details")
            <<< LabelRow() {
                $0.title = "Type"
                $0.value = "Type"
                }
            
            <<< LabelRow() {
                $0.title = "Operator"
                $0.value = "Operator"
        }    }
    
    // MARK: - CoreData
    func getLocationPickerData()
    {
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
                
                //addSpotViewController.locationPickerData.append(record.location!)
            }
            
        } catch {
            rwPrint(inFunction: #function, inMessage:"Unable to fetch managed objects for entity \(entity).")
        }
        
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
    }    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
