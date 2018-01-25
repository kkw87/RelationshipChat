//
//  RelationshipChatMessage.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 12/14/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import Foundation
import Firebase

struct RelationshipChatMessageKeys {
    //Message keys
    static let MessageText = "text"
    
    //All keys
    static let UserToSendToID = "to"
    static let SendingUserID = "from"
    static let MessageTimeStamp = "time"
    static let RelationshipID = "relationship"
    static let SenderDisplayName = "display_name"
    
    //Image Keys
    static let ImageURL = "image_download_url"
    static let ImageName = "image_name"
    static let ImageWidth = "image_width"
    static let ImageHeight = "image_height"
    
    //Video keys 
    static let VideoURL = "video_download_url"
    static let VideoName = "video_name"

}

class RelationshipChatMessage : NSObject {
    var senderDisplayName = ""
    var relationshipID = ""
    var sendingUserID = ""
    var receivingUserID = ""
    var timeStamp = Date()
    var messageUID = ""
 
    func saveValues(messageValues : [String : Any], completionHandler : @escaping (Error?, String?)->Void) {
        
        let messageReference = FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipMessageNodeKey).childByAutoId()
        
        messageReference.updateChildValues(messageValues) { (error, savedRef) in
            guard error == nil else {
                completionHandler(error!, nil)
                return
            }
            FirebaseDB.MainDatabase.child(FirebaseDB.MessageByRelationshipFanOutKey).child(self.relationshipID).updateChildValues([savedRef.key : self.sendingUserID], withCompletionBlock: { (error, _) in
                
                guard error == nil else {
                    completionHandler(error!, nil)
                    return
                }
                
                completionHandler(nil, savedRef.key)
            })
            
        }
    }
    
    func deleteMessageFromFB() {
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipMessageNodeKey).child(messageUID).removeValue()
        
        FirebaseDB.MainDatabase.child(FirebaseDB.MessageByRelationshipFanOutKey).child(relationshipID).child(messageUID).removeValue()
    }
    
}


