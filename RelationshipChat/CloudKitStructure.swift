//
//  CloudKitExtensions.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/19/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import CloudKit
import Foundation
import MapKit


struct Cloud {
    
    // MARK: -  Entitiy
    struct Entity {
        static let User = "User"
        static let Relationship = "Relationship"
        static let RelationshipRequest = "RelationshipRequest"
        static let RelationshipRequestResponse = "RelationshipRequestResponse"
        static let Message = "Message"
        static let UserTypingIndicator = "TypingIndicator"
        static let RelationshipActivity = "RelationshipActivity"
        static let UserLocation = "UserLoggedLocation"
    }
    
    struct RecordKeys {
        static let RecordType = "recordsType"
    }
    
    // MARK: - Database
    struct CloudDatabase {
        static let PublicDatabase = CKContainer.default().publicCloudDatabase
        static let PrivateDatabase = CKContainer.default().privateCloudDatabase
    }
    
    struct UserTypingIndicatorAttributes {
        static let TypingStatus = "status"
        static let Relationship = "relationship"
    }
    
    
    // MARK: - Entity Attributes
    
    struct UserLocationAttribute {
        static let UserName = "usersName"
        static let Location = "loggedLocation"
        static let LocationStringName = "locationName"
        static let Relationship = "relationship"
    }
    
    struct RelationshipRequestAttribute {
        static let Sender = "sender"
        static let UserToSendTo = "to"
        static let Relationship = "relationship"
    }
    
    struct RelationshipRequestResponseAttribute {
        static let UserToSendTo = "to"
        static let StatusUpdate = "status"
        static let SendingUsersName = "sendingName"
    }
    
    struct MessageAttribute {
        static let SenderDisplayName = "senderDisplayName"
        static let Text = "text"
        static let Relationship = "relationship"
        static let Media = "media"
        static let SenderID = "senderID"
    }
    
    struct UserAttribute {
        static let FirstName = "firstName"
        static let LastName = "lastName"
        static let NickName = "nickName"
        static let Birthday = "birthday"
        static let Gender = "gender"
        static let ProfileImage = "picture"
        static let Relationship = "relationship"
    }
    
    struct RelationshipAttribute {
        static let Status = "status"
        static let StartDate = "startDate"
        static let Users = "users"
        static let Activities = "activity"
        static let Locations = "dailyLocations"
    }
    
    struct RelationshipActivityAttribute {
        static let Name = "activityName"
        static let CreationDate = "date"
        static let Message = "bodyMessage"
        static let Relationship = "relationship"
        static let SystemCreated = "systemActivity"
        static let Location = "activityLocation"
        static let LocationStringName = "locationName"
        static let LocationStringAddress = "locationAddress"
    }
    
    struct RelationshipActivitySystemCreatedTypes {
        static let Birthday = "usersBirthday"
        static let Anniversary = "relationshipAnniversary"
    }
    
    struct Gender {
        static let Male = "Man"
        static let Female = "Woman"
    }
    
    // MARK: -  Relationship Update Status Response
    struct Status {
        static let Accepted = "Accepted"
        static let Declined = "Declined"
    }
    
    struct UserTypingStatus {
        static let Typing = "typing"
        static let DoneTyping = "done"
    }
    
    // MARK: - Subscription Names
    struct SubscriptionNames {
        static let TypingSubscription = "TypingSub"
        static let RelationshipSubscription = "RelationshipSub"
        static let SecondaryUserSubscription = "SecondarySub"
        static let ActivitySubscription = "ActivitySub"
        static let MessageSubscription = "MessageSub"
    }
    
    // MARK: - Response Messages
    struct Messages {
        static let RelationshipRequestMessage = "You have recieved a relationship request!"
        static let RelationshipResponseMessage = "You have received a response to your relationship request!"
        static let MessageRecieved = "You got a message!"
        static let ActivityMessage = "You have something new planned!"
    }
    
    // MARK: - Relationship Status
    struct RelationshipStatus {
        static let Single = "Single"
        static let Dating = "Dating"
        static let Married = "Married"
        static let Complicated = "Complicated"
        static let Pending = "Relationship Request Sent"
    }
    
    // MARK : - Helper Functions
    @available(iOS 10.0, *)
    static func saveMessageSubscription(_ messageRelationship : CKRecord, currentUser user : CKRecord) {
        
        let predicate = NSPredicate(format: "relationship = %@", messageRelationship.recordID)
        
        let messageSubscription = CKQuerySubscription(recordType: Cloud.Entity.Message, predicate: predicate, subscriptionID: Cloud.SubscriptionNames.MessageSubscription, options: CKQuerySubscriptionOptions.firesOnRecordCreation)
        let rinfo = CKNotificationInfo()
        rinfo.alertBody = Cloud.Messages.MessageRecieved
        rinfo.desiredKeys = [Cloud.RecordKeys.RecordType]
        rinfo.shouldSendContentAvailable = true
        rinfo.shouldBadge = true
        rinfo.soundName = "messageSound"
        messageSubscription.notificationInfo = rinfo
        
        let activityPredicate = NSPredicate(format: "relationship = %@", messageRelationship.recordID)
        let activitySubscription = CKQuerySubscription(recordType: Cloud.Entity.RelationshipActivity, predicate: activityPredicate, options: [.firesOnRecordCreation, .firesOnRecordUpdate])
        
        let activitySubscriptionInformation = CKNotificationInfo()
        activitySubscriptionInformation.shouldBadge = false
        activitySubscriptionInformation.shouldSendContentAvailable = true
        activitySubscriptionInformation.desiredKeys = [Cloud.RecordKeys.RecordType]
        activitySubscriptionInformation.alertBody = Messages.ActivityMessage
        
        activitySubscription.notificationInfo = activitySubscriptionInformation
        
        //Temporary Testing Predicate 
        let typingPredicate = NSPredicate(format: "relationship = %@", messageRelationship.recordID)
        let typingSubscription = CKQuerySubscription(recordType: Cloud.Entity.UserTypingIndicator, predicate: typingPredicate, options: CKQuerySubscriptionOptions.firesOnRecordCreation)
        
        let typingNotificationInfo = CKNotificationInfo()
        typingNotificationInfo.desiredKeys = [Cloud.UserTypingIndicatorAttributes.TypingStatus, Cloud.RecordKeys.RecordType]
        typingNotificationInfo.shouldSendContentAvailable = true 
        
        typingSubscription.notificationInfo = typingNotificationInfo
        
        
        let saveSubscriptionOps = CKModifySubscriptionsOperation()
        saveSubscriptionOps.subscriptionsToSave = [messageSubscription, typingSubscription, activitySubscription]
        
        saveSubscriptionOps.modifySubscriptionsCompletionBlock = { (savedRecords, deletedRecordsID, error) in
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: nil)
                print("error saving message subscription")
                return
            }
        }
        Cloud.CloudDatabase.PublicDatabase.add(saveSubscriptionOps)
    }
    
    
    static func deleteTypingIndicatorsFrom(_ fromRelationship : CKRecord) {
        let predicate = NSPredicate(format: "relationship = %@", fromRelationship.recordID)
        let query = CKQuery(recordType: Cloud.Entity.UserTypingIndicator, predicate: predicate)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil) { (typingIndicators, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard error == nil else {
                print(error!)
                return
            }
            
            let deleteIndicatorDeleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: typingIndicators?.map {
                $0.recordID
                })
            
            deleteIndicatorDeleteOperation.modifyRecordsCompletionBlock = { (_, _, error) in
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: nil)
                    print("error deleting typinc indicators")
                    return
                }
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            Cloud.CloudDatabase.PublicDatabase.add(deleteIndicatorDeleteOperation)
        }
    }
    
    static func pullUserInformationFrom(usersRecordToLoad : CKRecord) -> (usersImage : UIImage?, usersFullName : String, usersFirstName : String, usersLastName : String, usersBirthday : Date, usersGender : String) {
        
        let firstName = usersRecordToLoad[Cloud.UserAttribute.FirstName] as? String ?? ""
        let lastName = usersRecordToLoad[Cloud.UserAttribute.LastName] as? String ?? ""
        let birthday = usersRecordToLoad[Cloud.UserAttribute.Birthday] as? Date ?? Date()
        let gender = usersRecordToLoad[Cloud.UserAttribute.Gender] as? String ?? Cloud.Gender.Male
        
        var imageToSet = UIImage(named: "DefaultPicture")
        let name = "\(firstName) \(lastName)"
        
        if let cachedUserImage = RCCache.shared[usersRecordToLoad.recordID.recordName as AnyObject] {
            imageToSet = cachedUserImage
        } else {
            if let profilePicture = usersRecordToLoad[Cloud.UserAttribute.ProfileImage] as? CKAsset{
                let pictureData = try? Data(contentsOf: profilePicture.fileURL)
                if pictureData != nil {
                    let pictureImage = UIImage(data: pictureData!)
                    imageToSet = pictureImage
                    RCCache.shared[usersRecordToLoad.recordID.recordName as AnyObject] = pictureImage
                }
            }
            
        }
        return (imageToSet, name, firstName, lastName, birthday, gender)
    }
    
    static func pullRelationshipRequest(fromSender : CKRecordID, relationshipRecordID : CKRecordID, relationshipRequestID : CKRecordID, presentingVC : UIViewController?, completionHandler : @escaping (CKRecord, CKRecord) -> ()) -> Void {
        let fetchOperation = CKFetchRecordsOperation(recordIDs: [fromSender, relationshipRecordID])
        fetchOperation.fetchRecordsCompletionBlock = { (fetchedRecords, error) in
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: nil)
                print(error!)
                return
            }
            
            if fetchedRecords != nil {
                completionHandler(fetchedRecords![fromSender]!, fetchedRecords![relationshipRecordID]!)
            }
            
        }
        Cloud.CloudDatabase.PublicDatabase.add(fetchOperation)
        
    }
    
    static func errorHandling(_ error : Error, sendingViewController : UIViewController?) -> CKError.Code? {
        
        sendingViewController?.dismiss(animated: true, completion: nil)
        
        switch error._code {
        case CKError.notAuthenticated.rawValue:
            let alertController = UIAlertController(title: "Not signed into iCloud", message: "Please sign into your iCloud account", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) in
                UIApplication.shared.open(URL(string: "App-Prefs:root=CASTLE")!, options: [:], completionHandler: nil)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            DispatchQueue.main.async {
                sendingViewController?.dismiss(animated: true, completion: nil)
                sendingViewController?.present(alertController, animated: true, completion: nil)
            }
            return nil
            
        case CKError.networkUnavailable.rawValue:
            let alertController = UIAlertController(title: "No network availability", message: "Unable to access the network", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
            DispatchQueue.main.async {
                sendingViewController?.dismiss(animated: true, completion: nil)
                sendingViewController?.present(alertController, animated: true, completion: nil)
            }
            return nil
        case CKError.unknownItem.rawValue :
            sendingViewController?.displayAlertWithTitle("Record no longer exists!", withBodyMessage: "Your relationship record no longer exists!", withBlock: nil)
            return CKError.unknownItem
        default:
            sendingViewController?.displayAlertWithTitle("Error!", withBodyMessage: error.localizedDescription, withBlock: nil)
            return nil
        }
    }
    
    @available(iOS 10.0, *)
    static func addsubscriptionToSecondaryUserChanges(currentRelationship : CKRecord, currentUserRecord : CKRecord) {
        
        let secondaryUserPredicate = NSPredicate(format: "relationship = %@", currentRelationship.recordID)
        
        
        let secondaryUserSubscription = CKQuerySubscription(recordType: Cloud.Entity.User, predicate: secondaryUserPredicate, subscriptionID: Cloud.SubscriptionNames.SecondaryUserSubscription, options: CKQuerySubscriptionOptions.firesOnRecordUpdate)
        
        let subscriptionOptions = CKNotificationInfo()
        subscriptionOptions.shouldBadge = false
        subscriptionOptions.shouldSendContentAvailable = true
        subscriptionOptions.desiredKeys = [Cloud.UserAttribute.LastName, Cloud.RecordKeys.RecordType]
        secondaryUserSubscription.notificationInfo = subscriptionOptions
        
        Cloud.CloudDatabase.PublicDatabase.save(secondaryUserSubscription) {
            if $1 != nil {
                _ = Cloud.errorHandling($1!, sendingViewController: nil)
            }
        }
        
    }
}



