//
//  SettingsTableViewController.swift
//  iACDB
//
//  Created by Richard Walters on 02/01/2017.
//  Copyright © 2017 Richard Walters. All rights reserved.
//

import UIKit
import SafariServices
import Kingfisher

class SettingsTableViewController: UITableViewController, UITextFieldDelegate {
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard
    
    // Outlets
    
    @IBOutlet weak var userName:                UITextField!
    @IBOutlet weak var btnClearSpotData:        UIButton!
    @IBOutlet weak var btnUpdate:               UIButton!
    @IBOutlet weak var lblAboutApp:             UILabel!
    @IBOutlet weak var btnClearImageCache:      UIButton!
    @IBOutlet weak var lblKfDiskSpace:          UILabel!
    
    // Actions
    @IBAction func btnUpdate(_ sender: UIButton) {
        
        // Open app page in web browser
        let appHome = URL(string: "https://tbgweb.dyndns.info/wordpress/iosdevelopment/iacdb")!
        
        UIApplication.shared.open(appHome, options: [:], completionHandler: {
            (success) in
            print("Opened app home page")
        })
    }
    
    @IBAction func userName(_ sender: UITextField) {
        
        defaults.set(sender.text, forKey: "name")
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
    
    @IBAction func btnClearSpotData(_ sender: Any) {
        
        resetSpotData()
        
    }
    
    @IBAction func btnClearImageCache(_ sender: Any) {
        
        clearKingfisherCache()
    }
    
    
    @IBAction func btnMainSettings(_ sender: UIBarButtonItem) {
        
        go2iOSSettings()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load settings
        setViewControls()
        
        // Setup observer for changes in UserDefaults
        notifyDefaultsChange()
        
        // Activate Return key on keyboard
        userName.returnKeyType = .done
        userName.delegate = self
        
        displayKingfisherCache()

    }
    
    // Function to set the controls on the page to match the settings from the device UserDefaults
    func setViewControls() {
        
        userName.text = defaults.string(forKey: "name")
        
        lblAboutApp.text = "TBGweb Solutions v" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)!

    }
    
    /*
     * Function to add an observer to be notified when a user changes a setting
     */
    func notifyDefaultsChange()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(self.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    /*
     * Function to receive notification of changed user default
     */
    @objc func defaultsChanged(notification: Notification)
    {
            // Print user defaults to console
            printUserDefaults()
            
            // Log UserDefaults update notification
            print("Notification: UserDefaults Change")
        
            // Reload settings
            setViewControls()
        
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
    
    // Function to empty the CoreData store of all spot entries
    func resetSpotData()
    {
        let refreshAlert = UIAlertController(title: "Reset", message: "All spot data will be lost.", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { (action: UIAlertAction!) in
            
            // Call function to delete the CoreData table contents
            _ = entityDeleteAllData (inEntity: "EntSpots")
            
            // Get the container context
            let moc = getContext()
            
            // Reset the Managed Object context after deleting the data
            moc.reset()
            
            // Reload the tableView
            self.tableView.reloadData()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            // do nothing
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    // Function to display disk space used ly Kingfisher
    func displayKingfisherCache()
    {
        ImageCache.default.calculateDiskCacheSize { (size) in
            
            self.lblKfDiskSpace.text = "Using " + String(size/1000000) + "MB of disk space"
        }
    }
    
    // Function to clear the Kingfisher Image cache
    func clearKingfisherCache()
    {
        ImageCache.default.clearDiskCache()
        ImageCache.default.clearMemoryCache()
        displayKingfisherCache()
    }
}
