//
//  ActivityTableViewCell.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 6/27/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import CloudKit

class ActivityTableViewCell: UITableViewCell {
    
    // MARK : - Constants
    struct Constants {
        static let DateFormatRepeatedActivity = "E, MMM d"
        static let DefaultDateFormat = "E, MMM/dd/yyyy"
        
        static let BackgroundImageAlpha : CGFloat = 0.3
    }
    
    // MARK : - Outlets
    @IBOutlet weak var activityTitle: UILabel!
    
    @IBOutlet weak var date: UILabel!
    
    @IBOutlet weak var daysUntil: UILabel!
    
    @IBOutlet weak var descriptionBox: UITextView! {
        didSet {
            descriptionBox.backgroundColor = UIColor.clear
        }
    }
    
    // MARK : - Instance Properties
    fileprivate lazy var dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MM d,yyyy"
        return formatter
    }()
    
    var activity : RelationshipActivity?{
        didSet {
            if activity != nil {
                setupCell()
            }
        }
    }
    
    
    // MARK : - Class functions
    fileprivate func setupCell() {
        
        activityTitle.text = activity?.activityRecord[Cloud.RelationshipActivityAttribute.Name] as? String ?? "Title"
        descriptionBox.text = activity?.activityRecord[Cloud.RelationshipActivityAttribute.Message] as! String
        
        func setupSystemActivity() {
            dateFormatter.dateFormat = Constants.DateFormatRepeatedActivity
            
            daysUntil.text = "\(activity!.daysUntilActivity)"
            date.text = dateFormatter.string(from: activity!.activityDate)
            
            //set background image, with alpha 
            let typeOfActivity = activity!.activityRecord[Cloud.RelationshipActivityAttribute.SystemCreated] as! String
            
            let cellBackgroundImageView : UIImageView
            switch typeOfActivity {
            case Cloud.RelationshipActivitySystemCreatedTypes.Anniversary:
                let anniversaryBackgroundImage = UIImage(named: "anniversarybackground")
                cellBackgroundImageView = UIImageView(image: anniversaryBackgroundImage)

            default:
                let birthdayBackgroundImage = UIImage(named: "birthdaybackground")
                cellBackgroundImageView = UIImageView(image: birthdayBackgroundImage)
            }
            
            cellBackgroundImageView.contentMode = .scaleAspectFill
            cellBackgroundImageView.alpha = Constants.BackgroundImageAlpha
            backgroundView = cellBackgroundImageView
            
        }
        
        
        //Setup cell for user made activities
        func setupUserMadeActivity() {
            dateFormatter.dateFormat = Constants.DefaultDateFormat
            if let activityDays = activity?.daysUntilActivity {
                switch activityDays {
                    case 0 :
                        daysUntil.text = "Today"
                    case -1 :
                    daysUntil.text = "1 day ago"
                default :
                    daysUntil.text = "\(activityDays)"
                }
            }
            
            backgroundView = nil
            date.text = dateFormatter.string(from: activity!.activityDate)
            
        }
        
        if activity != nil {
            
            if activity!.activityRecord[Cloud.RelationshipActivityAttribute.SystemCreated] != nil {
                setupSystemActivity()
            } else {
                setupUserMadeActivity()
            }
        }
    }
}
