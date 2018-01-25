//
//  ActivityTableViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 10/15/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class ActivityTableViewController: UITableViewController {
    
    // MARK: - Constants
    struct Constants {
        static let NumberOfSections = 1
        
        static let CellIdentifier = "Activity Cell"
        
        static let SwipeToDeleteErrorTitle = "Unable to delete activity"
        static let SwipeToDeleteErrorBody = "There was a problem deleting the activity, birthdays and anniversaries aren't able to be deleted"
        
    }
    
    struct Storyboard {
        static let SegueID = "Activity Segue ID"
    }
    
    // MARK: - Model
    
    var activities = [RelationshipChatActivity]() {
        didSet {
            activities.sort {
                $0.daysUntil < $1.daysUntil
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    //MARK: - Instance variables 
    fileprivate lazy var dateFormatter : DateFormatter = {
        let cellDateFormat = "EEEE, MMM d"
        let formatter = DateFormatter()
        formatter.dateFormat = cellDateFormat
        return formatter
    }()
    
    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideEmptyCells()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.NumberOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return activities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ActivityTableViewController.Constants.CellIdentifier, for: indexPath) as! ActivityTableViewCell
        
        let activity = activities[indexPath.row]
        cell.activity = activity
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deletedAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            
            guard let recordToBeDeleted = self?.activities[indexPath.row], recordToBeDeleted.systemActivity == nil else {
                let alertController = UIAlertController(title: Constants.SwipeToDeleteErrorTitle, message: Constants.SwipeToDeleteErrorBody, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
                return
            }
            
            self?.activities.remove(at: indexPath.row)
            
            RelationshipChatActivity.deleteActivity(activityID: recordToBeDeleted.activityUID, completionHandler: { (error) in
                guard error == nil else {
                    print(error!)
                    return
                }
            })
        }
        
        deletedAction.backgroundColor = UIColor.red
        
        return UISwipeActionsConfiguration(actions: [deletedAction])
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.SegueID:
                if let activityOverviewVC = (segue.destination as? UINavigationController)?.contentViewController as? ActivityOverviewViewController {
                    let selectedActivity = activities[(tableView.indexPathForSelectedRow?.row)!]
                    
                    activityOverviewVC.activity = selectedActivity
                    activityOverviewVC.navigationItem.title = selectedActivity.title
                }
            default:
                break
            }
        }
    }
    
}
