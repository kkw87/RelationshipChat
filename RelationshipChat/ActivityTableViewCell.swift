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
        static let DefaultDateFormat = "E, MM/dd/yyyy"
        
        static let DaysUntilTitleLabelPastActivity = "Days ago"
        
        static let BackgroundImageAlpha : CGFloat = 0.3
    }
    
    // MARK : - Outlets
    @IBOutlet weak var activityTitle: UILabel!
    
    @IBOutlet weak var daysUntilTitle: UILabel!
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
    
    var activity : RelationshipChatActivity?{
        didSet {
            if activity != nil {
                setupCell()
            }
        }
    }
    
    
    // MARK : - Class functions
    fileprivate func setupCell() {
        
        activityTitle.text = activity?.title
        descriptionBox.text = activity?.description
        
        func setupSystemActivity() {
            dateFormatter.dateFormat = Constants.DateFormatRepeatedActivity
            
            //TODO, implement days until text
            daysUntil.text = "\(activity!.daysUntil)"
            date.text = dateFormatter.string(from: activity!.creationDate)
            
            //set background image, with alpha 
            if let typeOfActivity = activity?.systemActivity {
            
            let cellBackgroundImageView : UIImageView
            switch typeOfActivity {
            case SystemActivity.Anniversary:
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
            
        }
        
        
        //Setup cell for user made activities
        func setupUserMadeActivity() {
            dateFormatter.dateFormat = Constants.DefaultDateFormat
            let activityDays = activity!.daysUntil 
                switch activityDays {
                    case 0 :
                        daysUntil.text = "Today"
                case let day where day < 0 :
                    daysUntil.text = "1 day ago"
                default :
                    daysUntil.text = "\(activityDays)"
                }
            
            
            backgroundView = nil
            date.text = dateFormatter.string(from: activity!.creationDate)
            
        }
        
        if activity != nil {
            
            if activity!.systemActivity != nil {
                setupSystemActivity()
            } else {
                setupUserMadeActivity()
            }
        }
    }
}
