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
        
        static let PageControlYOffSet : CGFloat = 50
    }
    
    //MARK: - Storyboard Constants
    struct Storyboard {
        static let NewProfileSegue = "Make New Profile Segue"
        static let EditProfileSegue = "Edit Profile Segue"
        static let RelationshipConfirmationSegueID = "Relationship Confirmation Segue"
        static let PageViewEmbedSegueID = "ActivityOverviewEmbedSegue"
        
        static let UpcomingActivityVCID = "Upcoming VC"
        static let PastActivityVCID = "Previous VC"
        
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
    
    @IBOutlet weak var newProfileButton: UIButton! {
        didSet {
            newProfileButton.roundEdges()
            newProfileButton.backgroundColor = UIColor.flatPurple()
        }
    }
    
    // MARK: - PageView Controller Storyboard
    
    lazy var activityViewControllers : [UIViewController] = {
        let activityVCs = [
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Storyboard.UpcomingActivityVCID),
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Storyboard.PastActivityVCID)
        ]
        
        self.upcomingActivityVC = (activityVCs.first as? UINavigationController)?.contentViewController as? UpcomingActivitiesTableViewController
        self.pastActivityVC = (activityVCs.last as? UINavigationController)?.contentViewController as? ActivityTableViewController
        
        return activityVCs
    }()
    
    // MARK: - PageViewController VCs
    fileprivate var upcomingActivityVC : UpcomingActivitiesTableViewController? {
        didSet {
            upcomingActivityVC?.dataSource = self
        }
    }
    fileprivate var pastActivityVC : ActivityTableViewController? {
        didSet {
            pastActivityVC?.dataSource = self
        }
    }
    
    // MARK: - Page Control Properties
    private lazy var pageControl : UIPageControl = {
        
        let pageCtrl = UIPageControl(frame: CGRect(x: 0, y: view.bounds.maxY - Constants.PageControlYOffSet * 2, width: view.bounds.width, height: Constants.PageControlYOffSet))
        
        pageCtrl.numberOfPages = activityViewControllers.count
        pageCtrl.currentPage = 0
        pageCtrl.tintColor = UIColor.flatPurple()
        pageCtrl.pageIndicatorTintColor = UIColor.gray
        pageCtrl.currentPageIndicatorTintColor = UIColor.flatPurple()
        pageCtrl.isUserInteractionEnabled = false
        return pageCtrl
    }()
    
    fileprivate var embeddedVC : UIPageViewController? {
        didSet {
            if let initialVC = activityViewControllers.first {
                embeddedVC?.setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
            }
            view.addSubview(pageControl)
            print(pageControl)
        }
    }
    
    //MARK: - Instance Properties
    fileprivate lazy var loadingView : ActivityView = {
        let view = ActivityView(withMessage: "")
        return view
    }()
    
    fileprivate var relationshipActivities = [RelationshipActivity]() {
        didSet {
            
            //Reset the arrays so there is a double of everything 
            upcomingActivities = []
            pastActivities = []
            //This is readding everything to the arrays, clear upcoming and past activities
            for activty in relationshipActivities {
                if activty.daysUntilActivity < 0 {
                    pastActivities.append(activty)
                } else {
                    upcomingActivities.append(activty)
                }
            }
        }
    }
    
    var upcomingActivities = [RelationshipActivity]() {
        didSet {
            upcomingActivityVC?.activities = upcomingActivities
        }
    }
    var pastActivities = [RelationshipActivity]() {
        didSet {
            pastActivityVC?.activities = pastActivities
        }
    }
    
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
                    pageControl.isHidden = true 
                    embedViewContainer.isHidden = true
                    notInARelationshipView.isHidden = false
                    tabBarController?.chatBarItem?.isEnabled = false
                    notInARelationshipLabel.text = Constants.PendingNotInARelationshipViewText
                    secondaryUser = nil
                    daysLabelTitle.text = "Your relationship is"
                    daysLabel.text = "Pending"
                default :
                    pageControl.isHidden = false
                    embedViewContainer.isHidden = false
                    tabBarController?.chatBarItem?.isEnabled = true
                    notInARelationshipView.isHidden = true
                    relationshipStatus = relationshipRecord![Cloud.RelationshipAttribute.Status] as! String
                    relationshipStartDate = relationshipRecord![Cloud.RelationshipAttribute.StartDate] as? Date
                    
                    if let startDate = relationshipRecord![Cloud.RelationshipAttribute.StartDate] as? Date {
                        relationshipStartDate = startDate
                    }
                    
                    if let relationshipActivities = relationshipRecord![Cloud.RelationshipAttribute.Activities] as? [CKReference] {
                        loadActivitiesFrom(newRelationshipActivityReferences: relationshipActivities)
                    }
                    
                }
                
            } else {
                pageControl.isHidden = true
                embedViewContainer.isHidden = true
                daysLabelTitle.text = "You Are"
                relationshipStatus = Constants.DefaultRelationshipText
                notInARelationshipLabel.text = Constants.DefaultNotInARelationshipViewText
                notInARelationshipView.isHidden = false
                tabBarController?.chatBarItem?.isEnabled = false
                secondaryUser = nil
            }
        }
    }
    // MARK: - Relationship request variables
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
    
    //MARK: - Image Picking
    
    
    @IBAction func changeImage(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picturePicker = UIImagePickerController()
            picturePicker.delegate = self
            picturePicker.sourceType = .photoLibrary
            picturePicker.allowsEditing = true
            self.present(picturePicker, animated: true, completion: nil)
        }
    }
    
    //MARK: - Relationship request checking functions
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
            Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil) { [weak self] (relationshipResponses, error) in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    return
                }
                
                
                guard let relationResponseStatus = relationshipResponses?.first?[Cloud.RelationshipRequestResponseAttribute.StatusUpdate] as? String else {
                    print("no relationship response status")
                    return
                }
                
                switch relationResponseStatus {
                case Cloud.Status.Accepted :
                    self?.acceptedRelationshipResponseSetup()
                case Cloud.Status.Declined :
                    self?.declinedRelationshipResponseSetup()
                default :
                    break
                }
                
                let deleteResponsesOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: relationshipResponses?.map {
                    $0.recordID
                    })
                
                Cloud.CloudDatabase.PublicDatabase.add(deleteResponsesOperation)
                
            }
        }
    }
    
    // MARK: - Notification Observers
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
                        
                        Cloud.CloudDatabase.PublicDatabase.delete(withRecordID: relationshipRequestResponse.recordID!, completionHandler: { (_, error) in
                            guard error == nil else {
                                _ = Cloud.errorHandling(error!, sendingViewController: self)
                                return
                            }
                            
                            switch updateStatus {
                            case Cloud.Status.Accepted :
                                self?.acceptedRelationshipResponseSetup()
                            case Cloud.Status.Declined :
                                self?.declinedRelationshipResponseSetup()
                            default :
                                break
                            }
                            
                        })
                        
                    }
                    
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.CurrentUserRecordUpdateChannel, object: nil, queue: nil) { [weak self](notification) in
            DispatchQueue.main.async {
                self?.usersRecord = notification.userInfo?[CloudKitNotifications.CurrentUserRecordUpdateKey] as? CKRecord
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.ActivityUpdateChannel, object: nil, queue: OperationQueue.main) { (notification) in
            if let newActivity = notification.userInfo?[CloudKitNotifications.ActivityUpdateKey] as? CKRecord {
                DispatchQueue.main.async {
                    self.convertRecordsToActivities(records: [newActivity])
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.MessageChannel, object: nil, queue: OperationQueue.main) { (_) in
            
            //CRASH, this may crash 
            guard let currentBadgeValue = Int((self.tabBarController?.chatBarItem?.badgeValue)!) else {
                return
            }
            
            switch currentBadgeValue {
            case 0 :
                self.tabBarController?.chatBarItem?.badgeValue = "\(1)"
            default :
                self.tabBarController?.chatBarItem?.badgeValue = "\(currentBadgeValue + 1)"
            }
        }
    }
    
    // MARK: - User Record functions
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
                        self?.performSegue(withIdentifier: Storyboard.NewProfileSegue, sender: self)
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
    
    // MARK: - Relationship response functions
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.EditProfileSegue :
                if let dvc = segue.destination as? EditProfileViewController {
                    dvc.mainUserRecord = usersRecord
                }
            case Storyboard.RelationshipConfirmationSegueID :
                if let rvc = segue.destination as? RelationshipConfirmationViewController {
                    rvc.relationship = requestedRelationship
                    rvc.sendersRecord = sendersRecord
                    rvc.usersRecord = usersRecord
                    rvc.relationshipRequestID = relationshipRequestID
                }
            case Storyboard.PageViewEmbedSegueID :
                if let evc = segue.destination as? UIPageViewController {
                    evc.delegate = self
                    evc.dataSource = self
                    embeddedVC = evc
                }
            default : break
            }
        }
    }
    
    // MARK: - Activity Functions
    fileprivate func loadActivitiesFrom(newRelationshipActivityReferences : [CKReference]) {
        
        let currentActivityRecordIDs = relationshipActivities.map {
            $0.activityRecord.recordID
        }
        
        //Filter out new activities from current activities so there is no need to double fetch
        let newActivities = newRelationshipActivityReferences.filter { !currentActivityRecordIDs.contains($0.recordID)}.map {
            $0.recordID
        }
        
        let fetchAllActivitiesOperation = CKFetchRecordsOperation(recordIDs: newActivities)
        
        fetchAllActivitiesOperation.fetchRecordsCompletionBlock = {[weak self] (newActivityRecords, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: self )
                return
            }
            let activityRecords = Array(newActivityRecords!.values)
            self?.relationshipActivities = []
            self?.relationshipActivities = (self?.convertRecordsToActivities(records: activityRecords))!
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        Cloud.CloudDatabase.PublicDatabase.add(fetchAllActivitiesOperation)
    }
    
    fileprivate func convertRecordsToActivities(records : [CKRecord]) -> [RelationshipActivity] {
        
        let calendar = NSCalendar.current
        let currentDate = calendar.startOfDay(for: Date())
        let currentYear = calendar.component(.year, from: currentDate)
        
        var activityDateComponents = DateComponents()
        
        var activitiesArray = [RelationshipActivity]()
        
        func addSystemActivity(recordToBeConverted : CKRecord) {
            activityDateComponents.year = currentYear
            
            var systemMadeActivityDate = calendar.date(from: activityDateComponents)!
            
            let dateComparison = calendar.compare(systemMadeActivityDate, to: currentDate, toGranularity: .day)
            
            if dateComparison == .orderedAscending {
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: systemMadeActivityDate)
                dateComponents.year = currentYear + 1
                systemMadeActivityDate = calendar.date(from: dateComponents)!
            }
            
            let dayDifference = calendar.dateComponents([.day], from: currentDate, to: systemMadeActivityDate).day!
            
            let newActivity = RelationshipActivity(daysUntilActivity: dayDifference, activityRecord: recordToBeConverted, activityDate: systemMadeActivityDate)
            
            activitiesArray.append(newActivity)
            
        }
        
        func addActivity(recordToBeConverted : CKRecord) {
            let activityDate = calendar.date(from: activityDateComponents)!
            
            let days = calendar.dateComponents([.day], from: currentDate, to: activityDate).day!
            
            let newActivity = RelationshipActivity(daysUntilActivity: days, activityRecord: recordToBeConverted, activityDate: activityDate)
            
            activitiesArray.append(newActivity)
        }
        
        for record in records {
            
            activityDateComponents = calendar.dateComponents([.year, .month, .day], from: record[Cloud.RelationshipActivityAttribute.CreationDate] as! Date)
            
            if record[Cloud.RelationshipActivityAttribute.SystemCreated] != nil {
                addSystemActivity(recordToBeConverted: record)
            } else {
                addActivity(recordToBeConverted: record)
            }
        }
        
        return activitiesArray
    }
    
}

// MARK: - Image Controller delegate

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

// MARK: - ProfileViewController DataSource
extension ProfileViewController : UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        let pageContentVC = pageViewController.viewControllers![0]
        self.pageControl.currentPage = activityViewControllers.index(of: pageContentVC)!
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let currentIndex = activityViewControllers.index(of: viewController) else {
            return nil
        }
        
        if currentIndex <= 0 {
            return activityViewControllers.last
        } else {
            return activityViewControllers[currentIndex - 1]
        }
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let currentIndex = activityViewControllers.index(of: viewController) else {
            return nil
        }
        
        if currentIndex >= activityViewControllers.count - 1 {
            return activityViewControllers.first
        } else {
            return activityViewControllers[currentIndex + 1]
        }
    }
    
}

extension ProfileViewController : ActivityTableViewControllerDataSource {
    
    func addActivity(newActivityToSave: CKRecord, completionHandler : ((Bool?, Error?)->Void)?) {
        
        newActivityToSave[Cloud.RelationshipActivityAttribute.Relationship] = CKReference(record: relationshipRecord!, action: .deleteSelf) as CKRecordValue?
        
        var relationshipActivityArray = relationshipRecord![Cloud.RelationshipAttribute.Activities] as! [CKReference]
        let activityReference = CKReference(record: newActivityToSave, action: .none)
        relationshipActivityArray.append(activityReference)
        
        
        relationshipRecord![Cloud.RelationshipAttribute.Activities] = relationshipActivityArray as CKRecordValue?
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true

        }
        //save new activity and relationship
        
        let saveActivityOp = CKModifyRecordsOperation(recordsToSave: [newActivityToSave, relationshipRecord!], recordIDsToDelete: nil)
        
        saveActivityOp.modifyRecordsCompletionBlock = { [weak self] in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false

            }
            guard $2 == nil else {
                _ = Cloud.errorHandling($2!, sendingViewController: nil)
                completionHandler?(false, $2)
                return
            }
            
            let savedActivity = $0?.filter { ($0[Cloud.RecordKeys.RecordType] as? String) == Cloud.Entity.RelationshipActivity }.first
            completionHandler?(true, nil)

            self?.relationshipActivities.append(self!.convertRecordsToActivities(records: [savedActivity!]).first!)
        }
        
        Cloud.CloudDatabase.PublicDatabase.add(saveActivityOp)
    }
    
    func inAValidRelationshipCheck() -> Bool {
        guard relationshipRecord != nil else {
            return false
        }
        
        switch relationshipRecord![Cloud.RelationshipAttribute.Status] as! String {
        case Cloud.RelationshipStatus.Pending, Cloud.RelationshipStatus.Single:
            return false
        default:
            return true
        }
    }
    
    func deleteActivity(activityRecordID: CKRecordID) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        //Set original activities as a backup incase save fails
        let originalActivities = relationshipRecord![Cloud.RelationshipAttribute.Activities] as CKRecordValue?
        
        //Update relationship record to account for swiped activity that needs to be deleted
        relationshipRecord![Cloud.RelationshipAttribute.Activities] = (relationshipRecord![Cloud.RelationshipAttribute.Activities] as! [CKReference]).filter {
            $0.recordID.recordName != activityRecordID.recordName
            } as CKRecordValue?
        
        let modifyRecordsOp = CKModifyRecordsOperation(recordsToSave: [relationshipRecord!], recordIDsToDelete: [activityRecordID])
        
        modifyRecordsOp.modifyRecordsCompletionBlock = { [weak self] (savedRecords, deletedRecordIDs, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            guard error == nil else {
                self?.relationshipRecord![Cloud.RelationshipAttribute.Activities] = originalActivities
                print(error!)
                return
            }
            self?.relationshipActivities = (self?.relationshipActivities.filter {
                $0.activityRecord.recordID != deletedRecordIDs?.first
                })!
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        Cloud.CloudDatabase.PublicDatabase.add(modifyRecordsOp)
    }
}
