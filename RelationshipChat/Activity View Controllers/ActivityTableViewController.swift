//
//  ActivityTableViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 10/15/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import CloudKit
import MapKit

//MARK: - Data structures
struct RelationshipActivity {
    let daysUntilActivity : Int
    let activityRecord : CKRecord
    let activityDate : Date
}

//MARK: - ActivityTableViewController Data Source
protocol ActivityTableViewControllerDataSource {
    func deleteActivity(activityRecordID : CKRecordID)
    
    func addActivity(newActivityToSave : CKRecord, completionHandler : ((Bool?, Error?)->Void)?)
    
    func inAValidRelationshipCheck() -> Bool
}

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
    
    var dataSource : ActivityTableViewControllerDataSource?
    
    var activities = [RelationshipActivity]() {
        didSet {
            self.activities = self.activities.sorted {
                $0.daysUntilActivity < $1.daysUntilActivity
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
            
            guard let recordToBeDeleted = self?.activities[indexPath.row].activityRecord, recordToBeDeleted[Cloud.RelationshipActivityAttribute.SystemCreated] == nil else {
                let alertController = UIAlertController(title: Constants.SwipeToDeleteErrorTitle, message: Constants.SwipeToDeleteErrorBody, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
                return
            }
            //Filter current activities array to remove the deleted record
            self?.activities = (self?.activities.filter {
                $0.activityRecord != recordToBeDeleted
                })!
            self?.dataSource?.deleteActivity(activityRecordID: recordToBeDeleted.recordID)
        }
        
        //set garbage can image
        //deletedAction.image = ""
        deletedAction.backgroundColor = UIColor.red
        
        return UISwipeActionsConfiguration(actions: [deletedAction])
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.SegueID:
                if let activityOverviewVC = (segue.destination as? UINavigationController)?.contentViewController as? ActivityOverviewViewController {
                    let selectedActivityRecord = activities[(tableView.indexPathForSelectedRow?.row)!].activityRecord
                    
                    activityOverviewVC.activity = selectedActivityRecord
                    activityOverviewVC.navigationItem.title = selectedActivityRecord[Cloud.RelationshipActivityAttribute.Name] as? String
                }
            default:
                break
            }
        }
    }
    
}
