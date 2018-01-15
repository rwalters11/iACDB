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
import Kingfisher

class aircraftDetailsViewController: UIViewController, UISearchBarDelegate, UITextViewDelegate
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
        
        // Set textView delegate
        txtViewNotes.delegate = self
        
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
                    
                    if notesResult.count > 0 {
                        
                        // Display the Notes
                        txtViewNotes.text = notesResult[0].notes
                    }
                
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
        
        if (segue.identifier == "AddSpotFromACDetails")
        {
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
    
    // Do updates after editing Notes textView
    func textViewDidEndEditing(_ textView: UITextView) {
        
        let notes4Spot: infoSpot = infoSpot(inRegistration: inRegistration)
        
        notes4Spot.setNotes(inNotes: txtViewNotes.text)
        
        updateSpot(inSpot: notes4Spot)
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
            // Make sure search string is properly escaped
            let expectedCharSet = NSCharacterSet.urlQueryAllowed
            let searchTerm = aircraft.acRegistration?.addingPercentEncoding(withAllowedCharacters: expectedCharSet)
            
            // Set destination url & value to send including requested image width
            let url = URL(string: "http://tbgweb.dyndns.info/iacdb/iosGetLatestImage.php?registration=" + searchTerm! + "&w=500")!
            
            // Setup Kingfisher Image Cacheing & retrieval resource using aircraft registration as the cache key
            let resource = ImageResource(downloadURL: url, cacheKey: aircraft.acRegistration! + "w500")
            
            // Display the image with loading indicator and corner radius
            let processor = RoundCornerImageProcessor(cornerRadius: 5)
            
            self.imgAircraft?.kf.indicatorType = .activity
            self.imgAircraft?.kf.setImage(with: resource, placeholder: nil, options: [.processor(processor)])
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

