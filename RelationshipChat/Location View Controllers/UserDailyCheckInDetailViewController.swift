//
//  UserDailyCheckInDetailViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/12/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class UserDailyCheckInDetailViewController: UIViewController, MKMapViewDelegate {
    
    //MARK: - Model 
    var location : RelationshipChatLocation? {
        didSet {
            setupUI()
        }
    }
    
    //MARK: - Outlets
    @IBOutlet weak var labelContainerView: UIView! {
        didSet {
            labelContainerView.roundEdges()
            labelContainerView.clipsToBounds = true
        }
    }
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var locationTimeLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }
    
    //MARK: - Constants
    struct Storyboard {
        static let CellIdentifier = "User Location Cell"
        static let SwipeToDeleteUnwindSegue = "ActivityByDetailDeleted"
        
        static let AnnotationIdentifier = "LocationAnnotationView"
    }
    
    struct Constants {
        static let SwipeToDeleteText = "Delete"
        
        static let AnnotationSquareWidthAndHeight : CGFloat = 30
        
        static let NavigationConfirmationTitle = "Navigate to destination"
        static let NavigationConfirmationBody = "Do you wish to open maps to navigate to the destination?"
        static let NavigationConfirmationYesButton = "Navigate"
        static let NavigationConfirmationNoButton = "Cancel"
        
        
        static let DateFormat = "h:mm a"
        static let MapSpan : CLLocationDegrees = 0.02
    }
    
    //MARK: - Instance Properties
    lazy var dateFormatter : DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.DateFormat
        return dateFormatter
    }()
    
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - Class methods
    @objc func navigateToAnnotation(annotationView : MKAnnotation) {
        //TODO, incomplete, clicking on the arrow should send you to maps with navigation
        
    }
    
    private func setupUI() {
        //Setup mapview coordinate
        if let currentRelationshipChatLocation = location {
            let locationCoordinate = currentRelationshipChatLocation.location
            
            let mapRegion = MKCoordinateRegion(center: locationCoordinate, span: MKCoordinateSpan(latitudeDelta: Constants.MapSpan, longitudeDelta: Constants.MapSpan))
            
            mapView?.setRegion(mapRegion, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationCoordinate
            
            mapView?.addAnnotation(annotation)
            
            //Setup labels
            let creationTime = currentRelationshipChatLocation.creationDate
            
            let locationName = currentRelationshipChatLocation.locationName
            
            locationNameLabel?.text = locationName
            locationTimeLabel?.text = dateFormatter.string(from: creationTime)
        }
    }
    
    //MARK: - Mapview Delegate
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let navigationConfimrationController = UIAlertController(title: Constants.NavigationConfirmationTitle, message: Constants.NavigationConfirmationBody, preferredStyle: .alert)
        navigationConfimrationController.addAction(UIAlertAction(title: Constants.NavigationConfirmationYesButton, style: .default, handler: { (action) in
            guard let mapCoordinates = view.annotation?.coordinate else {
                print("error in annotation")
                return
            }
            
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: mapCoordinates))
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDefault])
            
        }))
    }
    
}
