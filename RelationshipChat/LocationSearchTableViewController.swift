//
//  LocationSearchTableViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 8/2/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import MapKit

class LocationSearchTableViewController: UITableViewController {
    
    //MARK: - Constants
    struct Storyboard {
        static let CellIdentifier = "search cell identifier"
    }
    
    //MARK: - Instance properties
    var matchingItems = [MKMapItem]()
    var mapView : MKMapView?
    var handleMapSearchDeleate : HandleMapSearch?
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.CellIdentifier, for: indexPath)
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = MKPlacemark.parseAddress(selectedItem: selectedItem)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        handleMapSearchDeleate?.dropPinZoomIn(placemark: selectedItem)
        dismiss(animated: true, completion: nil)
    }

}

//MARK: - UISearchResultsUpdating methods

extension LocationSearchTableViewController : UISearchResultsUpdating {
        func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView, let searchBarText = searchController.searchBar.text else {
            return
        }
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        search.start { (response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
    
}
