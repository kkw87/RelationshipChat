////
////  UserDailyCheckInTableViewController.swift
////  RelationshipChat
////
////  Created by Kevin Wang on 8/25/17.
////  Copyright © 2017 KKW. All rights reserved.
////
//
import UIKit
import MapKit
import Firebase

class UserDailyCheckInTableViewController: UITableViewController {


    //MARK: - Model
    fileprivate var userLocations = [String : [RelationshipChatLocation]]() {
        didSet {
            DispatchQueue.main.async {
                self.keyNames = Array(self.userLocations.keys)
            }
        }
    }
    
    fileprivate var keyNames = [String]() {
        didSet {
            keyNames = keyNames.sorted {$0 < $1}
            self.tableView.reloadData()
        }
    }

    //MARK: - Constants
    private struct Storyboard {
        static let SegueIdentifier = "To Day Segue"

    }

    struct Constants {
        
        static let CellIdentifier = "Overview Cell"

        static let LocationLogAlertControllerTitle = "Log your location"
        static let LocationLogAlertControllerBody = "Do you wish to log your current location?"
        static let LocationLogAlertControllerYesButton = "Yes"
        static let LocationLogAlertControllerNoButton = "No"
        
        static let SavingLocationMessage = "Saving your location"
        static let SavingRelationshipRecordsMessage = "Updating your location to the cloud"
        
        static let ErrorAlertTitle = "It seems we've had a technical hiccup"
        
        static let LocationDeletionErrorTitle = ""
        static let LocationDeletionErrorBody = ""
    }
    
    //MARK: - Instance Properties
    fileprivate lazy var locationManager : CLLocationManager = {
        let lm = CLLocationManager()
        lm.delegate = self
        lm.desiredAccuracy = kCLLocationAccuracyBest
        lm.requestWhenInUseAuthorization()
        return lm
    }()

    var locationLogInProgress = false
    fileprivate let loadingView = ActivityView(withMessage: "")
    weak var presentingView : UIView?
    
    

    //MARK: - Outlets
    @IBOutlet weak var logUserLocationButton: UIBarButtonItem!
    
    //MARK: - Model
    var currentRelationship : RelationshipChatRelationship? {
        didSet {
            if currentRelationship != nil {
                fetchLocations()
            }
        }
    }
    
    var currentUserName : String?
    
    //MARK: - Outlet actions
    @IBAction func logUserLocation(_ sender: Any) {

        let alertVC = UIAlertController(title: Constants.LocationLogAlertControllerTitle, message: Constants.LocationLogAlertControllerBody, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: Constants.LocationLogAlertControllerYesButton, style: .default, handler: { [weak self] _ in
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self?.logUserLocationButton.isEnabled = false
            self?.locationManager.requestLocation()
        }))
        alertVC.addAction(UIAlertAction(title: Constants.LocationLogAlertControllerNoButton, style: .cancel, handler: nil))
        present(alertVC, animated: true, completion: nil)

    }
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideEmptyCells()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Number of activities under each day
        // #warning Incomplete implementation, return the number of rows
        return keyNames.count
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifier, for: indexPath)

        let dayTitleString = keyNames[indexPath.row]

        //Need to get the amount of locations located in each day
        let locationAmount = userLocations[dayTitleString]?.count ?? 0

        cell.textLabel?.text = dayTitleString
        cell.detailTextLabel?.text = "\(locationAmount) \(locationAmount > 1 ? "locations" : "location")"

        return cell
    }

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case Storyboard.SegueIdentifier:
                guard let locationsByDayVC = segue.destination as? UserDailyCheckInByDayTableViewController, let sendingCellDateTitle = (sender as! UITableViewCell).textLabel!.text else {
                    break
                }
                locationsByDayVC.navigationItem.title = sendingCellDateTitle
                locationsByDayVC.userLocations = userLocations[sendingCellDateTitle]
            default:
                break
            }
        }
    }
    
    @IBAction func unwindFromCheckInByDayTVC(segue : UIStoryboardSegue) {
        
    }
    
    //MARK: - Class Methods

    private func fetchLocations() {
       
        //Fetch location IDs by relationship
        FirebaseDB.MainDatabase.child(FirebaseDB.LocationsByRelationshipFanOutKey).child(currentRelationship!.relationshipUID).observe(.childAdded) { (snapshot) in
            
            let relationshipLocationID = snapshot.key
            
            //Fetch individual locations
            RelationshipChatLocation.fetchLocation(withUID: relationshipLocationID, completionHandler: { [weak self](fetchedLocation) in
                
                //Organize and add in locations to current array
                if let newLocation = fetchedLocation {
                    
                    //Get the location date as a formattesd string value to be used as a key in the location dictionary
                    let locationDateString = newLocation.creationDate.returnDayAndDateAsString()
                    
                    if var locationsByDay = self?.userLocations[locationDateString] {
                        //Now check if the value already exists
                        locationsByDay = locationsByDay.filter {
                            $0.uid != newLocation.uid
                        }
                        
                        //Add in new location
                        locationsByDay.append(newLocation)
                        self?.userLocations[locationDateString] = locationsByDay
                        
                        
                    } else {
                        //Current day doesnt exist, create it and set thevalue to an array that contains the new location
                        self?.userLocations[locationDateString] = [newLocation]
                    }
                    
                    
                }
            })
            
            //Observe for locations being deleted
            FirebaseDB.MainDatabase.child(FirebaseDB.LocationsByRelationshipFanOutKey).child(self.currentRelationship!.relationshipUID).observe(.childRemoved, with: { [weak self](snapshot) in
                
                let deletedLocationID = snapshot.key
                
                
                for (stringDateKey,_) in self!.userLocations {
                    self?.userLocations[stringDateKey] = self?.userLocations[stringDateKey]?.filter {
                        $0.uid != deletedLocationID
                    }
                    
                    if self!.userLocations[stringDateKey]!.isEmpty {
                        self?.userLocations[stringDateKey] = nil
                    }
                    
                }
            })
            
            
            
            
        }
    }

}

//MARK: - LocationManager Delegate
extension UserDailyCheckInTableViewController : CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        loadingView.removeFromSuperview()
        print("Location did fail with error \(error)")
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard !locationLogInProgress, let userLoggedLocation = locations.first else {
            return
        }
        presentingView!.addSubview(loadingView)
        
        locationLogInProgress = true
        loadingView.updateMessageWith(message: Constants.SavingLocationMessage)
        loadingView.center = CGPoint(x: presentingView!.bounds.midX, y: presentingView!.bounds.midY)

        guard currentRelationship != nil else {
            loadingView.removeFromSuperview()
            print("relationship error")
            return
        }

        guard currentUserName != nil else {
            loadingView.removeFromSuperview()
            print("user name error")
            return
        }
        
        let addressNameFinder = CLGeocoder()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        addressNameFinder.reverseGeocodeLocation(userLoggedLocation, completionHandler: { [weak self] (foundLocations, error) in
            

            guard error == nil else {
                DispatchQueue.main.async {
                    self?.loadingView.removeFromSuperview()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    print(error!)
                }
                return
            }
            
            if let userLocationPlacemark = foundLocations?.first {
                            let addressName = userLocationPlacemark.name ?? ""
                            let addressStringName = "\(userLocationPlacemark.thoroughfare ?? ""), \(userLocationPlacemark.postalCode ?? "")"
                
                let userLoggedLocation = RelationshipChatLocation(creatingUserName: self!.currentUserName!, location: userLoggedLocation.coordinate, locationName: addressName, locationAddressName: addressStringName, relationship: self!.currentRelationship!.relationshipUID, creationDate: Date(), uid: "")
                
                userLoggedLocation.saveLocationToDB(completionHandler: { (error, uid) in
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self?.logUserLocationButton.isEnabled = true
                        self?.loadingView.removeFromSuperview()
                    }
                    guard error == nil else {
                        self?.displayAlertWithTitle(Constants.ErrorAlertTitle, withBodyMessage: error!.localizedDescription, withBlock: nil)
                        return
                    }
                    
                    //Send notification
                    let secondaryRelationshipMemberID = self?.currentRelationship?.relationshipMembers.filter {
                        $0 != Auth.auth().currentUser?.uid
                    }.first!
                    
                    FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(secondaryRelationshipMemberID!).observeSingleEvent(of: .value, with: { (secondaryUserSnapshot) in
                        let secondaryUserValues = secondaryUserSnapshot.value as! [String : Any]
                        
                        let secondaryUserTokenID = secondaryUserValues[RelationshipChatUserKeys.NotificationTokenID] as! String
                        
                        FirebaseDB.sendNotification(toTokenID: secondaryUserTokenID, titleText: "Your partner just logged a location!", bodyText: "\(self!.currentUserName!) was just at \(addressStringName)", dataDict: nil, contentAvailable: false, completionHandler: { (error) in
                            guard error == nil else {
                                print(error!)
                                return
                            }
                        })
                        
                        
                    })
                    
                    
                    
                })
                
            }
        })

    }
}


