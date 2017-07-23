//
//  locationDetailViewController.swift
//  iACDB
//
//  Created by Richard Walters on 06/01/2017.
//  Copyright © 2017 Richard Walters. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class locationDetailViewController: UIViewController, MKMapViewDelegate {
    
    // Create a reference to the Phone Location Manager
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    
    // Holder for value passed in by segue
    var inLocation: String = ""
    
    var mLatitude: Double = 0
    var mLongitude: Double = 0
    
    // Seup our User Defaults instance
    //let defaults = tbgUserDefaults.sharedInstance
    let defaults = UserDefaults.standard
    
    var zoomState: Bool = false
    
    @IBOutlet weak var btnZoom: UIBarButtonItem!
    @IBAction func btnZoom(_ sender: UIBarButtonItem) {
        
        // Toggle the zoom in/out
        zoom2Location(latitude: mLatitude, longitude: mLongitude)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Phone Location Manager
        locationManager.requestAlwaysAuthorization()
        
        // Test for Location Services turned on
        if CLLocationManager.locationServicesEnabled() {
            
            // Assign delegate
            locationManager.delegate = self as? CLLocationManagerDelegate
            
        }
        
        mapView.delegate = self
        
        // Test for ""
        if !inLocation.isEmpty {
            
            // Set the title
            self.navigationItem.title = inLocation

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
                    
                    showLocationData(location: result[0])
                }
                
                
                
            }catch let error as NSError {
                rwPrint(inFunction: #function, inMessage:"Unable to perform fetch of Locations: \(error.localizedDescription)")
            }
            
            // Allow the map to show the device location
            mapView.showsUserLocation = true
            
        }
    
    }

    func showLocationData(location: EntLocations) {
        
        // Extract lat/long
        let latitude = location.latitude
        let longitude = location.longitude
        
        // Set lat/long at class level
        mLatitude = Double(latitude)
        mLongitude = Double(longitude)
        
        var region = MKCoordinateRegion()
        
        // Set the centre lat/long of the map region
        region.center.latitude = CLLocationDegrees(latitude)
        region.center.longitude = CLLocationDegrees(longitude)
        
        // Set the dimensions of the mapView in degrees lat/long - 1 deg = 111km
        region.span.latitudeDelta = 1
        region.span.longitudeDelta = 1
        
        // Update the map
        mapView.setRegion(region, animated: true)
        
        // Display a pin on the map showing the location centre
        let pin = MKPointAnnotation()
        let pinCentre = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
        // Set the pin coordinates
        pin.coordinate = pinCentre
        
        // Add the pin to the map
        mapView.addAnnotation(pin)
        
    }
    
    // Function to set the map to a zoomed-in location
    func zoom2Location(latitude: Double, longitude: Double) {
        
        var region = MKCoordinateRegion()
        
        // Set the map centre
        region.center.latitude = CLLocationDegrees(latitude)
        region.center.longitude = CLLocationDegrees(longitude)
        
        // Toggle map zoom in/out
        switch zoomState  {
            
            case false:
            
                // Set the dimensions of the map in degrees - 1 deg = 111km
                region.span.latitudeDelta = 0.1
                region.span.longitudeDelta = 0.1
            
                btnZoom.title = "Zoom Out"
                zoomState = true
            
            case true:
            
                // Set the dimensions of the map in degrees - 1 deg = 111km
                region.span.latitudeDelta = 1
                region.span.longitudeDelta = 1
            
                btnZoom.title = "Zoom In"
                zoomState = false
            
    }
        // Update the map
        mapView.setRegion(region, animated: true)
        
    }
    
    // MARK:  - Map View delegates
    
    // Called when map notify's a change in the device location
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        switch segue.identifier!
        {
            
        case "addEditFromDetailLocationSegue":
            
            // Set the class of the addSpot View controller
            if let svc = segue.destination as? addEditLocationViewController {

                // Pass Location to details view
                svc.inLocation = inLocation
                
                
            }
            
        default: break
            // Do nothing
        }
        
        // Set the default value of the Back Item text to be shown in next view
        let backItem = UIBarButtonItem()
        backItem.title = "Save"
        navigationItem.backBarButtonItem = backItem
        
    }


}
