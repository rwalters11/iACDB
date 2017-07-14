//
//  SettingsTableViewController.swift
//  iACDB
//
//  Created by Richard Walters on 02/01/2017.
//  Copyright © 2017 Richard Walters. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, UITextFieldDelegate {
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    // Outlets
    
    @IBOutlet weak var userName:            UITextField!
    
    @IBOutlet weak var swLocationsCache:    UISwitch!
    @IBOutlet weak var swAircraftCache:     UISwitch!
    @IBOutlet weak var swUseNearestLocation:UISwitch!
    @IBOutlet weak var swImagesViaMobileData: UISwitch!
    @IBOutlet weak var swValidateRegistrations: UISwitch!
    
    // Actions
    
    @IBAction func swLocationsCache(_ sender: UISwitch) {
        
        defaults.set(sender.isOn, forKey: "loadLocationsCacheOnStartup")
    }
    
    @IBAction func swAircraftCache(_ sender: UISwitch) {

        defaults.set(sender.isOn, forKey: "loadAircraftCacheOnStartup")
    }
    
    @IBAction func swUseNearestLocation(_ sender: UISwitch) {

        defaults.set(sender.isOn, forKey: "useNearestLocation")
    }
    
    @IBAction func swImagesViaMobileData(_ sender: UISwitch) {
        
        defaults.set(sender.isOn, forKey: "imageLoadWiFiOnly")
    }
    
    @IBAction func userName(_ sender: UITextField) {
        
        defaults.set(sender.text, forKey: "name")
    }
    
    @IBAction func swValidateRegistrations(_ sender: UISwitch) {
        
        defaults.set(sender.isOn, forKey: "validateRegistrations")
    }
    
    @IBAction func btnReset(_ sender: UIBarButtonItem) {
        
        // Ask user if they want to reset their defaults
        
        let message = "Reset all settings to defaults?"
        
        let alertController = UIAlertController(title: "iACDB", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        // Create the actions
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
            
        }
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive) {
            UIAlertAction in
            
            // Set the User Defaults back to the initial setup
            eraseAllUserDefaults()
            
            self.setViewControls()
        }
        
        // Add the actions
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load settings
        setViewControls()
        
        // Activate Return key on keyboard
        userName.returnKeyType = .done
        userName.delegate = self

    }
    
    // Function to set the controls on the page to match the settings from the device UserDefaults
    func setViewControls() {
        
        userName.text = defaults.string(forKey: "name")
        
        swAircraftCache.setOn(defaults.bool(forKey: "loadAircraftCacheOnStartup"), animated: true)

        swLocationsCache.setOn(defaults.bool(forKey: "loadLocationsCacheOnStartup"), animated: true)
        
        swUseNearestLocation.setOn(defaults.bool(forKey: "useNearestLocation"), animated: true)
        
        swImagesViaMobileData.setOn(defaults.bool(forKey: "imageLoadWiFiOnly"), animated: true)
        
        swValidateRegistrations.setOn(defaults.bool(forKey: "validateRegistrations"), animated: true)

    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let headerView = view as! UITableViewHeaderFooterView
        
        // Set custom font colour for headers
        headerView.textLabel?.textColor = UIColor(red: 151.0/255, green: 193.0/255, blue: 100.0/255, alpha: 1)
        
    }
    
    // MARK: - UITextField Delegates
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        // Ask user if they want to reset their defaults
        
        let message = "Choose user"
        
        let alert = UIAlertController(title: "iACDB", message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // Create the actions
        let dAction = UIAlertAction(title: "Darren", style: UIAlertActionStyle.default) {
            
            UIAlertAction in
            
            self.updateUser(username: "Darren")
        }
        
        let jAction = UIAlertAction(title: "Jason", style: UIAlertActionStyle.default) {
            
            UIAlertAction in
            
            self.updateUser(username: "Jason")
        }
        
        let rAction = UIAlertAction(title: "Richard", style: UIAlertActionStyle.default) {
            
            UIAlertAction in
            
            self.updateUser(username: "Richard")
        }
        
        // Add the actions
        alert.addAction(dAction)
        alert.addAction(jAction)
        alert.addAction(rAction)
        
        present(alert, animated: true, completion: nil)
        
        return true
    }
    
    func updateUser(username: String) {
        
        self.userName.text = username
        defaults.set(username, forKey: "name")
        
        userName.resignFirstResponder()
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        return true;
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        switch textField.tag {
            
        // User Name
        case 1:
            break
            

            
        default: break
        }
        return true;
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        return true;
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        userName.resignFirstResponder();
        
        return true;
    }
}
