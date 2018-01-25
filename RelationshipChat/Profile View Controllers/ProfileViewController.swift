//
//  ProfileViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/12/16.
//  Copyright © 2016 KKW. All rights reserved.

//

import UIKit
import Firebase
import ChameleonFramework


@available(iOS 10.0, *)
class ProfileViewController: UIViewController, UINavigationControllerDelegate {
    
    //MARK: - Constants
    struct Constants {
        fileprivate static let ImageViewRadius : CGFloat = 5.0
        
        fileprivate static let DefaultRelationshipText = "Single"
        
        static let DefaultRelationshipStarterText = "Since "
        
        static let DefaultPlaceholderText = " "
        static let DefaultErrorTitle = "Oops!"
        
        static let FindingProfileMessage = "Trying to find your profile"
        static let LoadingProfileMessage = "Pulling up the details"
        static let FindingRelationshipMessage = "Seeing if you are in a relationship"
        static let LoadingRelationshipMessage = "Pulling up all the details"
        
        static let ActivityVCRequestMessage = "You recieved a relationship request..."
        
        static let DeclinedTitleText = "Your Relationship Request was denied"
        static let DeclinedBodyText = " has declined your request for a relationship"
        
        static let AcceptedTitleText = "Congratulations!"
        static let AcceptedBodyText = " has accepted your relationship request!"
        
        static let RelationshipRecordDeletedTitle = "Your relationship no longer exists"
        static let RelationshipRecordDeletedBody = "Your relationship was ended or your request was denied"
        
        static let ProfileRecordDeletedTitle = "Your profile can no longer found"
        static let ProfileRecordDeletedBody = "Your profile was deleted or can not be found, please create a new one"
        
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
        static let LoginSegue = "Login Segue"
        static let NewProfileSegue = "Make New Profile Segue"
        static let EditProfileSegue = "Edit Profile Segue"
        static let RelationshipConfirmationSegueID = "Relationship Confirmation Segue"
        static let PageViewEmbedSegueID = "ActivityOverviewEmbedSegue"
        
        static let UpcomingActivityVCID = "Upcoming VC"
        static let PastActivityVCID = "Previous VC"
        
    }
    
    //MARK: - Outlets
    
    @IBOutlet weak var viewDivider: UIView!
    
    @IBOutlet weak var notInARelationshipView: UIView!
    
    @IBOutlet weak var editProfileButton: UIBarButtonItem!
    
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    
    @IBOutlet weak var embedViewContainer: UIView! 
    
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
    
    @IBOutlet weak var pageControlContainerView: UIView! {
        didSet {
            pageControlContainerView.roundEdges()
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
    fileprivate var upcomingActivityVC : UpcomingActivitiesTableViewController?
    fileprivate var pastActivityVC : ActivityTableViewController?
    
    // MARK: - Page Control Properties
    private lazy var pageControl : UIPageControl = {
        
        
        //TODO, put the page control above 
        let pageCtrl = UIPageControl(frame: pageControlContainerView.bounds)
        
        pageCtrl.numberOfPages = activityViewControllers.count
        pageCtrl.currentPage = 0
        pageCtrl.tintColor = UIColor.white
        pageCtrl.pageIndicatorTintColor = UIColor.gray
        pageCtrl.currentPageIndicatorTintColor = UIColor.white
        pageCtrl.isUserInteractionEnabled = false
        return pageCtrl
    }()
    
    fileprivate var embeddedVC : UIPageViewController? {
        didSet {
            if let initialVC = activityViewControllers.first {
                embeddedVC?.setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
            }
            pageControlContainerView.addSubview(pageControl)
        }
    }
    
    //MARK: - Instance Properties
    fileprivate lazy var loadingView : ActivityView = {
        let view = ActivityView(withMessage: "")
        return view
    }()
    
    private var relationshipActivities = [RelationshipChatActivity]() {
        didSet {
            upcomingActivities = []
            pastActivities = []
            for activty in relationshipActivities {
                if activty.daysUntil < 0 {
                    pastActivities.append(activty)
                } else {
                    upcomingActivities.append(activty)
                }
            }
        }
    }
    
    private var upcomingActivities = [RelationshipChatActivity]() {
        didSet {
            upcomingActivityVC?.activities = upcomingActivities
        }
    }
    private var pastActivities = [RelationshipChatActivity]() {
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
    
    fileprivate var currentUser : RelationshipChatUser?
    {
        didSet {
            if currentUser != nil {
                newProfileButton.isHidden = true
                
                if currentUser!.profileImageURL != nil  {
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    }
                    
                    currentUser?.getUsersProfileImage(completionHandler: { [weak self] (downloadedImage, error) in
                        DispatchQueue.main.async {
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                        
                        guard error == nil else {
                            print(error!.localizedDescription)
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self?.userImage = downloadedImage
                        }
                    })
                    
                }
                
                loadRelationship()
                navigationItem.title = "\(currentUser!.firstName) \(currentUser!.lastName)"
                editProfileButton.isEnabled = true
                logoutButton.isEnabled = true
                tabBarController?.relationshipBarItem?.isEnabled = true
            } else {
                navigationItem.title = " "
                newProfileButton.isHidden = false
                editProfileButton.isEnabled = false
                logoutButton.isEnabled = false
                relationshipActivities = []
                tabBarController?.relationshipBarItem?.isEnabled = false
            }
        }
    }
    fileprivate var secondaryUser : RelationshipChatUser?
    {
        didSet {
            if secondaryUser != nil {
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                
                secondaryUser?.getUsersProfileImage(completionHandler: { [weak self](downloadedImage, error) in
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    
                    guard error == nil else {
                        print(error!.localizedDescription)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.relationshipUserImage = downloadedImage
                    }
                })
                
            } else {
                relationshipUserImage = UIImage(named: "Breakup")
            }
        }
    }
    
    
    fileprivate var currentRelationship : RelationshipChatRelationship?
        
        {
        didSet {
            func setupUIForPending() {
                pageControl.isHidden = true
                pageControlContainerView.isHidden = true
                embedViewContainer.isHidden = true
                notInARelationshipView.isHidden = false
                tabBarController?.chatBarItem?.isEnabled = false
                notInARelationshipLabel.text = Constants.PendingNotInARelationshipViewText
                secondaryUser = nil
                daysLabelTitle.text = "Your relationship is"
                daysLabel.text = "Pending"
            }
            
            func setupUIForRelationship() {
                pageControl.isHidden = false
                pageControlContainerView.isHidden = false
                embedViewContainer.isHidden = false
                tabBarController?.chatBarItem?.isEnabled = true
                notInARelationshipView.isHidden = true
                relationshipStatus = currentRelationship!.status
                relationshipStartDate = currentRelationship!.startDate
                
                let secondaryUserID = currentRelationship!.relationshipMembers.filter {
                    $0 != currentUser?.userUID
                    }.first!
                
                RelationshipChatUser.pullUserFromFB(uid: secondaryUserID) { [weak self] (fetchedSecondaryUser, error) in
                    guard error == nil else {
                        print(error!)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        
                        if let newSecondaryUser = fetchedSecondaryUser, self?.currentRelationship != nil {
                            self?.secondaryUser = newSecondaryUser
                        } else {
                            self?.secondaryUser = nil
                        }
                        
                    }
                }
                
                loadActivitiesFrom(relationshipUID: currentRelationship!.relationshipUID)
            }
            
            func setupUIForNoRelationship() {
                pageControl.isHidden = true
                pageControlContainerView.isHidden = true
                embedViewContainer.isHidden = true
                daysLabelTitle.text = "You Are"
                daysLabel.text = Constants.DefaultRelationshipText
                relationshipStatus = Constants.DefaultRelationshipText
                notInARelationshipLabel.text = Constants.DefaultNotInARelationshipViewText
                notInARelationshipView.isHidden = false
                tabBarController?.chatBarItem?.isEnabled = false
                secondaryUser = nil
                relationshipUserImage = UIImage(named: "Breakup")
            }
            
            
            if currentRelationship != nil {
                
                switch currentRelationship!.status {
                case RelationshipStatus.Pending :
                    DispatchQueue.main.async {
                        setupUIForPending()
                    }
                default :
                    DispatchQueue.main.async {
                        setupUIForRelationship()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.secondaryUser = nil
                    setupUIForNoRelationship()
                }
            }
        }
    }
    
    private var tabBarChatIconBadge : Int? {
        get {
            guard let badgeValue = self.tabBarController?.chatBarItem?.badgeValue else {
                return nil
            }
            return Int(badgeValue)
        } set {
            guard newValue != nil, newValue != 0 else {
                self.tabBarController?.chatBarItem?.badgeValue = nil
                return
            }
            
            self.tabBarController?.chatBarItem?.badgeValue = String(describing: newValue!)
        }
    }
    
    // MARK: - Relationship request variables
    private var sendingUserID : String?
    private var requestedRelationID : String?
    
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.relationshipBarItem?.isEnabled = false
        addNotificationObserver()
        tabBarChatIconBadge = UIApplication.shared.applicationIconBadgeNumber
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        changedImageButton.backgroundColor = UIColor.clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if currentUser == nil {
            pullUsersRecord()
        }
    }
    
    
    //MARK: - Outlet Actions, New Profile button, change image button
    
    @IBAction func logout(_ sender: Any) {
        
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            UserDefaults.standard.set(nil, forKey: FireBaseUserDefaults.UsersLoginName)
            UserDefaults.standard.set(nil, forKey: FireBaseUserDefaults.UsersPassword)
            self.performSegue(withIdentifier: Storyboard.LoginSegue, sender: nil)
        } catch {
            self.displayAlertWithTitle(Constants.DefaultErrorTitle, withBodyMessage: error.localizedDescription, withBlock: nil)
        }
    }
    
    @IBAction func createNewProfile(_ sender: Any) {
        
        guard Cloud.userIsLoggedIntoIcloud() else {
            present(Cloud.notLoggedIntoCloudVC, animated: true, completion: nil)
            
            return
        }
        performSegue(withIdentifier: Storyboard.NewProfileSegue, sender: self)
        
    }
    
    
    @IBAction func changeImage(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picturePicker = UIImagePickerController()
            picturePicker.delegate = self
            picturePicker.sourceType = .photoLibrary
            picturePicker.allowsEditing = true
            self.present(picturePicker, animated: true, completion: nil)
        }
    }
    
    // MARK: - Notification Observers
    fileprivate func addNotificationObserver() {
        
        NotificationCenter.default.addObserver(forName: NotificatonChannels.RelationshipRequestChannel, object: nil, queue: nil) { [weak self](notification) in
            
            if let valueDict = notification.userInfo {
                self?.sendingUserID = valueDict[FirebaseDB.NotificationRelationshipRequestSenderKey] as! String
                self?.requestedRelationID = valueDict[FirebaseDB.NotificationRelationshipRequestDataKey] as! String
                
                DispatchQueue.main.async {
                    self?.navigationController?.popToRootViewController(animated: true)
                    self?.performSegue(withIdentifier: Storyboard.RelationshipConfirmationSegueID, sender: nil)
                }
                
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
        
        guard let userLogin = UserDefaults.standard.value(forKey: FireBaseUserDefaults.UsersLoginName) as? String, let userPassword = UserDefaults.standard.value(forKey: FireBaseUserDefaults.UsersPassword) as? String else {
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            loadingView.removeFromSuperview()
            performSegue(withIdentifier: Storyboard.LoginSegue, sender: self)
            
            return
        }
        
        Auth.auth().signIn(withEmail: userLogin, password: userPassword) { [weak self](currentUserFromFB, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.loadingView.removeFromSuperview()
            }
            
            guard error == nil, let loggedInUser = currentUserFromFB else {
                self?.performSegue(withIdentifier: Storyboard.LoginSegue, sender: self)
                return
            }
            
            RelationshipChatUser.pullUserFromFB(uid: loggedInUser.uid, completionHandler: { (pulledUser, error) in
                guard error == nil, let currentUserFromFB = pulledUser else {
                    self?.performSegue(withIdentifier: Storyboard.LoginSegue, sender: self)
                    return
                }
                
                DispatchQueue.main.async {
                    
                    self?.currentUser = currentUserFromFB
                    
                }
                
            })
            
        }
        
    }
    
    
    private func loadRelationship() {
        
        guard let relationshipID = currentUser?.relationship else {
            return
        }
        
        RelationshipChatRelationship.fetchRelationship(withUID: relationshipID) { [weak self] (fetchedRelationship, error) in
            
            guard error == nil else {
                print(error!)
                return
            }
            
            if let updatedRelationship = fetchedRelationship {
                self?.currentRelationship = updatedRelationship
            } else {
                self?.currentRelationship = nil
            }
            
        }
        
        
        
    }
    
    // MARK: - Relationship response functions
    fileprivate func acceptedRelationshipResponseSetup() {
        
        if currentRelationship != nil && currentUser != nil {
            
            //TODO Check for relationship response 
            
        }
    }
    
    fileprivate func declinedRelationshipResponseSetup() {
        
    }
    
    //MARK: - Navigation
    
    @IBAction func newProfileCreated(segue : UIStoryboardSegue) {
        pullUsersRecord()
    }
    
    @IBAction func unwindFromEditProfile(segue : UIStoryboardSegue) {
        if let evc = segue.source as? EditProfileViewController {
            DispatchQueue.main.async {
                self.currentUser = evc.mainUserRecord
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.EditProfileSegue :
                if let dvc = segue.destination as? EditProfileViewController {
                    dvc.mainUserRecord = currentUser
                }
            case Storyboard.RelationshipConfirmationSegueID :
                if let rvc = segue.destination as? RelationshipConfirmationViewController {
                    rvc.sendingUsersUID = sendingUserID
                    rvc.requestedRelationshipUID = requestedRelationID
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
    fileprivate func loadActivitiesFrom(relationshipUID : String) {
        
        FirebaseDB.MainDatabase.child(FirebaseDB.ActivityByRelationshipFanOutKey).child(currentRelationship!.relationshipUID).observe(.childAdded) { (snapshot) in
            
            let activityKey = snapshot.key
            
            RelationshipChatActivity.fetchActivity(withUID: activityKey, completionHandler: { (fetchedActivity) in
                
                
                self.relationshipActivities = self.relationshipActivities.filter {
                    $0.activityUID != activityKey
                }
                
                
                
                if fetchedActivity != nil {
                    DispatchQueue.main.async {
                         self.relationshipActivities.append(fetchedActivity!)
                    }
                } 
                
            })
            
        }
    }
}
    
    // MARK: - Image Controller delegate
    
    @available(iOS 10.0, *)
    extension ProfileViewController : UIImagePickerControllerDelegate {
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
            
            if let editedPic = info[UIImagePickerControllerEditedImage] as? UIImage {
                userImage = editedPic
            } else if let originalPic = info[UIImagePickerControllerOriginalImage] as? UIImage {
                userImage = originalPic
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            currentUser?.saveUserToDB(userImage: userImage, completionBlock: { [weak self](completed, error) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    self?.displayAlertWithTitle("Oops!", withBodyMessage: error!.localizedDescription, withBlock: nil)
                    return
                }
                
            })
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
