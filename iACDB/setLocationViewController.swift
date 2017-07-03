//
//  setLocationViewController.swift
//  iACDB
//
//  Created by Richard Walters on 01/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//

import UIKit

// Import 3rd party frameworks
import Alamofire
import AlamofireImage
import SwiftyJSON

// Protocol for defining delegate to handle pass back of data to calling controller
protocol setLocationViewControllerDelegate{
    
    func returnFromSetLocation(controller: setLocationViewController, chosenLocation:String)
}

class setLocationViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource
{
    var delegate:setLocationViewControllerDelegate? = nil
    
    
    @IBOutlet weak var locationText:   UITextField!
    
    
    static var locationPickerData: [String]=[String]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Set Location"
    
    
    // Populate picker with list of valid locations from the server passing in delegate completion handler
    afPopulateLocations(completionHandler: { success, json -> Void in
    
    if (success) {
    
        debugPrint ("Locations data returned successfully from async call")
    
        // Clear existing array
        setLocationViewController.locationPickerData.removeAll()
    
        // Assign returned data to SwiftyJSON object
        let data = JSON(json!)
    
        // Iterate through array of Dictionary's
        for (_, object) in data {
    
            // Get the aircraft information from json
            let location = object["Location"].stringValue
    
            // Add the location to the pickerView
            setLocationViewController.locationPickerData.append(location)
    
            }
    
        } else
        {
            print("No data returned from async call")
        }
        
        //self.locationPicker.reloadAllComponents()
        
        //self.locationPicker.selectRow(0, inComponent: 0, animated: <#T##Bool#>)
    })
    
}

    // Get the Locations info from theTBGweb server asynchronously using Alamofire
    func afPopulateLocations(completionHandler:  @escaping (Bool, [[String: String]]?) -> ())
    {
        // Display network activity indicator in status bar
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Set destination url & value to send
        let url: String = "http://tbgweb.dyndns.info/iacdb/iosLoadLocations.php"
        
        // Do asynchronous call to server using Alamofire library
        Alamofire.request(url, method: .post)
            .validate()
            .responseJSON { response in
                
                // check for errors
                guard response.result.error == nil else {
                    // got an error in getting the data, need to handle it
                    print("error calling POST on Locations data request")
                    print(response.result.error!)
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    return completionHandler(false, nil)
                }
                
                // make sure we have got valid JSON as an array of key/vale pairs of strings
                guard let json = response.result.value as? [[String: String]]! else {
                    print("Didn't get valid JSON from server")
                    print("Error: \(response.result.error)")
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    return completionHandler(false, nil)
                }
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return completionHandler(true, json)
        }
    }
    
    // Function to take value selected and pass it back to calling view using delegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        // Set text field from pickerView value
        locationText.text = setLocationViewController.locationPickerData[row]
        
        // Check the delegate in calling controller is set
        guard let delegate = self.delegate else {
            print("Delegate for setLocationController not Set")
            return
        }
        
        // Set the delegate to be called when this view closes
        delegate.returnFromSetLocation(controller: self, chosenLocation: setLocationViewController.locationPickerData[row])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // The number of columns of data    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return setLocationViewController.locationPickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return setLocationViewController.locationPickerData[row]
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
