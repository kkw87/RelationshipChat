//
//  ActivityLocationSelectionViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 8/1/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import MapKit

//MARK : - Protocol Declarations 

protocol HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark)
}

protocol HandlePickedLocation {
    func newLocationSelectedFrom(placemark : MKPlacemark)
}

class ActivityLocationSelectionViewController: UIViewController {
    
    
    //MARK : - Constants
    struct Constants {
        static let AuthorizationErrorTitle = "We aren't able to use your location"
        static let AuthrozationRestrictedBody = "Location services are restricted, try again in another location"
        static let AuthorizationDeniedBody = "Location services are denied"
        
        static let AnnotationIdentifier = "AnnotationViewID"
        static let AnnotationSquareWidthHeight : CGFloat = 30
        
        static let longitudeSpan : CLLocationDegrees = 0.05
        static let latitudeSpan : CLLocationDegrees = 0.05
    }
    
    struct Storyboard {
        static let UnwindBackToActivity = "Activity Selected Unwind"
    }
    
    //MARK : - Instance properties
    fileprivate let locationManager = CLLocationManager()
    fileprivate var resultSearchController : UISearchController?
    fileprivate var selectedPin : MKPlacemark?
    var delegate : HandlePickedLocation?
    
    //MARK : - Outlets
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self 
        }
    }
    
    //MARK : - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()

    }

    //MARK: - Class Methods
    fileprivate func setup() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        let locationSearchTable = storyboard?.instantiateViewController(withIdentifier: "LocationSearchTableViewController") as! LocationSearchTableViewController
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDeleate = self 
        
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        resultSearchController?.searchBar.tintColor = UIColor.white
        
        let textField = resultSearchController?.searchBar.value(forKey: "searchField") as! UITextField
        
        textField.borderStyle = .none
        textField.backgroundColor = UIColor.white        
        
        navigationItem.searchController = resultSearchController
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true 
    }
}

// MARK: - CLLocation Manager Delegate methods

extension ActivityLocationSelectionViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        } else if status == .restricted {
            displayAlertWithTitle(Constants.AuthorizationErrorTitle, withBodyMessage: Constants.AuthrozationRestrictedBody, withBlock: nil)
        } else {
            let deniedAlertController = UIAlertController(title: Constants.AuthorizationErrorTitle, message: Constants.AuthorizationDeniedBody, preferredStyle: .alert)
            let appSettingsAction = UIAlertAction(title: "Settings", style: .default, handler: { (action) in
                if let appURL = URL(string: UIApplicationOpenSettingsURLString) {
                    if UIApplication.shared.canOpenURL(appURL) {
                        UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
                    }
                }
            })
            let cancelAction = UIAlertAction(title: "Don't use my location", style: .cancel, handler: nil)
            deniedAlertController.addAction(appSettingsAction)
            deniedAlertController.addAction(cancelAction)
            present(deniedAlertController, animated: true, completion: nil)
        }
    }
    
    //This is called when the location comes back
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpanMake(Constants.latitudeSpan, Constants.longitudeSpan)
            let region = MKCoordinateRegionMake(location.coordinate, span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _ = Cloud.errorHandling(error, sendingViewController: self)
        print(error)
    }
}

//MARK : - Mapview Delegates

extension ActivityLocationSelectionViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
            
        }
        
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.AnnotationIdentifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationIdentifier)
            view?.canShowCallout = true
        }
        
        view?.annotation = annotation
        let leftButtonSize = CGSize(width: Constants.AnnotationSquareWidthHeight, height: Constants.AnnotationSquareWidthHeight)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: leftButtonSize))
        
        button.setBackgroundImage(UIImage(named : "back arrow"), for: .normal)
        button.backgroundColor = UIColor.white
        button.addTarget(self, action: #selector(annotationCalloutTapped(_:)), for: .touchUpInside)
        
        view?.leftCalloutAccessoryView = button
        
        return view
    }
    
    @objc func annotationCalloutTapped(_ sender : UITapGestureRecognizer) {
        delegate?.newLocationSelectedFrom(placemark: selectedPin!)
        navigationController?.popViewController(animated: true)
    }
}

//MARK : - Handle Map Search Protocol methods

extension ActivityLocationSelectionViewController : HandleMapSearch {
    
    func dropPinZoomIn(placemark: MKPlacemark) {
        
        // cache the pin
        selectedPin = placemark
        
        //clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        annotation.subtitle = MKPlacemark.parseAddress(selectedItem: placemark)
        
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(Constants.latitudeSpan, Constants.longitudeSpan)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        
    }
    
}
