//
//  RelationshipTableViewCell.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 12/29/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
//import Contacts
import CloudKit

@available(iOS 10.0, *)
class RelationshipTableViewCell: UITableViewCell {
    
    //MARK : - Constants
    struct Constants {
        static let DefaultErrorMessageTitle = "There seems to be a problem"
        static let UserErrorMessage = "We were unable to access your account"
        static let RelationshipActivityMessage = "Requesting a relationship..."
        static let UserInARelationshipErrorMessage = "You are already in a relationship or have one pending"
        static let RequestedUserInARelationshipMessage = "The user is already in a relationship or is awaiting a response from a request"
        static let RelationshipSuccessTitle = "Relationship Request Sent"
        static let RelationshipBodyMessage = "You successfully sent a relationship request!"
        static let DoneButtonText = "Done"
        static let RequestBodyText = "has requested to start a relationship with you!"
    }
    
    //MARK : - Outlets
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var relationshipButton: UIButton! {
        didSet {
            relationshipButton.roundEdges()
            relationshipButton.clipsToBounds = true
        }
    }
    
    @IBOutlet fileprivate weak var userName: UILabel!
    
    @IBOutlet weak var userImageView: UIImageView! {
        didSet {
            userImageView.roundEdges()
            userImageView.clipsToBounds = true
            userImageView.contentMode = .scaleAspectFill
        }
    }
    
    //MARK : - Instance Properties
    var delegate : RelationshipCellDelegate?
    
    var userRecord : CKRecord?
    var clickedUsersRecord : CKRecord? {
        didSet {
            if clickedUsersRecord != nil {
                let userInformation = Cloud.pullUserInformationFrom(usersRecordToLoad: clickedUsersRecord!)
                userName.text = userInformation.usersFullName
                userImage = userInformation.usersImage
            }
        }
    }
    
    var userImage : UIImage? {
        get {
            return userImageView.image
        } set {
            if newValue != nil {
                spinner.stopAnimating()
                spinner.isHidden = true
                userImageView.image = newValue!
            }
        }
    }
    
    //MARK : - Outlet functions
    @IBAction func requestRelationship(_: Any) {
        
        if userRecord?[Cloud.UserAttribute.Relationship] != nil {
            delegate?.displayAlertWithTitle(Constants.DefaultErrorMessageTitle, withBodyMessage: Constants.UserInARelationshipErrorMessage, completion: nil)
        } else if clickedUsersRecord?[Cloud.UserAttribute.Relationship] != nil {
            delegate?.displayAlertWithTitle(Constants.DefaultErrorMessageTitle, withBodyMessage: Constants.RequestedUserInARelationshipMessage, completion: nil)
        } else {
            
            
            let saveRecordsOperation = CKModifyRecordsOperation()
            saveRecordsOperation.recordsToSave = makeChangesToRecords()
            saveRecordsOperation.savePolicy = .allKeys
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
      
            saveRecordsOperation.modifyRecordsCompletionBlock = { [weak self] (savedRecords, deletedRecordsID, error) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: nil)
                    print("error, newrelationship from relationshiptableviewcell")
                    return
                }

                    self?.delegate?.displayAlertWithTitle(Constants.RelationshipSuccessTitle, withBodyMessage: Constants.RelationshipBodyMessage) {_ in
                        self?.delegate?.popBackToRoot()
                    }
                    
                    let newRelationship = savedRecords?.filter { $0[Cloud.RecordKeys.RecordType] as! String == Cloud.Entity.Relationship}.first
                    NotificationCenter.default.post(name: CloudKitNotifications.RelationshipUpdateChannel, object: nil, userInfo: [CloudKitNotifications.RelationshipUpdateKey : newRelationship!])
                
            }
            Cloud.CloudDatabase.PublicDatabase.add(saveRecordsOperation)
        }
        
    }
    
    //MARK : - Class functions
    
    func makeChangesToRecords() -> [CKRecord] {
        
        let newRelationship = CKRecord(recordType: Cloud.Entity.Relationship)
        newRelationship[Cloud.RelationshipAttribute.Users] = [CKReference(record: userRecord!, action: .deleteSelf)] as CKRecordValue?
        
        newRelationship[Cloud.RelationshipAttribute.Status] = Cloud.RelationshipStatus.Pending as CKRecordValue?
        newRelationship[Cloud.RecordKeys.RecordType] = Cloud.Entity.Relationship as CKRecordValue?
        
        let anniversaryActivity = CKRecord(recordType: Cloud.Entity.RelationshipActivity)
        anniversaryActivity[Cloud.RelationshipActivityAttribute.CreationDate] = Date() as CKRecordValue?
        anniversaryActivity[Cloud.RelationshipActivityAttribute.Message] = "Your anniversary" as CKRecordValue?
        anniversaryActivity[Cloud.RelationshipActivityAttribute.Name] = "Anniversary" as CKRecordValue?
        anniversaryActivity[Cloud.RelationshipActivityAttribute.SystemCreated] = Cloud.RelationshipActivitySystemCreatedTypes.Anniversary as CKRecordValue?
        anniversaryActivity[Cloud.RelationshipActivityAttribute.Relationship] = CKReference(record: newRelationship, action: .deleteSelf) as CKRecordValue?
        anniversaryActivity[Cloud.RecordKeys.RecordType] = Cloud.Entity.RelationshipActivity as CKRecordValue?
        
        let usersBirthdayActivity = CKRecord(recordType: Cloud.Entity.RelationshipActivity)
        
        let usersBirthdayDate = userRecord![Cloud.UserAttribute.Birthday] as! Date
        
        usersBirthdayActivity[Cloud.RelationshipActivityAttribute.CreationDate] = usersBirthdayDate as CKRecordValue?
        let usersName = userRecord![Cloud.UserAttribute.FirstName] as! String
        usersBirthdayActivity[Cloud.RelationshipActivityAttribute.Message] = "Today is \(usersName)'s birthday!" as CKRecordValue?
        usersBirthdayActivity[Cloud.RelationshipActivityAttribute.Relationship] = CKReference(record: newRelationship, action: .deleteSelf)
        usersBirthdayActivity[Cloud.RelationshipActivityAttribute.Name] = "\(usersName)'s birthday!" as CKRecordValue?
        usersBirthdayActivity[Cloud.RelationshipActivityAttribute.SystemCreated] = Cloud.RelationshipActivitySystemCreatedTypes.Birthday as CKRecordValue?
        usersBirthdayActivity[Cloud.RecordKeys.RecordType] = Cloud.Entity.RelationshipActivity as CKRecordValue?
        
        newRelationship[Cloud.RelationshipAttribute.Activities] = [CKReference(record: usersBirthdayActivity, action: .none), CKReference(record: anniversaryActivity, action: .none)] as CKRecordValue?
        
        let relationshipRequest = CKRecord(recordType: Cloud.Entity.RelationshipRequest)
        
        relationshipRequest[Cloud.RelationshipRequestAttribute.Sender] = CKReference(record: userRecord!, action: .deleteSelf) as CKRecordValue?
        
        relationshipRequest[Cloud.RelationshipRequestAttribute.Relationship] = CKReference(record: newRelationship, action: .deleteSelf) as CKRecordValue?
        
        relationshipRequest[Cloud.RelationshipRequestAttribute.UserToSendTo] = CKReference(record: clickedUsersRecord!, action: .deleteSelf) as CKRecordValue?
        
        relationshipRequest[Cloud.RecordKeys.RecordType] = Cloud.Entity.RelationshipRequest as CKRecordValue?
        
        userRecord?[Cloud.UserAttribute.Relationship] = CKReference(record: newRelationship, action: .none) as CKRecordValue?
        
        return [userRecord!, newRelationship, relationshipRequest, usersBirthdayActivity, anniversaryActivity]
    }
    
}
