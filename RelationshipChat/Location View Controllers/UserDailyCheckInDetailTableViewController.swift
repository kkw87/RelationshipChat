//
//  UserDailyCheckInDetailTableViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/12/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import MapKit
import CloudKit

class UserDailyCheckInDetailTableViewController: UITableViewController, CheckInLocationCellDelegate {
    
    //MARK: - Model 
    var locationRecord : CKRecord? {
        didSet {
            tableView.reloadData()
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
    }

    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideEmptyCells()
        navigationItem.largeTitleDisplayMode = .never
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationRecord == nil ? 0 : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.CellIdentifier, for: indexPath) as! CheckInLocationTableViewCell
        
        let location = locationRecord![Cloud.UserLocationAttribute.Location] as! CLLocation

        let creationTime = locationRecord!.creationDate
        
        let locationName = locationRecord![Cloud.UserLocationAttribute.LocationStringName] as! String
        
        cell.delegate = self
        cell.locationCoordinate = location
        cell.locationName = locationName
        cell.locationCreationTime = creationTime
        
        return cell
    }
    
    //Comment back in for swipe to delete, dont forget the unwind in CheckInByDay
//    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//
//        let deleteAction = UIContextualAction(style: .destructive, title: Constants.SwipeToDeleteText) { [weak self] (action, view, completionHandler) in
//            self?.performSegue(withIdentifier: Storyboard.SwipeToDeleteUnwindSegue, sender: self)
//            completionHandler(true)
//        }
//
//        deleteAction.backgroundColor = UIColor.red
//        //deleteAction.image =
//        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
//        return configuration
//    }
//
    
    //MARK: - Class methods
    @objc func navigateToAnnotation(annotationView : MKAnnotation) {
        //TODO, incomplete, clicking on the arrow should send you to maps with navigation
        
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
