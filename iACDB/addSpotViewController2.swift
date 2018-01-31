//
//  addSpotViewController2.swift
//  iACDB
//
//  Created by Richard Walters on 29/01/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//

import UIKit
import Eureka

class addSpotViewController2: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupForm()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: - Form Setup
    func setupForm()
    {
        // Create sections and rows for Eureka form
        
        form
            +++ Section()
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
