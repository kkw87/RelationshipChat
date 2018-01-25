//
//  RelationshipChatTextMessage.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 1/24/18.
//  Copyright © 2018 KKW. All rights reserved.
//

import Foundation
import Firebase

class RelationshipChatTextMessage : RelationshipChatMessage {
    var text = ""

    
    func saveMessageToFB(completionHandler : @escaping (Error?, String?)->Void) {
        
        let messageValues = [RelationshipChatMessageKeys.MessageText : text, RelationshipChatMessageKeys.UserToSendToID : receivingUserID, RelationshipChatMessageKeys.SendingUserID : sendingUserID, RelationshipChatMessageKeys.MessageTimeStamp : timeStamp.timeIntervalSince1970, RelationshipChatMessageKeys.SenderDisplayName : senderDisplayName] as [String : Any]
        
        saveValues(messageValues: messageValues, completionHandler: completionHandler)
        
    }
    
    static func pullTextMessageFromFB(uid : String, completionHandler : @escaping (RelationshipChatTextMessage?)-> Void) {
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipMessageNodeKey).child(uid).observeSingleEvent(of: .value) { (snapshot) in
            
            let dictionaryValues = snapshot.value as! [String : Any]
            
            let messageID = snapshot.key
            
            guard let displayName = dictionaryValues[RelationshipChatMessageKeys.SenderDisplayName] as? String,  let messageText = dictionaryValues[RelationshipChatMessageKeys.MessageText] as? String, let relationshipUID = dictionaryValues[RelationshipChatMessageKeys.RelationshipID] as? String, let sendingID = dictionaryValues[RelationshipChatMessageKeys.SendingUserID] as? String, let receivingID = dictionaryValues[RelationshipChatMessageKeys.UserToSendToID] as? String, let messageDate = dictionaryValues[RelationshipChatMessageKeys.MessageTimeStamp] as? TimeInterval else {
                completionHandler(nil)
                return
            }
            
            
            let newMessage = RelationshipChatTextMessage()
            newMessage.senderDisplayName = displayName
            newMessage.text = messageText
            newMessage.relationshipID = relationshipUID
            newMessage.sendingUserID = sendingID
            newMessage.receivingUserID = receivingID
            newMessage.timeStamp = Date(timeIntervalSince1970: messageDate)
            newMessage.messageUID = messageID

            if newMessage.sendingUserID != Auth.auth().currentUser?.uid {
                newMessage.deleteMessageFromFB()
            }
            completionHandler(newMessage)
        }
    }
    
}
