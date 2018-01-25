//
//  RelationshipChatMediaMessage.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 1/24/18.
//  Copyright © 2018 KKW. All rights reserved.
//

import Foundation
import Firebase

class RelationshipChatMediaMessage : RelationshipChatMessage {
    var image : UIImage?
    var imageName : String?
    var imageWidth : CGFloat?
    var imageHeight : CGFloat?
    var videoName : String?
    var video : Data?
    var videoDownloadURL : URL?
    
    
    func saveMediaMessageToFB(imageUrlString : String, imageWidth : CGFloat, imageHeight : CGFloat, videoURL : String?, videoName : String?, completionHandler : @escaping (Error?, String?)->Void) {
        
        var messageValues = [RelationshipChatMessageKeys.UserToSendToID : receivingUserID, RelationshipChatMessageKeys.SendingUserID : sendingUserID, RelationshipChatMessageKeys.MessageTimeStamp : timeStamp.timeIntervalSince1970, RelationshipChatMessageKeys.SenderDisplayName : senderDisplayName, RelationshipChatMessageKeys.ImageName : imageName!, RelationshipChatMessageKeys.ImageURL : imageUrlString, RelationshipChatMessageKeys.ImageWidth : imageWidth, RelationshipChatMessageKeys.ImageHeight : imageHeight] as [String : Any]
        
        if videoURL != nil, videoName != nil {
            messageValues[RelationshipChatMessageKeys.VideoName] = videoName!
            messageValues[RelationshipChatMessageKeys.VideoURL] = videoURL!
        }
        
        saveValues(messageValues: messageValues, completionHandler: completionHandler)
        
    }
    
    static func pullMessageFromFB(uid : String, completionHandler : @escaping (RelationshipChatMediaMessage?)-> Void) {
        
        func downloadVideoTo(relationshipChatMessage : RelationshipChatMediaMessage, videoDownloadURL : URL, completionHandler : @escaping(RelationshipChatMediaMessage?)-> Void) {
            
                DispatchQueue.global(qos: .userInitiated).async {
                    let videoDownloadTask = URLSession.shared.dataTask(with: videoDownloadURL, completionHandler: { (videoData, response, error) in
                        
                        guard error == nil, videoData != nil else {
                            completionHandler(nil)
                            return
                        }
                        
                        relationshipChatMessage.video = videoData!
                        relationshipChatMessage.videoDownloadURL = videoDownloadURL
                        //Need the actual video file, TODO
                        if relationshipChatMessage.sendingUserID != Auth.auth().currentUser?.uid {
                            relationshipChatMessage.deleteMessageFromFB()
                        }
                        completionHandler(relationshipChatMessage)
                        
                    })
                    
                    videoDownloadTask.resume()
                }         
        }
        
        func downloadMediaFiles(relationshipChatMessage : RelationshipChatMediaMessage, imageDownloadURL : URL, videoDownloadURL : URL?, completionHandler : @escaping (RelationshipChatMediaMessage?)-> Void) {
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                let imageDownloadTask = URLSession.shared.dataTask(with: imageDownloadURL, completionHandler: { (data, response, error) in
                    guard error == nil else {
                        print(error!)
                        completionHandler(nil)
                        return
                    }
                    
                    guard let mediaData = data, let downloadedImage = UIImage(data: mediaData) else {
                        completionHandler(nil)
                        return
                    }
                    
                    relationshipChatMessage.image = downloadedImage
                    
                    if videoDownloadURL != nil {
                        downloadVideoTo(relationshipChatMessage: relationshipChatMessage, videoDownloadURL: videoDownloadURL!, completionHandler: completionHandler)
                    } else {
                        
                        if relationshipChatMessage.sendingUserID != Auth.auth().currentUser?.uid {
                            relationshipChatMessage.deleteMessageFromFB()
                        }
                        completionHandler(relationshipChatMessage)
                    }
                    
                })
                
                imageDownloadTask.resume()
            }
        }
    
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipMessageNodeKey).child(uid).observeSingleEvent(of: .value) { (snapshot) in
            
            let dictionaryValues = snapshot.value as! [String : Any]
            
            let messageID = snapshot.key
            
            guard let displayName = dictionaryValues[RelationshipChatMessageKeys.SenderDisplayName] as? String,
                let relationshipUID = dictionaryValues[RelationshipChatMessageKeys.RelationshipID] as? String,
                let sendingID = dictionaryValues[RelationshipChatMessageKeys.SendingUserID] as? String,
                let receivingID = dictionaryValues[RelationshipChatMessageKeys.UserToSendToID] as? String,
                let messageDate = dictionaryValues[RelationshipChatMessageKeys.MessageTimeStamp] as? TimeInterval,
                let mediaURLString = dictionaryValues[RelationshipChatMessageKeys.ImageURL] as? String,
                let mediaName = dictionaryValues[RelationshipChatMessageKeys.ImageName] as? String,
                let mediaURL = URL(string: mediaURLString),
                let downloadedImageWidth = dictionaryValues[RelationshipChatMessageKeys.ImageWidth] as? CGFloat,
                let downloadedImageHeight = dictionaryValues[RelationshipChatMessageKeys.ImageHeight] as? CGFloat else {
                    completionHandler(nil)
                    return
            }
            
            let newMessage = RelationshipChatMediaMessage()
            newMessage.senderDisplayName = displayName
            newMessage.relationshipID = relationshipUID
            newMessage.imageName = mediaName
            newMessage.imageWidth = downloadedImageWidth
            newMessage.imageHeight = downloadedImageHeight
            newMessage.sendingUserID = sendingID
            newMessage.receivingUserID = receivingID
            newMessage.timeStamp = Date(timeIntervalSince1970: messageDate)
            newMessage.messageUID = messageID
            
            //set video name if available
            if let videoFileName = dictionaryValues[RelationshipChatMessageKeys.VideoName] as? String {
                newMessage.videoName = videoFileName
            }
            
            if let videoDownloadString = dictionaryValues[RelationshipChatMessageKeys.VideoURL] as? String, let videoDownloadURL = URL(string: videoDownloadString) {
             
                downloadMediaFiles(relationshipChatMessage: newMessage, imageDownloadURL: mediaURL, videoDownloadURL: videoDownloadURL, completionHandler: completionHandler)
            } else {
                
                
                downloadMediaFiles(relationshipChatMessage: newMessage, imageDownloadURL: mediaURL, videoDownloadURL: nil, completionHandler: completionHandler)
            }

        }
    }
    
    override func deleteMessageFromFB() {
        super.deleteMessageFromFB()
        FirebaseDB.FBStorage.child(FirebaseDB.UserUploadedMediaNodeKey).child(relationshipID).child(imageName!).delete(completion: nil)
        
    }
}
