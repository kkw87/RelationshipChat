//
//  RelationshipViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 4/22/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import CloudKit

@available(iOS 10.0, *)
class RelationshipViewController: UIViewController {
    
    //MARK: - Constants
    struct Storyboard {
        static let NewRelationshipSegue = "New Relationship Segue"
        
        static let EditProfileSegue = "Edit Relationship Segue"
        
        static let RelationshipConfirmationSegueID = "Relationship Confirmation Segue"
        
        static let UserDailyCheckInTableEmbedSegue = "UserLocationEmbedSegue"
    }
    
    struct Constants {
        
        static let DefaultRelationshipStatusMessage = "You are not in a relationship"
        static let DefaultDateText = "Not in a relationship"
        
        static let PendingTextMessage = "Waiting to hear back"
        static let PendingStatusMessage = "Pending"
        static let NotInARelationshipPendingMessage = "Pending relationship..."
        
        static let DefaultNotInARelationshipMessage = "Find a relationship"
        
        static let DefaultRelationshipStartDate = Date()
        static let DateFormat = "EEEE, MMM d, yyyy"
        
        static let BlankMessage = " "
        
        static let AlertPendingDeleteTitle = "Delete your relationship request"
        static let AlertPendingDeleteBody = "Do you wish to delete your current relationship request?"
        
        static let StatusLabelTextDefault = "Currently"
        static let StatusLabelTextRelationship = "Since"
        
        static let FindingProfileMessage = "Finding your profile"
        static let DownloadingProfileMessage = "Pulling your profile information"
        
        static let FindingRelationshipMessage = "Trying to finding your relationship"
        static let DownloadingRelationshipMessage = "Getting all your relationship details"
    }
    
    //MARK: - Outlets
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView! {
        didSet {
            backgroundView.backgroundColor = UIColor(gradientStyle: .radial, withFrame: backgroundView.bounds, andColors: GlobalConstants.defaultGradientColorArray)
        }
    }
    @IBOutlet weak var embedViewContainer: UIView! {
        didSet {
            embedViewContainer.roundEdges()
            embedViewContainer.clipsToBounds = true 
        }
    }
    @IBOutlet weak var notInRelationshipView: UIView! {
        didSet {
            notInRelationshipView.roundEdges()
            notInRelationshipView.clipsToBounds = true
        }
    }
    @IBOutlet weak var editButton: UIBarButtonItem! {
        didSet {
            editButton.isEnabled = false
        }
    }
    @IBOutlet weak var relationshipWithButton: UIButton! {
        didSet {
            relationshipWithButton.roundEdges()
            relationshipWithButton.clipsToBounds = true
            
        }
    }
    @IBOutlet weak var relationshipStatus: UILabel!
    
    @IBOutlet weak var relationshipStartDate: UILabel!
    
    @IBOutlet weak var notInARelationshipViewText: UILabel!
    @IBOutlet weak var newRelationshipButton: UIButton! {
        didSet {
            newRelationshipButton.roundEdges()
            newRelationshipButton.clipsToBounds = true
            newRelationshipButton.backgroundColor = UIColor.clear
        }
    }
    
    @IBOutlet weak var cancelPendingRelationshipButton: UIButton! {
        didSet {
            cancelPendingRelationshipButton.isHidden = true
            cancelPendingRelationshipButton.roundEdges()
        }
    }
    
    
    
    // MARK: - Relationship request variables
    fileprivate var sendersRecord : CKRecord?
    fileprivate var requestedRelationship : CKRecord?
    fileprivate var relationshipRequestID : CKRecordID?
    
    
    //MARK: - Instance Variables
    
    fileprivate var loadingView = ActivityView(withMessage: "")
    
    var relationshipRecord : CKRecord? {
        didSet {
            if relationshipRecord != nil {
                setupRelationship()
            } else {
                unsetRelationship()
            }
        }
    }
    
    var pendingRelationshipRequestID : CKRecordID?
    
    private var currentUsersRecord : CKRecord? {
        didSet {
            if currentUsersRecord != nil {
                let usersName = Cloud.pullUserInformationFrom(usersRecordToLoad: currentUsersRecord!).usersFirstName
                embeddedUserDailyCheckIn?.currentUserName = usersName
            }
        }
    }
    
    private var secondaryUsersRecord : CKRecord? {
        didSet {
            if secondaryUsersRecord != nil {
                let userInfo = Cloud.pullUserInformationFrom(usersRecordToLoad: secondaryUsersRecord!)
                relationshipWithButton.setImage(userInfo.usersImage, for: .normal)
                relationshipWithButton.isEnabled = true
            } else {
                relationshipWithButton.isEnabled = false
                relationshipWithButton.setImage(UIImage(named: "Dislike Filled-50"), for: .normal)
            }
        }
    }
    
    
    
    private lazy var dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.DateFormat
        return formatter
    }()
    
    fileprivate var embeddedUserDailyCheckIn : UserDailyCheckInTableViewController? {
        didSet {
            embeddedUserDailyCheckIn?.relationshipRecord = relationshipRecord
        }
    }
    
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserInformation()
        addNotificationObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        relationshipWithButton.backgroundColor = UIColor.clear
        newRelationshipButton.backgroundColor = UIColor.clear
        tabBarController?.tabBar.items![1].tag = UIApplication.shared.applicationIconBadgeNumber
    }
    
    //MARK : - Outlet Methods
    
    
    @IBAction func cancelPendingRelationshipRequest(_ sender: Any) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let deleteConfirmationViewController = UIAlertController(title: Constants.AlertPendingDeleteTitle, message: Constants.AlertPendingDeleteBody, preferredStyle: .alert)
        deleteConfirmationViewController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        deleteConfirmationViewController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (alert) in
            
            let backupRelationship = self?.relationshipRecord
            
            let deleteOperation = CKModifyRecordsOperation(recordsToSave: [self!.currentUsersRecord!], recordIDsToDelete: [self!.relationshipRecord!.recordID])
            
            
            self?.currentUsersRecord?[Cloud.UserAttribute.Relationship] = nil
            self?.relationshipRecord = nil
            
            deleteOperation.modifyRecordsCompletionBlock = { [weak self] (savedRecords, deletedRecords, error) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if error != nil {
                    DispatchQueue.main.async {
                        _ = Cloud.errorHandling(error!, sendingViewController: self)
                        self?.relationshipRecord = backupRelationship
                        self?.currentUsersRecord?[Cloud.UserAttribute.Relationship] = (backupRelationship as! CKRecordValue)
                    }
                    
                } else {
                    DispatchQueue.main.async {
                        self?.displayAlertWithTitle("You cancelled your pending request", withBodyMessage: "Your pending request was successfully cancelled", withBlock: nil)
                        NotificationCenter.default.post(name: CloudKitNotifications.RelationshipUpdateChannel, object: nil, userInfo: nil)
                    }
                }
            }
            
            Cloud.CloudDatabase.PublicDatabase.add(deleteOperation)
        }))
        
        present(deleteConfirmationViewController, animated: true, completion: nil)
    }
    
    
    @IBAction func newRelationship(_ sender: Any) {
        if currentUsersRecord == nil {
            displayAlertWithTitle("Your profile is still loading!", withBodyMessage: "Try again in a few seconds", withBlock: nil)
        } else {
            performSegue(withIdentifier: Storyboard.NewRelationshipSegue, sender: self)
        }
    }
    //MARK: - Class methods
    
    fileprivate func setupRelationship() {
        
        if let status = relationshipRecord?[Cloud.RelationshipAttribute.Status] as? String {
            switch status {
                
            case Cloud.RelationshipStatus.Pending :
                notInRelationshipView.isHidden = false
                notInARelationshipViewText.text = Constants.NotInARelationshipPendingMessage
                newRelationshipButton.isEnabled = false
                editButton.isEnabled = false
                relationshipStatus.text = Constants.BlankMessage
                relationshipStartDate.text = Constants.PendingStatusMessage
                tabBarController?.chatBarItem?.isEnabled = false
                cancelPendingRelationshipButton.isHidden = false
                statusLabel.text = Constants.StatusLabelTextDefault
            default :
                tabBarController?.chatBarItem?.isEnabled = true
                statusLabel.text = Constants.StatusLabelTextRelationship
                editButton.isEnabled = true
                relationshipStatus.text = relationshipRecord![Cloud.RelationshipAttribute.Status] as? String ?? Constants.DefaultRelationshipStatusMessage
                
                relationshipStartDate.text = dateFormatter.string(from: relationshipRecord![Cloud.RelationshipAttribute.StartDate] as? Date ?? Date())
                
                embeddedUserDailyCheckIn?.relationshipRecord = relationshipRecord
                
                notInRelationshipView.isHidden = true
                
                cancelPendingRelationshipButton.isHidden = true
            }
        }
        
    }
    
    fileprivate func unsetRelationship() {
        statusLabel.text = Constants.StatusLabelTextDefault
        relationshipStatus.text = Constants.DefaultRelationshipStatusMessage
        relationshipStartDate.text = Constants.DefaultDateText
        notInRelationshipView.isHidden = false
        newRelationshipButton.isEnabled = true
        notInARelationshipViewText.text = Constants.DefaultNotInARelationshipMessage
        editButton.isEnabled = false
        tabBarController?.chatBarItem?.isEnabled = false
        secondaryUsersRecord = nil
        cancelPendingRelationshipButton.isHidden = true
        
        //Get users relationship value and remove it,
        
        if currentUsersRecord?[Cloud.UserAttribute.Relationship] != nil {
            currentUsersRecord![Cloud.UserAttribute.Relationship] = nil
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            Cloud.CloudDatabase.PublicDatabase.save(currentUsersRecord!, completionHandler: { (updatedUsersRecord, error) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    return
                }
                
                NotificationCenter.default.post(name: CloudKitNotifications.CurrentUserRecordUpdateChannel, object: nil, userInfo: [CloudKitNotifications.CurrentUserRecordUpdateKey : updatedUsersRecord!])
                
            })
        }
    }
    
    fileprivate func addNotificationObserver() {
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.RelationshipRequestChannel, object: nil, queue: nil) { [weak self] (notification) in
            
            if let relationshipRequest = notification.userInfo?[CloudKitNotifications.RelationshipRequestKey] as? CKQueryNotification {
                
                let predicate = NSPredicate(format: "to = %@", self!.currentUsersRecord!)
                let query = CKQuery(recordType: Cloud.Entity.RelationshipRequest, predicate: predicate)
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: { (fetchedRecords, error) in
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if error != nil {
                        DispatchQueue.main.async {
                            _ = Cloud.errorHandling(error!, sendingViewController: self)
                        }
                    } else if let relationshipRequestRecord = fetchedRecords?.first {
                        
                        let requestSender = relationshipRequestRecord[Cloud.RelationshipRequestAttribute.Sender] as! CKReference
                        let requestRelationship = relationshipRequestRecord[Cloud.RelationshipRequestAttribute.Relationship] as! CKReference
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                        
                        Cloud.pullRelationshipRequest(fromSender: requestSender.recordID, relationshipRecordID: requestRelationship.recordID, relationshipRequestID: relationshipRequest.recordID!, presentingVC: self) {(sendingUsersRecord, requestedRelationshipRecord) in
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            DispatchQueue.main.async {
                                
                                self?.sendersRecord = sendingUsersRecord
                                self?.requestedRelationship = requestedRelationshipRecord
                                self?.relationshipRequestID = relationshipRequest.recordID!
                                self?.navigationController?.popToRootViewController(animated: true)
                                self?.performSegue(withIdentifier: Storyboard.RelationshipConfirmationSegueID, sender: nil)
                                
                            }
                            
                        }
                    }
                })
            }
        }
        
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.RelationshipUpdateChannel, object: nil, queue: nil) { [weak self] (notification) in
            
            if let newRelationship = notification.userInfo?[CloudKitNotifications.RelationshipUpdateKey] as? CKQueryNotification {
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: newRelationship.recordID!) { (fetchedRecord, error) in
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if error != nil {
                        _ = Cloud.errorHandling(error!, sendingViewController: nil)
                    } else {
                        if let newRelationship = fetchedRecord {
                            self?.relationshipRecord = newRelationship
                        } else {
                            self?.relationshipRecord = nil
                        }
                    }
                }
            } else if let newRelationship = notification.userInfo?[CloudKitNotifications.RelationshipUpdateKey] as? CKRecord {
                
                DispatchQueue.main.async {
                    
                    self?.relationshipRecord = newRelationship
                }
            } else {
                DispatchQueue.main.async {
                    self?.relationshipRecord = nil
                    
                }
            }
            
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.CurrentUserRecordUpdateChannel, object: nil, queue: OperationQueue.main) { [weak self](notification) in
            DispatchQueue.main.async {
                if let changedUsersRecord = notification.userInfo?[CloudKitNotifications.CurrentUserRecordUpdateKey] as? CKRecord {
                    
                    self?.currentUsersRecord = changedUsersRecord
                } else {
                    self?.currentUsersRecord = nil
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.SecondaryUserUpdateChannel, object: nil, queue: nil) { [weak self] (notification) in
            if let newSecondaryUser = notification.userInfo?[CloudKitNotifications.SecondaryUserUpdateKey] as? CKQueryNotification {
                
                Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: newSecondaryUser.recordID!, completionHandler: { (record, error) in
                    DispatchQueue.main.async {
                        if error != nil {
                            _ = Cloud.errorHandling(error!, sendingViewController: nil)
                        } else {
                            self?.secondaryUsersRecord = record!
                        }
                    }
                })
                
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.MessageChannel, object: nil, queue: OperationQueue.main) { (_) in

            self.tabBarController?.tabBar.items![1].tag = UIApplication.shared.applicationIconBadgeNumber
        }
        
    }
    
    
    
    fileprivate func loadUserInformation() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        view.addSubview(loadingView)
        loadingView.updateMessageWith(message: Constants.FindingProfileMessage)
        loadingView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        CKContainer.default().fetchUserRecordID {[weak self] (usersRecordID, error) in
            
            guard error == nil, usersRecordID != nil else {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.loadingView.removeFromSuperview()
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                }
                return
            }
            
            let predicate = NSPredicate(format: "creatorUserRecordID = %@", usersRecordID!)
            let query = CKQuery(recordType: Cloud.Entity.User, predicate: predicate)
            
            self?.loadingView.updateMessageWith(message: Constants.DownloadingProfileMessage)
            
            Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: { (records, error) in
                
                guard error == nil, let usersRecord = records?.first else {
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self?.loadingView.removeFromSuperview()
                        _ = Cloud.errorHandling(error!, sendingViewController: self)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.currentUsersRecord = usersRecord
                    self?.loadingView.updateMessageWith(message: Constants.FindingRelationshipMessage)
                }
                
                self?.loadRelationship(fromUserRecord: usersRecord)
            })
            
            
        }
    }
    
    fileprivate func loadRelationship(fromUserRecord : CKRecord?) {
        
        guard let relationshipReference = fromUserRecord?[Cloud.UserAttribute.Relationship] as? CKReference else {
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.loadingView.removeFromSuperview()
            }
            return
        }
        
        DispatchQueue.main.async {
            self.loadingView.updateMessageWith(message: Constants.DownloadingRelationshipMessage)
        }
        
        Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: relationshipReference.recordID, completionHandler: { [weak self] (fetchedRelationship, error) in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.loadingView.removeFromSuperview()
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                }
                return
            }
            
            guard fetchedRelationship != nil else {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.loadingView.removeFromSuperview()
                    self?.currentUsersRecord = nil
                }
                return
            }
            
            guard let secondaryUser = ((fetchedRelationship![Cloud.RelationshipAttribute.Users] as? [CKReference])?.filter {$0.recordID != self?.currentUsersRecord!.recordID})?.first else {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.loadingView.removeFromSuperview()
                    self?.displayAlertWithTitle(Constants.DefaultDateText, withBodyMessage: Constants.DefaultNotInARelationshipMessage, withBlock: nil)
                    self?.relationshipRecord = nil
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.relationshipRecord = fetchedRelationship!
            }
            
            Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: secondaryUser.recordID, completionHandler: { (secondaryUsersRecord, error) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.loadingView.removeFromSuperview()
                }
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        _ = Cloud.errorHandling(error!, sendingViewController: self)
                        print(error!)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    if secondaryUsersRecord != nil {
                        self?.secondaryUsersRecord = secondaryUsersRecord!
                    } else {
                        self?.relationshipRecord = nil
                    }
                }
            })
        })
    }
    
    
    
    // MARK: - Navigation
    
    @IBAction func segueFromEditRelationVC(segue : UIStoryboardSegue) {
        if let ervc = segue.source as? EditRelationshipViewController {
            relationshipRecord = ervc.relationship
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case Storyboard.EditProfileSegue:
            if relationshipRecord != nil {
                return true
            } else {
                return false
            }
        case Storyboard.NewRelationshipSegue:
            if currentUsersRecord != nil {
                return true
            } else {
                return false
            }
        default:
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case Storyboard.EditProfileSegue:
                if let evc = segue.destination as? EditRelationshipViewController  {
                    evc.relationship = relationshipRecord
                }
            case Storyboard.NewRelationshipSegue:
                if let nrc = (segue.destination as? UINavigationController)?.visibleViewController as? NewRelationshipViewController {
                    nrc.userRecord = currentUsersRecord!
                }
            case Storyboard.RelationshipConfirmationSegueID :
                if let rvc = segue.destination as? RelationshipConfirmationViewController {
                    rvc.relationship = requestedRelationship
                    rvc.sendersRecord = sendersRecord
                    rvc.usersRecord = currentUsersRecord
                }
            case Storyboard.UserDailyCheckInTableEmbedSegue :
                if let userDailyLocations = (segue.destination as? UINavigationController)?.contentViewController as? UserDailyCheckInTableViewController {
                    embeddedUserDailyCheckIn = userDailyLocations
                    userDailyLocations.presentingView = self.view
                }
            default:
                break
            }
        }
        
    }
    
    
}
