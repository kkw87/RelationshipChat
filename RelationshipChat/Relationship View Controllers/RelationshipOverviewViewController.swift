////
////  RelationshipOverviewViewController.swift
////  RelationshipChat
////
////  Created by Kevin Wang on 4/22/17.
////  Copyright © 2017 KKW. All rights reserved.
////

import UIKit
import Firebase

@available(iOS 10.0, *)
class RelationshipOverviewViewController: UIViewController {
    
    
    //MARK: - Constants
    struct Storyboard {
        static let NewRelationshipSegue = "New Relationship Segue"
        
        static let EditProfileSegue = "Edit Relationship Segue"
        
        static let RelationshipConfirmationSegueID = "Relationship Confirmation Segue"
        
        static let UserDailyCheckInTableEmbedSegue = "UserLocationEmbedSegue"
        
        static let ViewRelationshipWithSegue = "View Relationship Profile"
    }
    
    struct Constants {
        
        static let DefaultErrorTitle = "Oops!"
        
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
            embedViewContainer.clipsToBounds = true
        }
    }
    @IBOutlet weak var notInRelationshipView: UIView! {
        didSet {
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
    
    @IBOutlet weak var newRelationshipButton: UIButton! {
        didSet {
            newRelationshipButton.roundEdges()
            newRelationshipButton.clipsToBounds = true
            newRelationshipButton.backgroundColor = UIColor.flatPurple()
        }
    }
    
    @IBOutlet weak var cancelPendingRelationshipButton: UIButton! {
        didSet {
            cancelPendingRelationshipButton.isHidden = true
            cancelPendingRelationshipButton.backgroundColor = UIColor.flatPurple()
            cancelPendingRelationshipButton.titleLabel?.textColor = UIColor.white
            cancelPendingRelationshipButton.roundEdges()
            cancelPendingRelationshipButton.clipsToBounds = true
        }
    }
    
    
    //MARK: - Instance Variables
    
    fileprivate var loadingView = ActivityView(withMessage: "")
    
    var relationship : RelationshipChatRelationship? {
        didSet {
            if relationship != nil {
                setupRelationship()
            } else {
                unsetRelationship()
            }
        }
    }
    
    
    private var currentUser : RelationshipChatUser? {
        didSet {
            if currentUser != nil {
                embeddedUserDailyCheckIn?.currentUserName = currentUser?.fullName
                newRelationshipButton.isEnabled = true
                
                if let relationshipID = currentUser?.relationship {
                    
                    RelationshipChatRelationship.fetchRelationship(withUID: relationshipID, completionHandler: { [weak self](fetchedRelationship, error) in
                                                
                        guard error == nil else {
                            print(error!)
                            return
                        }
                        
                        if let newRelationship = fetchedRelationship {
                            self?.relationship = newRelationship
                        } else {
                            self?.relationship = nil 
                        }
                        
                    })
                } else {
                    self.relationship = nil
                }
                
            } else {
                newRelationshipButton.isEnabled = false
            }
        }
    }
    
    private var secondaryUser : RelationshipChatUser? {
        didSet {
            if secondaryUser != nil {
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                secondaryUser?.getUsersProfileImage(completionHandler: { [weak self] (usersImage, error) in
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    
                    guard error == nil else {
                        print(error!.localizedDescription)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.relationshipWithButton.setImage(usersImage!, for: .normal)
                    }
                })
            } else {
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
            embeddedUserDailyCheckIn?.currentRelationship = relationship
        }
    }
    
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserInformation()
        // addNotificationObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        relationshipWithButton.backgroundColor = UIColor.clear
        tabBarController?.tabBar.items![1].tag = UIApplication.shared.applicationIconBadgeNumber
    }
    
    //MARK : - Outlet Methods
    
    
    @IBAction func cancelPendingRelationshipRequest(_ sender: Any) {
        
                let deleteConfirmationViewController = UIAlertController(title: Constants.AlertPendingDeleteTitle, message: Constants.AlertPendingDeleteBody, preferredStyle: .alert)
                deleteConfirmationViewController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                deleteConfirmationViewController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (alert) in
        
                    
                    RelationshipChatRelationship.deleteRelationship(relationshipUID: self!.relationship!.relationshipUID, completionHandler: { (error) in
                        guard error == nil else {
                            self?.displayAlertWithTitle(Constants.DefaultErrorTitle, withBodyMessage: error!.localizedDescription, withBlock: nil)
                            
                            return
                        }
  
                        DispatchQueue.main.async {
                            self?.displayAlertWithTitle("You cancelled your pending request", withBodyMessage: "Your pending request was successfully cancelled", withBlock: nil)
                            self?.relationship = nil
                        }
                    })
                }))
        
                present(deleteConfirmationViewController, animated: true, completion: nil)
    }
    
    
    @IBAction func newRelationship(_ sender: Any) {
        if currentUser == nil {
            if loadingView.window == nil {
                loadUserInformation()
            }
        } else {
            performSegue(withIdentifier: Storyboard.NewRelationshipSegue, sender: self)
        }
    }
    //MARK: - Class methods
    
    fileprivate func setupRelationship() {
        
        func setupUIForPendingRelationship() {
            notInRelationshipView.isHidden = false
            newRelationshipButton.isHidden = true
            editButton.isEnabled = false
            relationshipWithButton.isEnabled = false
            relationshipStatus.text = Constants.BlankMessage
            relationshipStartDate.text = Constants.PendingStatusMessage
            tabBarController?.chatBarItem?.isEnabled = false
            cancelPendingRelationshipButton.isHidden = false
            statusLabel.text = Constants.StatusLabelTextDefault
        }
        
        func setupUIForInRelationship() {
            tabBarController?.chatBarItem?.isEnabled = true
            newRelationshipButton.isHidden = true
            statusLabel.text = Constants.StatusLabelTextRelationship
            editButton.isEnabled = true
            relationshipWithButton.isEnabled = true
            relationshipStatus.text = relationship!.status
            
            relationshipStartDate.text = dateFormatter.string(from: relationship!.startDate)
            
            embeddedUserDailyCheckIn?.currentRelationship = relationship
            
            notInRelationshipView.isHidden = true
            
            cancelPendingRelationshipButton.isHidden = true
        }
        
        let status = relationship!.status
        
        switch status {
        case RelationshipStatus.Pending :
            setupUIForPendingRelationship()
        default :
            setupUIForInRelationship()
        }

        //Get second user
        if let secondaryUserID = (relationship?.relationshipMembers.filter {
            $0 != self.currentUser!.userUID!
            }.first) {
            
            RelationshipChatUser.pullUserFromFB(uid: secondaryUserID, completionHandler: { (fetchedUser, error) in
                guard error == nil else {
                    print(error!)
                    return
                }
                DispatchQueue.main.async {
                    if fetchedUser != nil, self.relationship != nil {
                        self.secondaryUser = fetchedUser!
                    } else {
                        self.secondaryUser = nil
                    }
                }
                
            })
        }
    }
    
    
    
    
    
    
    fileprivate func unsetRelationship() {
        
        statusLabel.text = Constants.StatusLabelTextDefault
        relationshipStatus.text = Constants.DefaultRelationshipStatusMessage
        relationshipStartDate.text = Constants.DefaultDateText
        notInRelationshipView.isHidden = false
        newRelationshipButton.isHidden = false
        editButton.isEnabled = false
        tabBarController?.chatBarItem?.isEnabled = false
        secondaryUser = nil
        cancelPendingRelationshipButton.isHidden = true
        relationshipWithButton.imageView?.image = UIImage(named: "Dislike Filled-50")
        
    }
    
    //    fileprivate func addNotificationObserver() {
    //
    //        NotificationCenter.default.addObserver(forName: CloudKitNotifications.RelationshipRequestChannel, object: nil, queue: nil) { [weak self] (notification) in
    //
    //            if let relationshipRequest = notification.userInfo?[CloudKitNotifications.RelationshipRequestKey] as? CKQueryNotification {
    //
    //                let predicate = NSPredicate(format: "to = %@", self!.currentUser!)
    //                let query = CKQuery(recordType: Cloud.Entity.RelationshipRequest, predicate: predicate)
    //
    //                UIApplication.shared.isNetworkActivityIndicatorVisible = true
    //                Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: { (fetchedRecords, error) in
    //                    DispatchQueue.main.async {
    //                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    //                    }
    //                    if error != nil {
    //                        DispatchQueue.main.async {
    //                            _ = Cloud.errorHandling(error!, sendingViewController: self)
    //                        }
    //                    } else if let relationshipRequestRecord = fetchedRecords?.first {
    //
    //                        let requestSender = relationshipRequestRecord[Cloud.RelationshipRequestAttribute.Sender] as! CKReference
    //                        let requestRelationship = relationshipRequestRecord[Cloud.RelationshipRequestAttribute.Relationship] as! CKReference
    //
    //                        DispatchQueue.main.async {
    //                            UIApplication.shared.isNetworkActivityIndicatorVisible = true
    //                        }
    //                        Cloud.pullRelationshipRequest(fromSender: requestSender.recordID, relationshipRecordID: requestRelationship.recordID, relationshipRequestID: relationshipRequest.recordID!, presentingVC: self) {(sendingUsersRecord, requestedRelationshipRecord) in
    //                            DispatchQueue.main.async {
    //                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
    //
    //                                self?.sendersRecord = sendingUsersRecord
    //                                self?.requestedRelationship = requestedRelationshipRecord
    //                                self?.relationshipRequestID = relationshipRequest.recordID!
    //                                self?.navigationController?.popToRootViewController(animated: true)
    //                                self?.performSegue(withIdentifier: Storyboard.RelationshipConfirmationSegueID, sender: nil)
    //
    //                            }
    //
    //                        }
    //                    }
    //                })
    //            }
    //        }
    //
    //
    //        NotificationCenter.default.addObserver(forName: CloudKitNotifications.RelationshipUpdateChannel, object: nil, queue: nil) { [weak self] (notification) in
    //
    //            if let newRelationship = notification.userInfo?[CloudKitNotifications.RelationshipUpdateKey] as? CKQueryNotification {
    //
    //                UIApplication.shared.isNetworkActivityIndicatorVisible = true
    //                Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: newRelationship.recordID!) { (fetchedRecord, error) in
    //                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
    //                    if error != nil {
    //                        _ = Cloud.errorHandling(error!, sendingViewController: nil)
    //                    } else {
    //                        if let newRelationship = fetchedRecord {
    //                            self?.relationship = newRelationship
    //                        } else {
    //                            self?.relationship = nil
    //                        }
    //                    }
    //                }
    //            } else if let newRelationship = notification.userInfo?[CloudKitNotifications.RelationshipUpdateKey] as? CKRecord {
    //                DispatchQueue.main.async {
    //                    self?.relationship = newRelationship
    //                }
    //            } else {
    //                DispatchQueue.main.async {
    //                    self?.relationship = nil
    //
    //                }
    //            }
    //
    //        }
    //
    //        NotificationCenter.default.addObserver(forName: CloudKitNotifications.CurrentUserRecordUpdateChannel, object: nil, queue: OperationQueue.main) { [weak self](notification) in
    //            DispatchQueue.main.async {
    //                if let changedUsersRecord = notification.userInfo?[CloudKitNotifications.CurrentUserRecordUpdateKey] as? CKRecord {
    //
    //                    self?.currentUser = changedUsersRecord
    //                } else {
    //                    self?.currentUser = nil
    //                }
    //            }
    //        }
    //
    //        NotificationCenter.default.addObserver(forName: CloudKitNotifications.SecondaryUserUpdateChannel, object: nil, queue: nil) { [weak self] (notification) in
    //            if let newSecondaryUser = notification.userInfo?[CloudKitNotifications.SecondaryUserUpdateKey] as? CKQueryNotification {
    //
    //                Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: newSecondaryUser.recordID!, completionHandler: { (record, error) in
    //                    DispatchQueue.main.async {
    //                        if error != nil {
    //                            _ = Cloud.errorHandling(error!, sendingViewController: nil)
    //                        } else {
    //                            self?.secondaryUser = record!
    //                        }
    //                    }
    //                })
    //
    //            }
    //        }
    //
    //        NotificationCenter.default.addObserver(forName: CloudKitNotifications.MessageChannel, object: nil, queue: OperationQueue.main) { (_) in
    //
    //            //CRASH , this may crash
    //            guard let currentBadgeValue = Int((self.tabBarController?.chatBarItem?.badgeValue)!) else {
    //                return
    //            }
    //
    //            switch currentBadgeValue {
    //            case 0 :
    //                self.tabBarController?.chatBarItem?.badgeValue = "\(1)"
    //            default :
    //                self.tabBarController?.chatBarItem?.badgeValue = "\(currentBadgeValue + 1)"
    //            }
    //        }
    
    
    
    fileprivate func loadUserInformation() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            //Segue to login
            return
        }
        
        RelationshipChatUser.pullUserFromFB(uid: uid) { [weak self] (fetchedUser, error) in
            guard error == nil else {
                print(error!)
                return
            }
            DispatchQueue.main.async {
                if fetchedUser != nil {
                    self?.currentUser = fetchedUser!
                } else {
                    self?.currentUser = nil
                }
            }
            
        }
    }
    // MARK: - Navigation
    
    //    @IBAction func segueFromEditRelationVC(segue : UIStoryboardSegue) {
    //        if let ervc = segue.source as? EditRelationshipViewController {
    //            relationship = ervc.relationship
    //        }
    //    }
    //
    //    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    //        switch identifier {
    //        case Storyboard.EditProfileSegue:
    //            if relationship != nil {
    //                return true
    //            } else {
    //                return false
    //            }
    //        case Storyboard.NewRelationshipSegue:
    //            if currentUser != nil {
    //                return true
    //            } else {
    //                return false
    //            }
    //        default:
    //            return true
    //        }
    //    }
    //
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case Storyboard.EditProfileSegue:
                if let evc = segue.destination as? EditRelationshipViewController  {
                    evc.relationship = relationship
                }
            case Storyboard.NewRelationshipSegue:
                if let nrc = (segue.destination as? UINavigationController)?.visibleViewController as? NewRelationshipViewController {
                    nrc.currentUser = currentUser!
                }
            case Storyboard.RelationshipConfirmationSegueID :
                if let rvc = segue.destination as? RelationshipConfirmationViewController {
                    //TODO, figure out confirmation 
                }
            case Storyboard.UserDailyCheckInTableEmbedSegue :
                if let userDailyLocations = (segue.destination as? UINavigationController)?.contentViewController as? UserDailyCheckInTableViewController {
                    embeddedUserDailyCheckIn = userDailyLocations
                    userDailyLocations.presentingView = self.view
                }
            case Storyboard.ViewRelationshipWithSegue :
                if let relationshipWithVC = segue.destination as? RelationshipDetailsTableViewController {
                    relationshipWithVC.secondaryUser = secondaryUser
                }
            default:
                break
            }
        }
    }
}

