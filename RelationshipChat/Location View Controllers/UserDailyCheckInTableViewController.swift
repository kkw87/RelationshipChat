//
//  UserDailyCheckInTableViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 8/25/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import MapKit
import CloudKit

class UserDailyCheckInTableViewController: UITableViewController {
 
    //MARK: - Model
    fileprivate var userLocations = [String : [CKRecord]]() {
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
    var relationshipRecord : CKRecord? {
        didSet {
            if relationshipRecord != nil {
                fetchNewLocationsFrom(relationship: relationshipRecord!)
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
        addNotificationObservers()
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
                locationsByDayVC.dataSource = self 
            default:
                break
            }
        }
    }
    
    @IBAction func unwindFromCheckInByDayTVC(segue : UIStoryboardSegue) {
        
    }
    
    //MARK: - Class Methods
    
    fileprivate func addNotificationObservers() {
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.RelationshipUpdateChannel, object: nil, queue: nil) { [weak self] (notification) in
            if let relationship = notification.userInfo?[CloudKitNotifications.RelationshipUpdateKey] as? CKRecord {
                self?.relationshipRecord = relationship
            }
        }
    }

    
    fileprivate func fetchNewLocationsFrom(relationship : CKRecord) {
        
        guard let updatedActivityLocations = relationshipRecord?[Cloud.RelationshipAttribute.Locations] as? [CKReference] else {
            return
        }
        
        //Setup a container to store any new locations
        var newLocations = [CKRecordID]()
        
        //Setup array of locations from the passed in relationship record
        let updatedRelationshipActivityIDs = updatedActivityLocations.map {
            $0.recordID
        }
        
        //Setup array of locations from the current locations that are being displayed
        let currentUserLocationRecordIDs = Array(userLocations.values).joined().map {
            $0.recordID
        }
        
        //Filter out new locations
        newLocations.append(contentsOf: updatedRelationshipActivityIDs.filter {
            !currentUserLocationRecordIDs.contains($0)
        })
        
        //Fetch new locations 
        fetch(locations: newLocations)
    }
    
    fileprivate func fetch(locations : [CKRecordID]) {
        
        let locationFetchOperation = CKFetchRecordsOperation(recordIDs: locations)
        locationFetchOperation.fetchRecordsCompletionBlock = {
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }

            if $1 != nil {
                _ = Cloud.errorHandling($1!, sendingViewController: self)
                print($1!._code)
                //if the record isnt found , delete it from the relationship record and update
            }
            else if $0 != nil {
                self.organizeLocations(locations: Array($0!.values))
            }
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        Cloud.CloudDatabase.PublicDatabase.add(locationFetchOperation)
    }
    
    
    fileprivate func organizeLocations(locations : [CKRecord]) -> Void {
        
        for location in locations {
            if let locationDate = location.creationDate {
                
                let dateString = locationDate.returnDayAndDateAsString()
                
                if var currentDayLocations = userLocations[dateString] {
                    if !currentDayLocations.contains(location) {
                        currentDayLocations.append(location)
                        userLocations[dateString] = currentDayLocations
                    }
                } else {
                    userLocations[dateString] = [location]
                }
            }
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
        
        guard relationshipRecord != nil else {
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
            
            
            let newUserLocation = CKRecord(recordType: Cloud.Entity.UserLocation)
            newUserLocation[Cloud.UserLocationAttribute.Location] = userLoggedLocation as CKRecordValue?
            newUserLocation[Cloud.UserLocationAttribute.Relationship] = CKReference(record: self!.relationshipRecord!, action: .deleteSelf) as CKRecordValue?
            newUserLocation[Cloud.UserLocationAttribute.UserName] = self!.currentUserName! as CKRecordValue?
            
            if let userLocationPlacemark = foundLocations?.first {
                let addressName = "\(userLocationPlacemark.thoroughfare ?? ""), \(userLocationPlacemark.postalCode ?? "")"
                newUserLocation[Cloud.UserLocationAttribute.LocationStringName] = addressName as CKRecordValue?
            }
            
            let locationReference = CKReference(record: newUserLocation, action: .none)
            
            
            
            if var relationshipLocations = self!.relationshipRecord![Cloud.RelationshipAttribute.Locations] as? [CKReference] {
                
                relationshipLocations.append(locationReference)
                self!.relationshipRecord![Cloud.RelationshipAttribute.Locations] = relationshipLocations as CKRecordValue?
            } else {
                //Make the array, append the new value, then set it
                let locationReferences = [locationReference]
                self!.relationshipRecord![Cloud.RelationshipAttribute.Locations] = locationReferences as CKRecordValue?
            }
            
            DispatchQueue.main.async {
                self?.loadingView.updateMessageWith(message: Constants.SavingRelationshipRecordsMessage)
            }
            
            let saveOperation = CKModifyRecordsOperation(recordsToSave: [newUserLocation, self!.relationshipRecord!], recordIDsToDelete: nil)
            
            saveOperation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
                self?.logUserLocationButton.isEnabled = true
                self?.locationLogInProgress = false
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
                
                let savedRelationshipRecord = savedRecords?.filter {$0.recordID == self?.relationshipRecord!.recordID}.first as Any
                
                if let savedUserLocation = (savedRecords?.filter {
                    $0.recordID == newUserLocation.recordID
                    })?.first {
                    self?.organizeLocations(locations: [savedUserLocation])
                    
                }
                
                NotificationCenter.default.post(name: CloudKitNotifications.RelationshipUpdateChannel, object: nil, userInfo: [CloudKitNotifications.RelationshipUpdateKey : savedRelationshipRecord])
                
            }
            
            Cloud.CloudDatabase.PublicDatabase.add(saveOperation)
            
        })
        
    }
}

extension UserDailyCheckInTableViewController : LocationDataSource {
    
    func delete(location: CKRecord) {
        //Remove the deleted location from the current locations
        let locationValues = Array(self.userLocations.values).flatMap {
            $0
            }.filter {
                $0.recordID != location.recordID
        }
        
        let originalLocations = self.relationshipRecord![Cloud.RelationshipAttribute.Locations] as CKRecordValue?
        
        self.relationshipRecord![Cloud.RelationshipAttribute.Locations] = (self.relationshipRecord![Cloud.RelationshipAttribute.Locations] as! [CKReference]).filter {
            $0.recordID.recordName != location.recordID.recordName
            } as CKRecordValue?
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        let modifyRecordsOp = CKModifyRecordsOperation(recordsToSave: [relationshipRecord!], recordIDsToDelete: [location.recordID])
        modifyRecordsOp.modifyRecordsCompletionBlock = { [weak self] (savedRecords, deletedRecordIDs, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard error == nil else {
                self?.relationshipRecord?[Cloud.RelationshipAttribute.Locations] = originalLocations
                print("error deleting location")
                return
            }
            
            self?.userLocations = [:]
            self?.organizeLocations(locations: locationValues)
            
        }
        
        Cloud.CloudDatabase.PublicDatabase.add(modifyRecordsOp)
    }

}
