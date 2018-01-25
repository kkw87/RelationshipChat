//
//  ActivityOverviewViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 7/26/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import Firebase
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
    var activity : RelationshipChatActivity? {
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
    
    var currentRelationship : RelationshipChatRelationship?
    private var secondaryUser : RelationshipChatUser?
    
    fileprivate var newActivityLocation : MKPlacemark? {
        didSet {
            if activity != nil {
                activity!.locationStringName = newActivityLocation!.name!
                activity!.locationStringAddress = MKPlacemark.parseAddress(selectedItem: newActivityLocation!)
                
                let activityCLLocation = CLLocationCoordinate2D(latitude: newActivityLocation!.coordinate.latitude, longitude: newActivityLocation!.coordinate.longitude)
                activityLocation = activityCLLocation
                
                activity!.location = activityCLLocation
            }
        }
    }
    
    fileprivate var activityLocation : CLLocationCoordinate2D? {
        didSet {
            if activityLocation != nil {
                newLocationButton?.isEnabled = true
                setupMapView()
                let addressStringTitle = activity!.locationStringName
                let addressStringBody = activity!.locationStringAddress
                
                addressNameLabel?.text = addressStringTitle
                addressLabel?.text = addressStringBody
                
            } else {
                newLocationButton?.isEnabled = false
            }
        }
    }
    
    fileprivate var calendar = Calendar.current
    fileprivate var activityModified : RelationshipChatRelationship?
    
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

            if activity!.systemActivity != nil {
           
                datePicker?.datePickerMode = .date
                datePicker?.isEnabled = false
                descriptionTextBox?.isEditable = false
                saveButton?.isEnabled = false
                newLocationButton?.isHidden = true
                addressLabel?.text = activity!.description
            }
            activityDate = activity!.creationDate
            descriptionTextBox?.text = activity!.description
            
            activityLocation = activity!.location
            
        }
        
    }
    
    fileprivate func setupMapView() {
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = activityLocation!
        pointAnnotation.title = activity!.locationStringName
        pointAnnotation.subtitle = activity!.locationStringAddress
        
        locationMapView?.addAnnotation(pointAnnotation)
        
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(activityLocation!, span)
        locationMapView?.setRegion(region, animated: true)
        
    }
    
    @objc func getDirections() {
        let placemark = MKPlacemark(coordinate: activityLocation!)
        
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
        
        activity!.creationDate = datePicker.date
        activity!.description = descriptionTextBox.text
        
        if activityLocation != nil {
            activity!.location = activityLocation!
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        view.addSubview(loadingView)
        loadingView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        loadingView.updateMessageWith(message: Constants.SaveMessage)
        
        
        activity!.saveActivity { (error, _) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.loadingView.removeFromSuperview()
            }
            
            
            guard error == nil else {
                print(error!)
                return
            }

        }

    }
    
    //MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if activity?.systemActivity != nil {
            if indexPath.section == 2 {
                return 0.0
            }
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    //MARK: - Tableview Datasource
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if activity?.systemActivity != nil {
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
