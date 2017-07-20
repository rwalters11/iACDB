//
//  aircraftDetailsViewController.swift
//  iACDB
//
//  Created by Richard Walters on 01/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//

import UIKit
import CoreData

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON

class aircraftDetailsViewController: UIViewController, UISearchBarDelegate
{
    
    @IBOutlet weak var lblRegistration:     UILabel!
    @IBOutlet weak var lblTypeSeries:       UILabel!
    @IBOutlet weak var imgAircraft:         UIImageView!
    @IBOutlet weak var lbl4lblTypeSeries:   UILabel!
    @IBOutlet weak var txtViewNotes:        UITextView!
    
    // Values passed in by segue
    var inRegistration: String!
    var inMenuSpot: Bool = true
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the RH bar button 'Spot' if details shown from existing spot
        if !inMenuSpot {
            
            navigationItem.rightBarButtonItem = nil
            
        }
        
        lblRegistration.text = inRegistration
        
        // Add border to notes field
        let color = UIColor.lightGray.cgColor
        txtViewNotes.layer.borderColor = color
        txtViewNotes.layer.borderWidth = 0.5
        txtViewNotes.layer.cornerRadius = 5
        
        // Test for ""
        if !inRegistration.isEmpty {
            
            // Get context for CoreData
            let moc = getContext()
            
            // Get Aircraft details from CoreData
            
            // Setup NSFetchResultController for table (entity)
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntAircraft")
            
            // Setup sorts
            let fetchSort = NSSortDescriptor(key: "acRegistration", ascending: true)
            fetchRequest.sortDescriptors = [fetchSort]
            
            // Setup predicate
            let predicate = NSPredicate(format: "acRegistration == %@", inRegistration)
            fetchRequest.predicate = predicate
            
            // Perform the fetch
            do {
                // Test for empty array
                if let result = try moc.fetch(fetchRequest) as? [EntAircraft] {
                    
                    // Pass the array to the show function
                    showAircraftData(acDetails: result)
                }
                
            }catch let error as NSError {
                rwPrint(inFunction: #function, inMessage:"Unable to perform fetch of Aircraft details: \(error.localizedDescription)")
            }
            
            // Get Notes from CoreData
            
            // Setup NSFetchResultController for table (entity)
            let notesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntSpots")
            
            // Setup sorts
            let notesFetchSort = NSSortDescriptor(key: "registration", ascending: true)
            notesFetchRequest.sortDescriptors = [notesFetchSort]
            
            // Setup predicate
            let notesPredicate = NSPredicate(format: "registration == %@", inRegistration)
            notesFetchRequest.predicate = notesPredicate
            
            // Perform the fetch
            do {
                // Test for empty array
                if let notesResult = try moc.fetch(notesFetchRequest) as? [EntSpots] {
                    
                    // Display the Notes
                    txtViewNotes.text = notesResult[0].notes
                    
                }
                
            }catch let error as NSError {
                rwPrint(inFunction: #function, inMessage:"Unable to perform fetch of Spot details: \(error.localizedDescription)")
            }
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //moveTextField(txtViewNotes, moveDistance: -250, up: true)
    }
    
    // Do the preparation for showing the next view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "AddSpotFromACDetails") {
            
            // Set the class of the details View controller
            let svc = segue.destination as! addSpotViewController
            
            // Pass the registration to the Add Spot view
            svc.inRegistration = inRegistration!
            
            // Set the custom value of the Back Item text to be shown in the Add Spot view
            let backItem = UIBarButtonItem()
            backItem.title = "Add"
            navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
        }
    }
    
    // Function to compile and display the aircraft details - may be more than 1 aircraft with same registration !!
    func showAircraftData(acDetails: [EntAircraft]) {
        
        // Check for empty array - New A/C
        if acDetails.isEmpty
        {
            // Hide empty fields
            lbl4lblTypeSeries.isHidden = true
            lblTypeSeries.isHidden = true
            imgAircraft.isHidden = true
            
            return
        }
    
        let aircraft = acDetails[0]
        
        lblTypeSeries.text = aircraft.acType! + "-" + aircraft.acSeries!
        
        // Make call to server if current image is nil and image available for registration
        if aircraft.acImageAvailable
        {
            
            // Get image asynchronously from server passing in delegate completion handler to function
            loadImageFromURL(inRegistration: aircraft.acRegistration!, completionHandler: { (imageFromServer) in
                
                // Test for cell
                self.imgAircraft.image = imageFromServer

            })
            
            
        }
    }
    
    // Fetch an aircraft image from theTBGweb server asynchronously using Alamofire/AlamofireImage
    func loadImageFromURL(inRegistration: String, completionHandler: @escaping (UIImage?) -> () ){
        
        // Set default image to be returned
        let defaultImage: UIImage? = nil
        
        let acRegistration = inRegistration
        
        // Make sure search string is properly escaped
        let expectedCharSet = NSCharacterSet.urlQueryAllowed
        let searchTerm = acRegistration.addingPercentEncoding(withAllowedCharacters: expectedCharSet)
        
        // Set destination url & value to send including requested image width
        let url: String = "http://tbgweb.dyndns.info/iacdb/iosGetLatestImage.php"
        let postValues: [String: String] = ["registration": searchTerm!, "w": "500"]
        
        // Request the image from the server
        Alamofire.request(url, method: .get, parameters: postValues)
            .validate()
            .responseImage { response in
                
                debugPrint(response)
                
                // check for errors
                guard response.result.error == nil else {
                    // got an error in getting the data, need to handle it
                    debugPrint("error calling POST on image request")
                    debugPrint(response.result.error!)
                    
                    return
                }
                
                // Check for valid image and return
                guard let responseImage = response.result.value else
                {
                    completionHandler(defaultImage)
                    return
                }
                
                
                // Return to completion handler with image
                completionHandler(responseImage)
        }
        
    }
    
    // Move the text field in a pretty animation!
    func moveTextField(_ textField: UITextView, moveDistance: Int, up: Bool) {
        let moveDuration = 0.3
        let movement: CGFloat = CGFloat(up ? moveDistance : -moveDistance)
        
        UIView.beginAnimations("animateTextField", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(moveDuration)
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
}

