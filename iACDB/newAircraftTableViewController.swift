//
//  newAircraftTableViewController.swift
//  iACDB
//
//  Created by Richard Walters on 11/02/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//

import UIKit
import CoreData
import Alamofire

class newAircraftTableViewController: UITableViewController,  NSFetchedResultsControllerDelegate  {
    
    // Setup controller to manage our data NSFetched results style
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Seup our User Defaults instance
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get ref to the network monitor
        let netMonitor = appDelegate.netMonitor!
        
        var networkStatus: String = "TBGweb server "
        
        // Start the listener
        netMonitor.listener = { status in
            
            // Take action depending on status 1st pass - identify status
            switch status {
                
            case .notReachable:
                networkStatus += "is not reachable"
                
            case .unknown:
                networkStatus += "status unknown"
                
            case .reachable(.ethernetOrWiFi):
                networkStatus += "is WiFi reachable"
                
            case .reachable(.wwan):
                networkStatus += "is reachable via mobile data"
            }
            
            print(networkStatus)
            
            // Take action depending on status - 2nd pass
            switch status {
                
            // Do nothing
            case .notReachable, .unknown:
                break
                
            // Trigger sync of CoreData caches
            case .reachable(.ethernetOrWiFi), .reachable(.wwan):
                
                //syncNewAircraft2RemoteDB()
                
                break
            }
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
