//
//  UserDailyCheckInByDayTableViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 8/25/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import CloudKit
import MapKit

class UserDailyCheckInByDayTableViewController: UITableViewController {
    
    //MARK : - Constants
    struct Storyboard {
        static let DetailSegue = "To Detail Segue"
        static let CellIdentifier = "Location Cell"
        static let SwipeToDeleteUnwindSegue = "ActivityByDayDeleted" 
    }
    
    struct Constants {
        static let SwipeToDeleteText = "Delete"
    }
    
    //MARK : - Model
    var userLocations : [CKRecord]? {
        didSet {
            if userLocations?.count == 0 {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: Storyboard.SwipeToDeleteUnwindSegue, sender: self)
                }
            } else {
                userLocations?.sort {
                    $0.creationDate! < $1.creationDate!
                }
                
                DispatchQueue.main.async {
                    self.tableView?.reloadData()
                }
            }
        }
    }
    
    var deletedRecord : CKRecord?
    
    //MARK : - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideEmptyCells()
        navigationItem.largeTitleDisplayMode = .never
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return userLocations?.count ?? 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.CellIdentifier, for: indexPath)
        
        guard userLocations != nil else {
            return cell
        }
        
        let currentLocation = userLocations![indexPath.row]
        
        let locationStringName = currentLocation[Cloud.UserLocationAttribute.LocationStringName] as! String
        let locationCreatorName = currentLocation[Cloud.UserLocationAttribute.UserName] as! String
        
        cell.textLabel?.text = locationStringName
        cell.detailTextLabel?.text = locationCreatorName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: Constants.SwipeToDeleteText) { [weak self] (action, view, completionHandler) in
            
            
            if let recordToDelete = self?.userLocations?[indexPath.row] {
                self?.updateRelationshipWithDeleted(record: recordToDelete)
                completionHandler(true)
            } else {
                //Print, some kind of alert to the user
                completionHandler(false)
            }
        }
        
        //deleteAction.image needs to be set 
        deleteAction.backgroundColor = UIColor.red
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return configuration
    }
    
    //Add Swipe to delete with ios 11
    //Upon Deletion, should unwind back to CheckInTVC
    
    
    
    
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
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.DetailSegue:
                if let detailTV = segue.destination as? UserDailyCheckInDetailTableViewController {
                    
                    let indexPath = tableView.indexPath(for: sender as! UITableViewCell)!
                    let selectedRecord = userLocations![indexPath.row]
                    let locationCreatorName = selectedRecord[Cloud.UserLocationAttribute.UserName] as! String
                    detailTV.navigationItem.title = locationCreatorName
                    detailTV.locationRecord = selectedRecord
                    
                }
            default:
                break
            }
        }
    }
    
    @IBAction func unwindFromDetailTableViewController(segue : UIStoryboardSegue) {
        
        guard let sourceVC = segue.source as? UserDailyCheckInDetailTableViewController, let deletedRecordFromSegue = sourceVC.locationRecord else {
            print("there was a problem deleting the location from unwind")
            return
        }
        
        updateRelationshipWithDeleted(record: deletedRecordFromSegue)
    }
    
    //MARK: - Class Methods
    fileprivate func updateRelationshipWithDeleted(record : CKRecord) {
        userLocations = userLocations?.filter {
            $0.recordID != record.recordID
        }

        NotificationCenter.default.post(name: CloudKitNotifications.LocationDeletedUpdateChannel, object: self, userInfo: [CloudKitNotifications.LocationDeletedKey:record])
    }
    
}
