//
//  ActivityOverviewViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 7/26/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import CloudKit
import MapKit

@available(iOS 10.0, *)
class ActivityOverviewViewController: UITableViewController {
    
    //MARK : - Constants   
    struct Constants {
        static let AnnotationIdentifier = "default a ID"
        static let DeletingMessage = "Deleting activity..."
        static let SaveMessage = "Saving activity..."
        
        static let AlertErrorTitleMessage = "There seems to be a problem"
        static let AlertErrorEmptyTitleMessage = "You need to enter a title"
        static let AlertErrorEmptyDescriptionMessage = "You need to enter a description"
        
        static let AddressLabelDefaultText = "This activity has no location"
        
        static let CoordinateSpan : CLLocationDegrees = 0.05
        static let SquareSizeWidthLength : CGFloat = 30
        
        static let AlphaColorValue : CGFloat = 0.5
    }
    
    struct Storyboard {
        static let EditLocationSegue = "Find Location Segue"
    }
    
    //MARK : - Outlets
    
    @IBOutlet weak var datePicker: UIDatePicker! {
        didSet {
            datePicker.minimumDate = Date()
        }
    }
    
    @IBOutlet weak var descriptionTextBox: UITextView!
    
    @IBOutlet weak var newLocationButton: UIButton! {
        didSet {
            newLocationButton.backgroundColor = UIColor.flatPurple()
            newLocationButton.clipsToBounds = true
            newLocationButton.setTitleColor(UIColor.white, for: .normal)
            newLocationButton.roundEdges()
        }
    }
    
    @IBOutlet weak var locationMapView: MKMapView! {
        didSet {
            locationMapView.delegate = self
            locationMapView.mapType = .standard
        }
    }
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var addressLabelContainerView: UIView! {
        didSet {
            addressLabelContainerView.roundEdges()
        }
    }
    
    @IBOutlet weak var addressNameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    

   
    //MARK : - Model
    var activity : CKRecord? {
        didSet {
            setupUI()
        }
    }
    
    //MARK : - Instance properties
    
    fileprivate var loadingView = ActivityView(withMessage: "")
    
    fileprivate var activityDate : Date {
        get {
            return datePicker?.date ?? Date()
        } set {
            datePicker?.setDate(activityDate, animated: true)
        }
    }
    
    var relationshipRecord : CKRecord?
    
    fileprivate var newActivityLocation : MKPlacemark? {
        didSet {
            if activity != nil {
                activity![Cloud.RelationshipActivityAttribute.LocationStringName] = newActivityLocation?.name as CKRecordValue?
                activity![Cloud.RelationshipActivityAttribute.LocationStringAddress] = MKPlacemark.parseAddress(selectedItem: newActivityLocation!) as CKRecordValue?
                
                let activityCLLocation = CLLocation(latitude: newActivityLocation!.coordinate.latitude, longitude: newActivityLocation!.coordinate.longitude)
                activityLocation = activityCLLocation
                
                activity![Cloud.RelationshipActivityAttribute.Location] = activityCLLocation as CKRecordValue?
            }
        }
    }
    
    fileprivate var activityLocation : CLLocation? {
        didSet {
            if activityLocation != nil {
                newLocationButton?.isEnabled = true
                setupMapView()
                let addressStringTitle = activity![Cloud.RelationshipActivityAttribute.LocationStringName] as! String
                let addressStringBody = activity![Cloud.RelationshipActivityAttribute.LocationStringAddress] as! String
                
                addressNameLabel?.text = addressStringTitle
                addressLabel?.text = addressStringBody
                
            } else {
                newLocationButton?.isEnabled = false
            }
        }
    }
    
    fileprivate var calendar = Calendar.current
    fileprivate var activityModified : CKRecord?
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Set Button color
        newLocationButton.backgroundColor = UIColor.darkGray
        newLocationButton.tintColor = UIColor.white
        
    }
    
    //MARK: - Class methods
    
    fileprivate func setupUI() {
        
        if activity != nil {

            if activity![Cloud.RelationshipActivityAttribute.SystemCreated] != nil {
           
                datePicker?.datePickerMode = .date
                datePicker?.isEnabled = false
                descriptionTextBox?.isEditable = false
                saveButton?.isEnabled = false
                newLocationButton?.isHidden = true
                addressLabel?.text = activity![Cloud.RelationshipActivityAttribute.Message] as! String
            }
            
            activityDate = activity![Cloud.RelationshipActivityAttribute.CreationDate] as! Date
            descriptionTextBox?.text = activity![Cloud.RelationshipActivityAttribute.Message] as! String
            
            activityLocation = activity![Cloud.RelationshipActivityAttribute.Location] as? CLLocation
            
        }
        
    }
    
    fileprivate func setupMapView() {
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = activityLocation!.coordinate
        pointAnnotation.title = activity![Cloud.RelationshipActivityAttribute.LocationStringName] as? String
        pointAnnotation.subtitle = activity![Cloud.RelationshipActivityAttribute.LocationStringAddress] as? String
        
        locationMapView?.addAnnotation(pointAnnotation)
        
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(activityLocation!.coordinate, span)
        locationMapView?.setRegion(region, animated: true)
        
    }
    
    @objc func getDirections() {
        let placemark = MKPlacemark(coordinate: activityLocation!.coordinate)
        
        let mapItem = MKMapItem(placemark: placemark)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    //MARK: - Outlet methods
    
    @IBAction func cancelAction(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    @IBAction func saveActivity(_ sender: Any) {
        
        guard !descriptionTextBox.text!.isEmpty else {
            descriptionTextBox.backgroundColor = UIColor.red.withAlphaComponent(Constants.AlphaColorValue)
            displayAlertWithTitle(Constants.AlertErrorTitleMessage, withBodyMessage: Constants.AlertErrorEmptyDescriptionMessage, withBlock: nil)
            return
        }
        
        activity![Cloud.RelationshipActivityAttribute.CreationDate] = datePicker.date as CKRecordValue?
        activity![Cloud.RelationshipActivityAttribute.Message] = descriptionTextBox.text as CKRecordValue?
        
        if activityLocation != nil {
            activity![Cloud.RelationshipActivityAttribute.Location] = activityLocation! as CKRecordValue?
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        view.addSubview(loadingView)
        loadingView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        loadingView.updateMessageWith(message: Constants.SaveMessage)
        
        Cloud.CloudDatabase.PublicDatabase.save(activity!) { [weak self] (savedRecord, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.loadingView.removeFromSuperview()
            }

            if error != nil {
                _ = Cloud.errorHandling(error!, sendingViewController: self)
            } else {
                if let successfullySavedRecord = savedRecord {
                    NotificationCenter.default.post(name: CloudKitNotifications.ActivityUpdateChannel, object: nil, userInfo: [CloudKitNotifications.ActivityUpdateKey : successfullySavedRecord])
                }
            }
        }
        
    }
    
    //MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if activity?[Cloud.RelationshipActivityAttribute.SystemCreated] != nil {
            if indexPath.section == 2 {
                return 0.0
            }
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    //MARK: - Tableview Datasource
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if activity?[Cloud.RelationshipActivityAttribute.SystemCreated] != nil {
            if section == 2 {
                return nil
            }
        }
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.EditLocationSegue:
                if let alsvc = segue.destination as? ActivityLocationSelectionViewController {
                    alsvc.delegate = self 
                }
            default:
                break
            }
        }
    }

}

//MARK: - MapView Delegates

@available(iOS 10.0, *)
extension ActivityOverviewViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.AnnotationIdentifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationIdentifier)
            view?.canShowCallout = true
        }
        view?.annotation = annotation
        
        let squareSize = CGSize(width: Constants.SquareSizeWidthLength, height: Constants.SquareSizeWidthLength)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: squareSize))
        button.setBackgroundImage(UIImage(named : "car"), for: .normal)
        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
        button.backgroundColor = UIColor.clear
        view?.leftCalloutAccessoryView = button
        
        return view
    }
    
}

//MARK: - Textfield Delegates

@available(iOS 10.0, *)
extension ActivityOverviewViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let enteredText = textField.text {
            if enteredText.onlyAlphabetical() {
                textField.resignFirstResponder()
                return true
            } else {
                displayAlertWithTitle("Oops!", withBodyMessage: "Please enter only alphabetical characters", withBlock: nil)
                return false
            }
        }
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.backgroundColor = UIColor.white
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.backgroundColor = UIColor.white
    }
    
    
}


//MARK: - HandlePicked location protocol methods

@available(iOS 10.0, *)
extension ActivityOverviewViewController : HandlePickedLocation {
    
    func newLocationSelectedFrom(placemark: MKPlacemark) {
        newActivityLocation = placemark
    }
    
}
