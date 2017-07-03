//
//  getCameraViewController.swift
//  iACDB
//
//  Created by Richard Walters on 02/01/2017.
//  Copyright © 2017 Richard Walters. All rights reserved.
//

import UIKit
import MobileCoreServices

// 3rd Party Librarys
//import TesseractOCR
import SwiftOCR

protocol getCameraReturnProtocol {
    
    func setCameraRegistration(valueSent: String)
}

class getCameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var delegate: getCameraReturnProtocol?
    
    @IBOutlet weak var imageView: UIImageView!
    
    var newMedia: Bool = false
    
    // Instantiate the imagePicker for access to the camera and photo library
    let imagePicker = UIImagePickerController()
    
    //let tesseract = G8Tesseract(language: "eng")
    let swiftOCR = SwiftOCR()
    
    @IBAction func getPhoto(_ sender: UIBarButtonItem) {
        
        showCamera()
    }
    
    @IBAction func libraryPhoto(_ sender: UIBarButtonItem)  {
        
        showPhotoLibrary(sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        self.navigationController?.delegate = self
    
    }
    
    /*
     *
     * Function to show the camera to the User
     *
     */
    func showCamera() {
        
        // Create and display ImagePicker configured for Camera
        // **********************************************************************
        
        // Test if device has a camera and it is available
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .camera
            imagePicker.cameraCaptureMode = .photo
            imagePicker.modalPresentationStyle = .fullScreen
            imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)!
            
            self.present(imagePicker, animated: true, completion: nil)
            
            newMedia = true
            
        }else{
            
            showAlert(inTitle: "iACDB", inMessage: "This device has no suitable camera", inViewController: self)
        }
    }
    
    /*
    *
    * Function to show the Photo Library to the user
    *
    */
    func showPhotoLibrary(sender: UIBarButtonItem) {
        
        // Create and display ImagePicker configured for Photo Library
        // **********************************************************************
        
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        
        // Apple requires iPad Photo Library access to be via a popover
        imagePicker.modalPresentationStyle = .popover
        
        self.present(imagePicker, animated: true, completion: nil)
        
        newMedia = false
        
        // iPad only
        imagePicker.popoverPresentationController?.barButtonItem = sender
    
    }
    
    // MARK: Image Picker delegates
    
    // Called when user selects image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Get the image from the picker
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // Load the imageView
        imageView.contentMode = .scaleAspectFit
        imageView.image = chosenImage
        
        // If picture is new ie from the camera - save it
        if newMedia == true {
        
            UIImageWriteToSavedPhotosAlbum(chosenImage, self, nil, nil)
        }
        
        // Get text from the Image
        var ocrText = processImage(image: chosenImage)
        
        // Do any post processing on the result
        ocrText = cleanOCRResult(inResult: ocrText)
        
        // Send the result back to the Add Spot page
        delegate?.setCameraRegistration(valueSent: ocrText)
        
        // Close the picker
        self.dismiss(animated: true, completion: nil)
        
    }

    // User cancels the imagePicker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        // Close the picker
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    *
    * Function to take an image and process it using OCR to obtain text.
    *
    */
    func processImage(image: UIImage) -> String {
        
        var returnText: String = ""
        
        // Process the image
        
        swiftOCR.recognize(image) { recognisedText in
            
            rwPrint(inFunction: #function, inMessage: "OCR text: \(recognisedText)")
            returnText = recognisedText
        }
        
        // Use scaling function to ensure image is in a suitable scale for Tesseract
        // let scaledImage = scaleImage4Tesseract(image: image, maxDimension: 640)
        
        /*
        // Test that Tesseract has been instantiated correctly
        if tesseract != nil {
            
            // Pass the scaled image to Tesseract using it's own black & white tool to improve contrast for better results
            tesseract?.image = scaledImage.g8_blackAndWhite()
            
            // Do the OCR
            tesseract?.recognize()
            
            rwPrint(inFunction: #function, inMessage: "OCR text: \(tesseract?.recognizedText)")
            returnText = (tesseract?.recognizedText)!
        }
         */
        
        return returnText
    }
}


