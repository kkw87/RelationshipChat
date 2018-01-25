//
//  RelationshipChatUser.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 12/14/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import Foundation
import Firebase

struct UsersGender {
    static let Male = "Male"
    static let Female = "Female"
}


struct RelationshipChatUserKeys {
    static let FirstNameKey = "firstName"
    static let LastNameKey = "lastName"
    static let BirthdayKey = "birthday"
    static let GenderKey = "gender"
    static let ProfileImageKey = "profileImage"
    static let RelationshipKey = "relationship"
    static let FullName = "fullName"
    static let NotificationTokenID = "tokenID"
    static let BirthdayActivityID = "user_birthday_activity_id"
}

class RelationshipChatUser : NSObject {
    var userUID : String?
    var firstName = ""
    var lastName = ""
    var birthday = Date()
    var gender = ""
    var profileImageURL : String? {
        didSet {
            
        }
    }
    
    var tokenID = ""
    var relationship : String?
    
    private let profileImageCache = NSCache<NSString, UIImage>()
    
    func deleteUser(completionHandler : @escaping (Error?) -> Void) {

        guard let currentUser = Auth.auth().currentUser else {
            completionHandler(nil)
            return
        }
        
        if relationship != nil {
            
            RelationshipChatRelationship.deleteRelationship(relationshipUID: relationship!, completionHandler: { (error) in
                guard error == nil else {
                    print(error!)
                    return
                }
            })
        }
        
        if profileImageURL != nil {
            
            FirebaseDB.FBStorage.child(RelationshipChatUserKeys.ProfileImageKey).child(currentUser.uid).delete(completion: { (error) in
                guard error == nil else {
                    completionHandler(error)
                    return
                }
                completionHandler(nil)
            })
        }
        
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(currentUser.uid).removeValue { (error, _) in
            
            guard error == nil else {
                completionHandler(error)
                return
            }
            Auth.auth().currentUser?.delete(completion: nil)
            completionHandler(nil)
            FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(currentUser.uid).removeAllObservers()            
        }
        
    }
    
    
    func getUsersProfileImage(completionHandler userCalledCompletionBlock : @escaping (UIImage?, Error?) -> Void) {
        //Convert the URL string to NSString to use for image lookup in the cache
        guard let imageURl = profileImageURL else {
            return
        }
        
        let cacheKey = NSString(string : imageURl)
        
        if let cachedProfileImage = profileImageCache.object(forKey: cacheKey) {
            userCalledCompletionBlock(cachedProfileImage, nil)
        } else if let imageDownloadURL = URL(string: imageURl) {
            
            DispatchQueue.global(qos: .userInitiated).async {
               let task = URLSession.shared.dataTask(with: imageDownloadURL, completionHandler: { [weak self](data, response, error) in
                    guard error == nil else {
                        userCalledCompletionBlock(nil, error!)
                        return
                    }
                    if let userImage = UIImage(data: data!) {
                        self?.profileImageCache.setObject(userImage, forKey: cacheKey)
                        userCalledCompletionBlock(userImage, nil)
                    }
                })
                
                task.resume()
                
            }
            
            
        }
        
    }
    
    func saveUserToDB(userImage : UIImage?, completionBlock : @escaping (Bool, Error?)->Void) {
        
        //Nested func to save the user after the image has been sorted out
        func saveUserWith(uid : String, valuesToSave userValues : [String : Any]) {
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            //Create new node for user to save to Firebase
            let newUser = FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(uid)
            
            //Save user to firebase
            newUser.updateChildValues(userValues, withCompletionBlock: {(err, ref) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard err == nil else {
                    completionBlock(false, err!)
                    return
                }
                
                completionBlock(true, nil)
            })
        }
        
        
        
        //Make sure user is authenticated and has a uid from firebase
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
    
        
        var userValuesToSave = [RelationshipChatUserKeys.FirstNameKey : firstName, RelationshipChatUserKeys.LastNameKey : lastName, RelationshipChatUserKeys.BirthdayKey : birthday.timeIntervalSince1970, RelationshipChatUserKeys.GenderKey : gender, RelationshipChatUserKeys.FullName : fullName, RelationshipChatUserKeys.NotificationTokenID : Messaging.messaging().fcmToken!] as [String : Any]
        
        if relationship != nil {
            userValuesToSave[RelationshipChatUserKeys.RelationshipKey] = relationship!
        }
        
        //Convert image to data to upload to Firebase storage with JPEG compression
        if let imageToSave = userImage, let uploadData = UIImageJPEGRepresentation(imageToSave, 0.1) {
            
            //Upload data to storage
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            let imageName = "\(uid).jpg"
            
            
            //Call profile image upload to firebase database
            FirebaseDB.FBStorage.child(FirebaseDB.ProfileImageNodeKey).child(uid).child(imageName).putData(uploadData, metadata: nil, completion: {(meta, error) in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    completionBlock(false, error!)
                    return
                }
                if let imageDownloadURL = meta?.downloadURL()?.absoluteString {
                    
                    userValuesToSave[RelationshipChatUserKeys.ProfileImageKey] = imageDownloadURL
                    //Get download URL from meta data
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    }
                }
                saveUserWith(uid: uid, valuesToSave: userValuesToSave)
            })
        }
        else {
            saveUserWith(uid: uid, valuesToSave: userValuesToSave)
        }
    }
    
    
}

extension RelationshipChatUser {
    //Convenience var for full name of the user
    var fullName : String {
        return "\(firstName) \(lastName)"
    }
    
    static func makeUserWithValues(userValues : [String : Any], snapshotKey: String) -> RelationshipChatUser {
        let newUser = RelationshipChatUser()
        
        newUser.firstName = userValues[RelationshipChatUserKeys.FirstNameKey] as! String
        newUser.lastName = userValues[RelationshipChatUserKeys.LastNameKey] as! String
        newUser.birthday = Date(timeIntervalSince1970: userValues[RelationshipChatUserKeys.BirthdayKey] as! TimeInterval)
        newUser.gender = userValues[RelationshipChatUserKeys.GenderKey] as! String
        newUser.userUID = snapshotKey
        newUser.tokenID = userValues[RelationshipChatUserKeys.NotificationTokenID] as! String
        
        if let currentRelationshipID = userValues[RelationshipChatUserKeys.RelationshipKey] as? String {
            newUser.relationship = currentRelationshipID
        }
        
        if let imageDownloadURL = userValues[RelationshipChatUserKeys.ProfileImageKey] as? String {
            newUser.profileImageURL = imageDownloadURL
        }
        
        return newUser
    }
    
    //Conveninece func to pull user from DB with a UID value and converts the snapshot into a user object
    static func pullUserFromFB(uid : String, completionHandler : @escaping (RelationshipChatUser?, Error?)->Void) {
        
        let userRef = FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(uid)
        
        userRef.observe(.value, with: { (updatedUser) in
            if let userDict = updatedUser.value as? [String : Any] {
                let updatedUserRecord = RelationshipChatUser.makeUserWithValues(userValues: userDict, snapshotKey: updatedUser.key)
                completionHandler(updatedUserRecord, nil)
            } else {
                completionHandler(nil, nil)
            }
            
        }) { (error) in
            completionHandler(nil, error)
        }
        
    }
    
    
    
}
