//
//  CheckInLocationTableViewCell.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 8/25/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import MapKit

protocol CheckInLocationCellDelegate : MKMapViewDelegate {
    //
}

class CheckInLocationTableViewCell: UITableViewCell {
    
    //MARK : - Constants
    struct Constants {
        static let DateFormat = "h:mm a"
        static let MapSpan : CLLocationDegrees = 2.0
    }
    

    //MARK : - Model
    var locationCoordinate : CLLocation? {
        didSet {
            let locationCoordinates = locationCoordinate?.coordinate
            let mapRegion = MKCoordinateRegion(center: locationCoordinates!, span: MKCoordinateSpan(latitudeDelta: Constants.MapSpan, longitudeDelta: Constants.MapSpan))
            mapView?.setRegion(mapRegion, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationCoordinates!
            
            mapView.addAnnotation(annotation)
        }
    }
    var locationName : String? {
        didSet {
            mainLabel?.text = locationName
        }
    }
    
    var locationCreationTime : Date? {
        didSet {
            timeLabel?.text = dateFormatter.string(from: locationCreationTime!)
        }
    }
    
    //Should be the activity here 
    
    //MARK : - Instance properties
    lazy var dateFormatter : DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.DateFormat
        return dateFormatter
    }()
    
    var delegate : CheckInLocationCellDelegate?

    //MARK: - Outlets

    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = delegate
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
