//
//  UserDailyCheckInByDayTableViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 8/25/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import Firebase
import MapKit

protocol LocationDataSource {
    func delete(locationUID : String)
}

class UserDailyCheckInByDayTableViewController: UITableViewController {
    
    //MARK : - Constants
    struct Storyboard {
        static let DetailSegue = "To Detail Segue"
        static let CellIdentifier = "Location Cell"
        static let SwipeToDeleteUnwindSegue = "ActivityByDayDeleted" 
    }
    
    struct Constants {
        static let SwipeToDeleteText = "Delete"
    }
    
    //MARK : - Model
    var userLocations : [RelationshipChatLocation]? {
        didSet {
            if userLocations?.count == 0 {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: Storyboard.SwipeToDeleteUnwindSegue, sender: self)
                }
            } else {
                userLocations?.sort {
                    $0.creationDate < $1.creationDate
                }
                
                DispatchQueue.main.async {
                    self.tableView?.reloadData()
                }
            }
        }
    }
    
    var dataSource : LocationDataSource?
    
    //MARK : - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideEmptyCells()
        navigationItem.largeTitleDisplayMode = .never
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return userLocations?.count ?? 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.CellIdentifier, for: indexPath)
        
        guard userLocations != nil else {
            return cell
        }
        
        let currentLocation = userLocations![indexPath.row]
        
        let locationStringName = currentLocation.locationName
        let locationCreatorName = currentLocation.creatingUserName
        
        cell.textLabel?.text = locationStringName
        cell.detailTextLabel?.text = locationCreatorName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: Constants.SwipeToDeleteText) { [weak self] (action, view, completionHandler) in
            
            
            if let locationToDelete = self?.userLocations?[indexPath.row] {
                self?.updateRelationshipWithDeleted(location: locationToDelete)
                completionHandler(true)
            } else {
                //Print, some kind of alert to the user
                completionHandler(false)
            }
        }
        
        //deleteAction.image needs to be set 
        deleteAction.backgroundColor = UIColor.red
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return configuration
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.DetailSegue:
                if let detailTV = segue.destination as? UserDailyCheckInDetailViewController {
                    let indexPath = tableView.indexPath(for: sender as! UITableViewCell)!
                    let selectedLocation = userLocations![indexPath.row]
                    let locationCreatorName = selectedLocation.creatingUserName
                    detailTV.navigationItem.title = locationCreatorName
                    detailTV.location = selectedLocation
                }
            default:
                break
            }
        }
    }
    
    //MARK: - Class Methods
    fileprivate func updateRelationshipWithDeleted(location : RelationshipChatLocation) {
        DispatchQueue.main.async {
            
            RelationshipChatLocation.deleteLocationFromDB(withUID: location.uid, completionHandler: { (error) in
                guard error == nil else {
                    print(error!)
                    return
                }
                
                DispatchQueue.main.async {
                    self.userLocations = self.userLocations?.filter {
                        $0.uid != location.uid
                    }
                    
                    self.tableView.reloadData()
                    
                }
            })
            
        }

    }
    
}
