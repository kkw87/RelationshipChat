//
//  FirebaseDBStructure.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 12/14/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import Foundation
import Firebase

struct FlaggedUserBehaviors {
    static let Spam = "Spamming"
    static let InappropriateComments = "Lude comments"
    static let Harassment = "Harassment"
}

struct FirebaseDB {
    
    static let MainDatabase = Database.database().reference()
    static let FBStorage = Storage.storage().reference()
    
    static let NotificationSendAPIURLString = "https://fcm.googleapis.com/fcm/send"
    
    static let RelationshipUserNodeKey = "user"
    static let RelationshipRelationshipNodeKey = "relationship"
    static let RelationshipMessageNodeKey = "messages"
    static let RelationshipLocationNodeKey = "locations"
    static let RelationshipActivityNodeKey = "activities"
    static let RelationshipRequestKey = "relationship_request"
    static let ReportedUserNodeKey = "reported_user"
    
    static let MessageByRelationshipFanOutKey = "relationship_messages"
    static let ActivityByRelationshipFanOutKey = "relationship_activities"
    static let LocationsByRelationshipFanOutKey = "relationship_locations"
    
    static let NotificationRelationshipRequestDataKey = "relationshipID"
    static let NotificationRelationshipRequestSenderKey = "senderUID"
    
    //FBStorage nodes
    static let ProfileImageNodeKey = "profile_image"
    static let UserUploadedMediaNodeKey = "user_uploaded_media"
    
    static func sendNotification(toTokenID: String, titleText : String, bodyText : String, dataDict : [String :String]?, contentAvailable : Bool, completionHandler : @escaping (Error?)->Void) {
     
        let url = URL(string: FirebaseDB.NotificationSendAPIURLString)
        
        var postParams = [String : Any]()
        
        let notificationDict : [String : Any]
        if contentAvailable {
            notificationDict = ["body": bodyText, "title": titleText, "content_available" : true]
        } else {
            notificationDict = ["body": bodyText, "title": titleText]
        }
        
        if dataDict != nil {
            postParams = ["to": toTokenID,  "notification": notificationDict, "data" : dataDict!]
        } else {
             postParams = ["to": toTokenID,  "notification": notificationDict]
        }
        
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAPhB2Au4:APA91bGPQSTaOpHbJlcbl6VOYHXZQCa2s0rWr3nzuB3gKsRp79rx-qP25AnXfBFT9jqNC51C7Hm4e0F2Cf3KhQoG3woRoXCxYvmtqzUgH5Ia916l2VjiUAFNfCnLhfvvj4eSQTVT61-1", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postParams, options: JSONSerialization.WritingOptions())
        } catch {
            //Throw?
            print(error)
        }
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            guard error == nil else {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
        
        task.resume()
        
    }
}

struct FireBaseUserDefaults {
    static let UsersLoginName = "userLogin"
    static let UsersPassword = "password"
}

struct NotificatonChannels {
    static let RelationshipRequestChannel = NSNotification.Name(rawValue: "RelationshipRequestChannel")
    static let RelationshipRequestKey = "RelationshipRequestKey"
}

