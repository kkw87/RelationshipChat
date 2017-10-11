//
//  UpcomingActivitiesTableViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/13/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import CloudKit

//MARK: - Data structures
struct RelationshipActivity {
    let daysUntilActivity : Int
    let activityRecord : CKRecord
    let activityDate : Date
}

@available(iOS 10.0, *)
class UpcomingActivitiesTableViewController: UITableViewController {
    
    // MARK: - Constants
    struct Constants {
        static let NumberOfSections = 1
     
        static let CellIdentifier = "Upcoming Activity Cell"
        
        static let SwipeToDeleteErrorTitle = "Unable to delete activity"
        static let SwipeToDeleteErrorBody = "There was a problem deleting the activity, birthdays and anniversaries aren't able to be deleted"
    }
    
    struct Storyboard {
        static let SegueID = "Activity Segue ID"
    }
    
    // MARK : - Instance properties
    fileprivate var activities = [RelationshipActivity]() {
        didSet {
            self.activities = self.activities.sorted {
                $0.daysUntilActivity < $1.daysUntilActivity
            }
        }
    }
    
    fileprivate lazy var dateFormatter : DateFormatter = {
        let cellDateFormat = "EEEE, MMM d"
        let formatter = DateFormatter()
        formatter.dateFormat = cellDateFormat
        return formatter
    }()
    
    var relationshipRecord : CKRecord? {
        didSet {
            let activities = relationshipRecord?[Cloud.RelationshipAttribute.Activities] as? [CKReference]
            if activities != nil {
                loadActivities(activityReferences: activities!)
            }
        }
    }
    
    //MARK : - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideEmptyCells()
        addNotificationObservers()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
    }
    
    // MARK: - Class Methods
    fileprivate func addNotificationObservers() {
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.ActivityUpdateChannel, object: nil, queue: OperationQueue.main) { (notification) in
            
            if let newActivity = notification.userInfo?[CloudKitNotifications.ActivityUpdateKey] as? CKRecord {
                self.activities = self.activities.filter {$0.activityRecord.recordID != newActivity.recordID}
                self.addActivityFrom(record: newActivity)
            } else if let activityReferences = notification.userInfo?[CloudKitNotifications.ActivityUpdateKey] as? [CKReference] {
                self.loadActivities(activityReferences: activityReferences)
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.ActivityDeletedChannel, object: nil, queue: OperationQueue.main) { (notification) in
            
            if let deletedActivity = notification.userInfo?[CloudKitNotifications.ActivityDeletedKey] as? CKRecordID {
                self.activities = self.activities.filter { $0.activityRecord.recordID != deletedActivity}
            } else if let deletedReferenceID = notification.userInfo?[CloudKitNotifications.ActivityDeletedChannel] as? CKQueryNotification {
                self.activities = self.activities.filter { $0.activityRecord.recordID != deletedReferenceID.recordID }
            }
            
        }
    }
    
    fileprivate func loadActivities(activityReferences : [CKReference]) {
        
        let fetchAllActivitiesOperation = CKFetchRecordsOperation(recordIDs: activityReferences.map {$0.recordID})

        fetchAllActivitiesOperation.fetchRecordsCompletionBlock = { (fetchedRecords, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if error != nil {
                _ = Cloud.errorHandling(error!, sendingViewController: self)
            } else {
                self.activities = []
                for (_, fetchedActivity) in fetchedRecords! {
                  self.addActivityFrom(record: fetchedActivity)
                }
            }
            
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        Cloud.CloudDatabase.PublicDatabase.add(fetchAllActivitiesOperation)
    }
    
    //MARK: - Table view delegates
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
                
        let deletedAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            
            guard let recordToBeDeleted = self?.activities[indexPath.row].activityRecord, recordToBeDeleted[Cloud.RelationshipActivityAttribute.SystemCreated] == nil else {
                let alertController = UIAlertController(title: Constants.SwipeToDeleteErrorTitle, message: Constants.SwipeToDeleteErrorBody, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
                return
            }
            
            let originalActivities = self?.relationshipRecord![Cloud.RelationshipAttribute.Activities] as CKRecordValue?
            
            self?.relationshipRecord![Cloud.RelationshipAttribute.Activities] = (self?.relationshipRecord![Cloud.RelationshipAttribute.Activities] as! [CKReference]).filter {
                $0.recordID.recordName != recordToBeDeleted.recordID.recordName
            } as CKRecordValue?
            
            let modifyRecordsOp = CKModifyRecordsOperation(recordsToSave: [self!.relationshipRecord!], recordIDsToDelete: [recordToBeDeleted.recordID])
            
            modifyRecordsOp.modifyRecordsCompletionBlock = { [weak self] (savedRecords, deletedRecordIDs, error) in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                guard error == nil else {
                    self?.relationshipRecord![Cloud.RelationshipAttribute.Activities] = originalActivities
                    print(error!)
                    return
                }
                                self?.activities = (self?.activities.filter {
                    $0.activityRecord.recordID != deletedRecordIDs?.first
                    })!
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            Cloud.CloudDatabase.PublicDatabase.add(modifyRecordsOp)
        }
        
        //set garbage can image
        //deletedAction.image = ""
        deletedAction.backgroundColor = UIColor.red
        
        return UISwipeActionsConfiguration(actions: [deletedAction])
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return Constants.NumberOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return activities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifier, for: indexPath) as! ActivityTableViewCell
        
        let activity = activities[indexPath.row]
        cell.activity = activity
        
        return cell
    }
    
    //MARK: - Add/Delete methods 
    func update(activity : CKRecord) {
        activities = activities.filter {$0.activityRecord != activity}
        addActivityFrom(record: activity)
    }
    
    func delete(activityToDelete : CKRecordID) {
        activities = activities.filter { $0.activityRecord.recordID != activityToDelete }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.SegueID:
                if let activityOverviewVC = segue.destination as? ActivityOverviewViewController {
                    
                    let selectedActivityRecord = activities[(tableView.indexPathForSelectedRow?.row)!].activityRecord
                    
                    activityOverviewVC.activity = selectedActivityRecord
                    activityOverviewVC.navigationItem.title = selectedActivityRecord[Cloud.RelationshipActivityAttribute.Name] as? String
                }
            default:
                break
            }
        }
    }
    
    //MARK: - Class Methods
    fileprivate func addActivityFrom(record : CKRecord) {

        let calendar = NSCalendar.current
        let currentDate = calendar.startOfDay(for: Date())
        let currentYear = calendar.component(.year, from: currentDate)
        
        var activityDateComponents = calendar.dateComponents([.year, .month, .day], from: record[Cloud.RelationshipActivityAttribute.CreationDate] as! Date)
        
        func addSystemActivity() {
            activityDateComponents.year = currentYear
            
            var systemMadeActivityDate = calendar.date(from: activityDateComponents)!
            
            let dateComparison = calendar.compare(systemMadeActivityDate, to: currentDate, toGranularity: .day)
            
            if dateComparison == .orderedAscending {
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: systemMadeActivityDate)
                dateComponents.year = currentYear + 1
                systemMadeActivityDate = calendar.date(from: dateComponents)!
            }
            
            let dayDifference = calendar.dateComponents([.day], from: currentDate, to: systemMadeActivityDate).day!
            
            let newActivity = RelationshipActivity(daysUntilActivity: dayDifference, activityRecord: record, activityDate: systemMadeActivityDate)
            
            activities.append(newActivity)
            
        }
        
        func addActivity() {
            let activityDate = calendar.date(from: activityDateComponents)!
            
            let days = calendar.dateComponents([.day], from: currentDate, to: activityDate).day!
            
            let newActivity = RelationshipActivity(daysUntilActivity: days, activityRecord: record, activityDate: activityDate)
            
            activities.append(newActivity)
        }
        
        if record[Cloud.RelationshipActivityAttribute.SystemCreated] != nil {
            addSystemActivity()
        } else {
            addActivity()
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
