//
//  ProfileViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/12/16.
//  Copyright © 2016 KKW. All rights reserved.

//

import UIKit
import CloudKit
import ChameleonFramework


@available(iOS 10.0, *)
class ProfileViewController: UIViewController, UINavigationControllerDelegate {
    
    //MARK: - Constants
    struct Constants {
        fileprivate static let ImageViewRadius : CGFloat = 5.0
        
        fileprivate static let DefaultRelationshipText = "Single"
        
        static let DefaultRelationshipStarterText = "Since "
        
        static let DefaultPlaceholderText = " "
        
        static let FindingProfileMessage = "Trying to find your profile"
        static let LoadingProfileMessage = "Pulling up the details"
        static let FindingRelationshipMessage = "Seeing if you are in a relationship"
        static let LoadingRelationshipMessage = "Pulling up all the details"
        
        static let ActivityVCRequestMessage = "You recieved a relationship request..."
        
        static let DeclinedTitleText = "Your Relationship Request was denied"
        static let DeclinedBodyText = " has declined your request for a relationship"
        
        static let AcceptedTitleText = "Congratulations!"
        static let AcceptedBodyText = " has accepted your relationship request!"
        
        static var DefaultUserPicture : UIImage = {
            let picture = UIImage(named: "DefaultPicture")
            return picture!
        }()
        
        static let DefaultNotInARelationshipViewText = "You are not in a relationship"
        static let PendingNotInARelationshipViewText = "You have a pending relationship request!"
    }
    
    struct Storyboard {
        static let newProfileSegue = "Make New Profile Segue"
        static let editProfileSegue = "Edit Profile Segue"
        static let RelationshipConfirmationSegueID = "Relationship Confirmation Segue"
        static let NewActivitySegue = "New Activity"
        static let EmbeddedUserLocationsVC = "ActivityOverviewEmbedSegue"
    }
    
    //MARK: - Outlets
    
    @IBOutlet weak var viewDivider: UIView!
    @IBOutlet weak var notInARelationshipView: UIView! {
        didSet {
            notInARelationshipView.roundEdges()
        }
    }
    
    
    @IBOutlet weak var embedViewContainer: UIView! {
        didSet {
            embedViewContainer.roundEdges()
            embedViewContainer.clipsToBounds = true 
        }
    }
    
    @IBOutlet weak var changedImageButton: UIButton!
    
    @IBOutlet weak var userImageView: UIImageView! {
        didSet {
            userImageView.roundEdges()
            userImageView.clipsToBounds = true
        }
    }
    
    
    @IBOutlet weak var notInARelationshipLabel: UILabel!
    
    @IBOutlet fileprivate weak var relationshipPictureView: UIImageView! {
        didSet {
            relationshipPictureView.roundEdges()
            relationshipPictureView.image = Constants.DefaultUserPicture
        }
    }
    
    @IBOutlet weak var daysLabelTitle: UILabel!
    
    @IBOutlet weak var daysLabel: UILabel!
    
    @IBOutlet weak var gradientView: UIView! {
        didSet {
            gradientView.backgroundColor = UIColor(gradientStyle: .radial, withFrame: gradientView.bounds, andColors: GlobalConstants.defaultGradientColorArray)
        }
    }
    @IBOutlet fileprivate weak var relationshipType: UILabel! {
        didSet {
            relationshipType.text = " "
        }
    }
    @IBOutlet weak var newActivityButton: UIButton! {
        didSet {
            newActivityButton.isEnabled = false
            newActivityButton.roundEdges()
        }
    }
    @IBOutlet weak var newProfileButton: UIButton! {
        didSet {
            newProfileButton.roundEdges()
        }
    }
    
    // MARK: - Instance Variables
    
    fileprivate var embeddedVC : UpcomingActivitiesTableViewController?
    
    fileprivate lazy var loadingView : ActivityView = {
        let view = ActivityView(withMessage: "")
        return view
    }()
    
    fileprivate var relationshipStatus = Constants.DefaultRelationshipText {
        didSet {
            relationshipType.text = relationshipStatus
            
            if relationshipStatus != Constants.DefaultRelationshipText {
                daysLabelTitle.text = "\(relationshipStatus) for"
            } else {
                daysLabelTitle.text = "You Are"
            }
        }
    }
    
    fileprivate var relationshipStartDate : Date? {
        didSet {
            daysLabel.text = relationshipDaysText
        }
    }
    
    
    fileprivate var relationshipDaysText : String {
        get {
            let calendar = NSCalendar.current
            let currentDate = calendar.startOfDay(for: Date())
            let relationshipStartDate = calendar.startOfDay(for: self.relationshipStartDate!)
            let relationshipTime = calendar.dateComponents([.year, .month, .day], from: relationshipStartDate, to: currentDate)
            
            let daysText = relationshipTime.day! <= 1 ? "1 day" : "\(relationshipTime.day!) days"
            let yearsText = relationshipTime.year == 1 ? "\(relationshipTime.year!) year" : "\(relationshipTime.year!) years"
            let monthText = relationshipTime.month == 1 ? "\(relationshipTime.month!) month" : "\(relationshipTime.month!) months"
            
            if relationshipTime.year! > 0 && relationshipTime.month! > 0 {
                return "\(yearsText) \(monthText) \(daysText)"
            } else if relationshipTime.year! > 0 {
                return "\(yearsText) \(daysText)"
            } else if relationshipTime.month! > 0 {
                return "\(monthText) \(daysText)"
            } else {
                return daysText
            }
        }
    }
    
    
    fileprivate var userImage : UIImage? {
        get {
            return userImageView.image
        } set {
            userImageView.image = newValue
        }
    }
    
    fileprivate var relationshipUserImage : UIImage? {
        get {
            return relationshipPictureView.image
        } set {
            relationshipPictureView.image = newValue
        }
    }
    
    fileprivate var usersRecord : CKRecord? {
        didSet {
            
            if usersRecord != nil {
                newProfileButton.isHidden = true
                let userInfo = Cloud.pullUserInformationFrom(usersRecordToLoad: usersRecord!)
                userImage = userInfo.usersImage
                navigationItem.title = userInfo.usersFullName
            } else {
                navigationItem.title = " "
                newProfileButton.isHidden = false
            }
        }
    }
    fileprivate var secondaryUser : CKRecord? {
        didSet {
            if secondaryUser != nil {
                let userInfo = Cloud.pullUserInformationFrom(usersRecordToLoad: secondaryUser!)
                relationshipUserImage = userInfo.usersImage
            } else {
                relationshipUserImage = UIImage(named: "Breakup")
            }
        }
    }
    
    fileprivate var relationshipRecord : CKRecord? {
        didSet {
            if relationshipRecord != nil {
                switch relationshipRecord![Cloud.RelationshipAttribute.Status] as! String {
                case Cloud.RelationshipStatus.Pending :
                    notInARelationshipView.isHidden = false
                    tabBarController?.chatBarItem?.isEnabled = false
                    newActivityButton.isEnabled = false
                    notInARelationshipLabel.text = Constants.PendingNotInARelationshipViewText
                    secondaryUser = nil
                    daysLabelTitle.text = "Your relationship is"
                    daysLabel.text = "Pending"
                default :
                    tabBarController?.chatBarItem?.isEnabled = true
                    newActivityButton.isEnabled = true
                    notInARelationshipView.isHidden = true
                    relationshipStatus = relationshipRecord![Cloud.RelationshipAttribute.Status] as! String
                    relationshipStartDate = relationshipRecord![Cloud.RelationshipAttribute.StartDate] as? Date
                    embeddedVC?.relationshipRecord = relationshipRecord
                    if let startDate = relationshipRecord![Cloud.RelationshipAttribute.StartDate] as? Date {
                        relationshipStartDate = startDate
                    }
                    
                }
                
            } else {
                daysLabelTitle.text = "You Are"
                relationshipStatus = Constants.DefaultRelationshipText
                notInARelationshipLabel.text = Constants.DefaultNotInARelationshipViewText
                notInARelationshipView.isHidden = false
                tabBarController?.chatBarItem?.isEnabled = false
                newActivityButton.isEnabled = false
                secondaryUser = nil
            }
        }
    }
    //Relationship request variables
    fileprivate var sendersRecord : CKRecord?
    fileprivate var requestedRelationship : CKRecord?
    fileprivate var relationshipRequestID : CKRecordID?
    
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        addNotificationObserver()
        let backButton = UIBarButtonItem()
        backButton.title = "Profile"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        changedImageButton.backgroundColor = UIColor.clear
        newActivityButton.backgroundColor = UIColor.clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        if FileManager.default.ubiquityIdentityToken == nil {
            
            let alertController = UIAlertController(title: "Not signed into iCloud", message: "Please sign into your iCloud account", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) in
                UIApplication.shared.open(URL(string: "App-Prefs:root=CASTLE")!, options: [:], completionHandler: nil)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            
        } else {
            if usersRecord == nil {
                pullUsersRecord()
            }
            tabBarController?.tabBar.items![1].tag = UIApplication.shared.applicationIconBadgeNumber
            checkRelationshipRequests()
            checkRelationshipRequestResponse()
        }
        
    }
    
    //MARK: - Class Functions
    
    
    @IBAction func changeImage(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picturePicker = UIImagePickerController()
            picturePicker.delegate = self
            picturePicker.sourceType = .photoLibrary
            picturePicker.allowsEditing = true
            self.present(picturePicker, animated: true, completion: nil)
        }
    }
    
    fileprivate func checkRelationshipRequests() {
        
        if relationshipRecord == nil && usersRecord != nil {
            let predicate = NSPredicate(format: "to = %@", usersRecord!)
            let query = CKQuery(recordType: Cloud.Entity.RelationshipRequest, predicate: predicate)
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: { (fetchedRequests, error) in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    return
                }
                
                guard let request = fetchedRequests?.first, let relationship = request[Cloud.RelationshipRequestAttribute.Relationship] as? CKReference, let sendingUsersReference = request[Cloud.RelationshipRequestAttribute.Sender] as? CKReference else {
                    return
                }
            
                Cloud.pullRelationshipRequest(fromSender: sendingUsersReference.recordID, relationshipRecordID: relationship.recordID, relationshipRequestID: request.recordID, presentingVC: self, completionHandler: { [weak weakSelf = self] (sendingUsersRecord, relationshipRequestedRecord) in
                    DispatchQueue.main.async {
                        weakSelf?.sendersRecord = sendingUsersRecord
                        weakSelf?.requestedRelationship = relationshipRequestedRecord
                        weakSelf?.relationshipRequestID = request.recordID
                        weakSelf?.performSegue(withIdentifier: Storyboard.RelationshipConfirmationSegueID, sender: self)
                    }
                    
                })
                
                
                
                
            })
            
        }
    }
    
    fileprivate func checkRelationshipRequestResponse() {
        
        if relationshipRecord?[Cloud.RelationshipAttribute.Status] as? String == Cloud.RelationshipStatus.Pending && usersRecord != nil {
            let predicate = NSPredicate(format: "to = %@", usersRecord!)
            let query = CKQuery(recordType: Cloud.Entity.RelationshipRequestResponse, predicate: predicate)
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil) {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                guard $1 == nil else {
                    _ = Cloud.errorHandling($1!, sendingViewController: self)
                    return
                }
                
                
                guard let relationResponseStatus = ($0?.first)?[Cloud.RelationshipRequestResponseAttribute.StatusUpdate] as? String else {
                    print("no relationship response status")
                    return
                }
                
                switch relationResponseStatus {
                case Cloud.Status.Accepted :
                    self.acceptedRelationshipResponseSetup()
                case Cloud.Status.Declined :
                    self.declinedRelationshipResponseSetup()
                default :
                    break
                }
                
                for record in $0! {
                    Cloud.deleteRecord(record.recordID, presentingVC: self, completionBlock: nil)
                }
                
            }
        }
    }
    
    
    fileprivate func addNotificationObserver() {
        
        //Add notification observer for messages, to update chat tab bar badge
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.RelationshipUpdateChannel, object: nil, queue: nil) { [weak self] (notification) in

            if let updatedRelationship = notification.userInfo?[CloudKitNotifications.RelationshipUpdateKey] as? CKQueryNotification {
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: updatedRelationship.recordID!, completionHandler: { [weak weakSelf = self] (newRelationship, error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    if error != nil {
                        _ = _ = Cloud.errorHandling(error!, sendingViewController: nil)
                    } else {
                        DispatchQueue.main.async {
                            weakSelf?.relationshipRecord = newRelationship!
                        }
                    }
                })
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
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.SecondaryUserUpdateChannel, object: nil, queue: nil) { [weak self] (notification) in
            if let updatedSecondaryUser = notification.userInfo?[CloudKitNotifications.SecondaryUserUpdateKey] as? CKQueryNotification {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: updatedSecondaryUser.recordID!, completionHandler: { (newSecondaryUser, error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    if error != nil {
                        _ = Cloud.errorHandling(error!, sendingViewController: nil)
                    } else {
                        DispatchQueue.main.async {
                            self?.secondaryUser = newSecondaryUser!
                            
                        }
                    }
                })
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.RelationshipRequestChannel, object: nil, queue: nil) { [weak self](notification) in
            
            if let relationshipRequest = notification.userInfo?[CloudKitNotifications.RelationshipRequestKey] as? CKQueryNotification {
                
                let predicate = NSPredicate(format: "to = %@", (self?.usersRecord)!)
                let query = CKQuery(recordType: Cloud.Entity.RelationshipRequest, predicate: predicate)
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: { (fetchedRecords, error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    if error != nil {
                        DispatchQueue.main.async {
                            _ = Cloud.errorHandling(error!, sendingViewController: self)
                        }
                    } else if let relationshipRequestRecord = fetchedRecords?.first {
                        
                        let requestSender = relationshipRequestRecord[Cloud.RelationshipRequestAttribute.Sender] as! CKReference
                        let requestRelationship = relationshipRequestRecord[Cloud.RelationshipRequestAttribute.Relationship] as! CKReference
                        DispatchQueue.main.async {
                            UIApplication.shared.isNetworkActivityIndicatorVisible = true
                        }
                        Cloud.pullRelationshipRequest(fromSender: requestSender.recordID, relationshipRecordID: requestRelationship.recordID, relationshipRequestID: relationshipRequest.recordID!, presentingVC: self) {(sendingUsersRecord, requestedRelationshipRecord) in
                            
                            DispatchQueue.main.async {
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
       
            NotificationCenter.default.addObserver(forName: CloudKitNotifications.RelationshipRequestResponseChannel, object: nil, queue: nil) { [weak self] (notification) in
                if let relationshipRequestResponse = notification.userInfo?[CloudKitNotifications.RelationshipRequestResponseKey] as? CKQueryNotification {
                    
                    if let updateStatus = relationshipRequestResponse.recordFields?[Cloud.RelationshipRequestResponseAttribute.StatusUpdate] as? String {
                        Cloud.deleteRecord(relationshipRequestResponse.recordID!, presentingVC: self, completionBlock: nil)
                        
                        switch updateStatus {
                        case Cloud.Status.Accepted :
                            self?.acceptedRelationshipResponseSetup()
                        case Cloud.Status.Declined :
                            self?.declinedRelationshipResponseSetup()
                        default :
                            break
                        }
                    }
                    
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.CurrentUserRecordUpdateChannel, object: nil, queue: nil) { [weak self](notification) in
            DispatchQueue.main.async {
                self?.usersRecord = notification.userInfo?[CloudKitNotifications.CurrentUserRecordUpdateKey] as? CKRecord
            }
        }
        
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.ActivityDeletedChannel, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
            
            let deletedRecordID : CKRecordID
            
            if let deletedRecord = notification.userInfo?[CloudKitNotifications.ActivityDeletedKey] as? CKQueryNotification {
                deletedRecordID = deletedRecord.recordID!
            } else {
                deletedRecordID = notification.userInfo![CloudKitNotifications.ActivityDeletedKey] as! CKRecordID
            }
            
            
            if let relationshipActivities = self?.relationshipRecord?[Cloud.RelationshipAttribute.Activities] as? [CKReference] {
                self?.relationshipRecord![Cloud.RelationshipAttribute.Activities] = (relationshipActivities.filter { $0.recordID != deletedRecordID }) as CKRecordValue?
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                Cloud.CloudDatabase.PublicDatabase.save((self?.relationshipRecord!)!, completionHandler: { (savedRelationshipRecord, error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    if error != nil {
                        _ = Cloud.errorHandling(error!, sendingViewController: self)
                    }
                })
            }
        }
    }
    
    
    fileprivate func pullUsersRecord() {
        DispatchQueue.main.async {
            
            self.view.addSubview(self.loadingView)
            self.loadingView.center = self.view.center
            self.loadingView.updateMessageWith(message: Constants.FindingProfileMessage)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        CKContainer.default().fetchUserRecordID { [weak self] (userRecordID, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            guard error == nil else {
                DispatchQueue.main.async {
                    self?.loadingView.removeFromSuperview()
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    print(error!)
                }
                return
            }
            
            let predicate = NSPredicate(format: "creatorUserRecordID = %@", userRecordID!)
            let query = CKQuery(recordType: Cloud.Entity.User, predicate: predicate)
            DispatchQueue.main.async {
                self?.loadingView.updateMessageWith(message: Constants.LoadingProfileMessage)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                guard error == nil else {
                    DispatchQueue.main.async {
                        self?.loadingView.removeFromSuperview()
                    }
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    return
                }
                
                guard let userRecord = records?.first else {
                    DispatchQueue.main.async {
                        self?.loadingView.removeFromSuperview()
                        self?.performSegue(withIdentifier: Storyboard.newProfileSegue, sender: self)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.usersRecord = userRecord
                    if self?.usersRecord?[Cloud.UserAttribute.Relationship] != nil {
                        self?.loadRelationship()
                    } else {
                        self?.loadingView.removeFromSuperview()
                        self?.relationshipRecord = nil
                        self?.checkRelationshipRequests()
                        self?.checkRelationshipRequestResponse()
                    }
                    
                }
                
            })
            
            
        }
    }
    
    private func loadRelationship() {
        
        let relationshipUserReference = usersRecord?[Cloud.UserAttribute.Relationship] as! CKReference
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.loadingView.updateMessageWith(message: Constants.FindingRelationshipMessage)
        }
        Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: relationshipUserReference.recordID, completionHandler: { [weak self] (fetchedRelationship, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            guard error == nil else {
                DispatchQueue.main.async {
                    self?.loadingView.removeFromSuperview()
                }
                _ = Cloud.errorHandling(error!, sendingViewController: self)
                //Relationship not found
                if error!._code == 11 {
                    self?.usersRecord![Cloud.UserAttribute.Relationship] = nil
                    Cloud.CloudDatabase.PublicDatabase.save(self!.usersRecord!) {
                        guard $1 == nil else {
                            _ = Cloud.errorHandling(error!, sendingViewController: self)
                            return
                        }
                    }
                }
                return
            }
            
            guard let relationship = fetchedRelationship else {
                DispatchQueue.main.async {
                    self?.loadingView.removeFromSuperview()
                    self?.relationshipRecord = nil
                }
                return
            }
            
            guard let secondaryUserID = ((relationship[Cloud.RelationshipAttribute.Users] as? [CKReference])?.filter { $0.recordID != self?.usersRecord?.recordID})?.first else {
                DispatchQueue.main.async {
                    self?.loadingView.removeFromSuperview()
                    
                }
                return
            }
            
            
            DispatchQueue.main.async {
                self?.relationshipRecord = relationship
                self?.loadingView.updateMessageWith(message: Constants.LoadingRelationshipMessage)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: secondaryUserID.recordID, completionHandler: { (secondaryUserRecord, error) in
                DispatchQueue.main.async {
                    self?.loadingView.removeFromSuperview()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    return
                }
                
                guard secondaryUserRecord != nil else{
                    return
                }
                
                DispatchQueue.main.async {
                    self?.secondaryUser = secondaryUserRecord!
                }
            })
        })
    }
    
    fileprivate func acceptedRelationshipResponseSetup() {
        
        if relationshipRecord != nil && usersRecord != nil {
            
            Cloud.addsubscriptionToSecondaryUserChanges(currentRelationship: relationshipRecord!, currentUserRecord: usersRecord!)
            
            Cloud.saveMessageSubscription(relationshipRecord!, currentUser: usersRecord!)
            
            self.displayAlertWithTitle(Constants.AcceptedTitleText, withBodyMessage: Constants.AcceptedBodyText, withBlock: nil)
            
            Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: (relationshipRecord?.recordID)!, completionHandler: { [weak self] (newRelationship, error) in
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    print(error!)
                    return
                }
                
                guard newRelationship != nil else {
                    print("error fetching updated relationship")
                    return
                }
                
                self?.relationshipRecord = newRelationship
                
            })
        }
    }
    
    fileprivate func declinedRelationshipResponseSetup() {
        
        self.usersRecord![Cloud.UserAttribute.Relationship] = nil
        self.relationshipRecord = nil
        
        
        let declinedRelationshipRecordsOp = CKModifyRecordsOperation(recordsToSave: [self.usersRecord!], recordIDsToDelete: [self.relationshipRecord!.recordID])
        declinedRelationshipRecordsOp.modifyRecordsCompletionBlock = { [weak self] (savedRecords, deletedRecords, error) in
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: self)
                return
            }
            
            DispatchQueue.main.async {
                self?.displayAlertWithTitle(Constants.DeclinedTitleText, withBodyMessage: Constants.DeclinedBodyText, withBlock: nil)
            }
            NotificationCenter.default.post(name: CloudKitNotifications.CurrentUserRecordUpdateChannel, object: nil, userInfo: [CloudKitNotifications.CurrentUserRecordUpdateKey : (self?.usersRecord)!])
            NotificationCenter.default.post(name: CloudKitNotifications.RelationshipUpdateChannel, object: nil, userInfo: nil)
            
        }
        
        Cloud.CloudDatabase.PublicDatabase.add(declinedRelationshipRecordsOp)
        
    }
    //MARK: - Navigation
    
    
    @IBAction func unwindFromNewProfile(segue : UIStoryboardSegue) {
        if let evc = segue.source as? EditProfileViewController {
            DispatchQueue.main.async {
                self.usersRecord = evc.mainUserRecord
            }
        }
    }
    
    
    
    @IBAction func unwindFromNewActivity(segue : UIStoryboardSegue) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.editProfileSegue :
                if let dvc = segue.destination as? EditProfileViewController {
                    dvc.mainUserRecord = usersRecord
                } else {
                    break
                }
            case Storyboard.RelationshipConfirmationSegueID :
                if let rvc = segue.destination as? RelationshipConfirmationViewController {
                    rvc.relationship = requestedRelationship
                    rvc.sendersRecord = sendersRecord
                    rvc.usersRecord = usersRecord
                    rvc.relationshipRequestID = relationshipRequestID
                }
            case Storyboard.NewActivitySegue :
                if let nvc = segue.destination as? NewActivityViewController {
                    nvc.relationship = relationshipRecord
                }
            case Storyboard.EmbeddedUserLocationsVC :
                if let uctvc = (segue.destination as? UINavigationController)?.contentViewController as? UpcomingActivitiesTableViewController {
                    embeddedVC = uctvc
                }
            default : break
            }
        }
    }
    
}

//MARK: - Image Controller delegate

@available(iOS 10.0, *)
extension ProfileViewController : UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let imageInfo = picker.savePickedImageLocally(info)
        usersRecord![Cloud.UserAttribute.ProfileImage] = CKAsset(fileURL: imageInfo.fileURL!)
        RCCache.shared[usersRecord?.recordID.recordName as AnyObject] = imageInfo.image
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        Cloud.CloudDatabase.PublicDatabase.save(usersRecord!) { (savedRecord, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: nil)
                return
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: CloudKitNotifications.CurrentUserRecordUpdateChannel, object: nil, userInfo: [CloudKitNotifications.CurrentUserRecordUpdateKey : savedRecord as Any])
            }
        }
        
        userImage = imageInfo.image
        self.dismiss(animated: true, completion: nil)
    }
}
