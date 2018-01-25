//
//  UpcomingActivitiesTableViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/13/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import CloudKit

@available(iOS 10.0, *)
class UpcomingActivitiesTableViewController: ActivityTableViewController{
    
    // MARK: - Constants
    struct Storyboard {
        static let NewActivitySegue = "New Activity"
    }
    
    //MARK: - Outlets
    @IBOutlet weak var newActivityButton: UIBarButtonItem!
    
    // MARK: - Instance Properties
    override var activities: [RelationshipChatActivity] {
        didSet {
//            guard let relationshipStatus = dataSource?.inAValidRelationshipCheck() else {
//                return
//            }
//            
//            if relationshipStatus {
//                newActivityButton.isEnabled = true
//            } else {
//                newActivityButton.isEnabled = false
//            }
        }
    }
    
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.NewActivitySegue :
                if let newActivityVC = (segue.destination as? UINavigationController)?.contentViewController as? NewActivityViewController{
                }
            default :
                break
            }
        }
    }
    
    @IBAction func unwindFromNewActivity(segue : UIStoryboardSegue) {
        
    }
    
}
