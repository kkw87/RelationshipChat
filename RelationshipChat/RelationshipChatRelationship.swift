//
//  RelationshipChatRelationship.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 12/14/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import Foundation

struct RelationshipStatus {
    static let Pending = "Pending"
    static let Single = "Single"
    static let Dating = "Dating"
    static let Married = "Married "
}

struct RelationshipKeys {
    static let StartDate = "startDate"
    static let Status = "status"
    static let Members = "relationshipMembers"
    static let AnniversaryRecordID = "anniversary_activity_id"
}

class RelationshipChatRelationship : NSObject {
    var status = RelationshipStatus.Pending
    var startDate = Date()
    var relationshipMembers = [String]()
    var relationshipUID = String()
    
    static func deleteRelationship(relationshipUID : String, completionHandler : @escaping (Error?)->Void) {
        
        func deleteDataAssociatedWithRelationship() {
            FirebaseDB.MainDatabase.child(FirebaseDB.ActivityByRelationshipFanOutKey).child(relationshipUID).observe(.childAdded, with: { (snapshot) in
                                
                FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipActivityNodeKey).child(snapshot.key).removeValue()
            })
            
            FirebaseDB.MainDatabase.child(FirebaseDB.ActivityByRelationshipFanOutKey).child(relationshipUID).removeValue()
            
            FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipRelationshipNodeKey).child(relationshipUID).removeValue { (error, _) in
                
                guard error == nil else {
                    completionHandler(error)
                    
                    return
                }
                
                completionHandler(nil)
                
            }
        }
        
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipRelationshipNodeKey).child(relationshipUID).observeSingleEvent(of: .value) { (snapshot) in
            let relationshipData = snapshot.value as! [String : Any]
            
            if let usersToDelete = relationshipData[RelationshipKeys.Members] as? [String] {
                for userID in usersToDelete {
                    FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(userID).child(RelationshipChatUserKeys.RelationshipKey).removeValue()
                }
                
            }
            
            deleteDataAssociatedWithRelationship()

        }
    }
    
    static func fetchRelationship(withUID relationshipUID : String, completionHandler : @escaping (RelationshipChatRelationship?, Error?)->Void) {
        
        let relationshipRef = FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipRelationshipNodeKey).child(relationshipUID)
        
        relationshipRef.observe(.value, with: { (relationshipSnapshot) in
            
            if let valueDictionary = relationshipSnapshot.value as? [String : Any] {
                
                let newRelationship = RelationshipChatRelationship()
                
                if let newStatus = valueDictionary[RelationshipKeys.Status] as? String {
                    newRelationship.status = newStatus
                    
                }
                
                if let newStartDate = valueDictionary[RelationshipKeys.StartDate] as? TimeInterval {
                    newRelationship.startDate = Date(timeIntervalSince1970: newStartDate)
                    
                }
                
                if let newMembers = valueDictionary[RelationshipKeys.Members] as? [String] {
                    newRelationship.relationshipMembers = newMembers
                }
                
                newRelationship.relationshipUID = relationshipSnapshot.key
                
                completionHandler(newRelationship, nil)
            } else {
                completionHandler(nil, nil)
            }
            
            
            
        }) { (error) in
            completionHandler(nil, error)
        }
        
        
        
    }
    
    func updateCurrentRelationship(completionHandler : @escaping (Error?)->Void) {
        let values = [RelationshipKeys.Members : relationshipMembers, RelationshipKeys.StartDate : startDate.timeIntervalSince1970, RelationshipKeys.Status : status] as! [String : Any]
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipRelationshipNodeKey).child(relationshipUID).updateChildValues(values) { (error, _) in
            guard error == nil else {
                completionHandler(error)
                return
            }
            
            completionHandler(nil)
        }
    }
    
    func saveNewRelationship(completionHandler : @escaping (Error?)->Void) {
        let values = [RelationshipKeys.Members : relationshipMembers, RelationshipKeys.StartDate : startDate.timeIntervalSince1970, RelationshipKeys.Status : status] as! [String : Any]
        
        
        //TODO, need to implemen the auto id
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipRelationshipNodeKey).childByAutoId().updateChildValues(values) { [weak self](error, ref) in
            
            self?.relationshipUID = ref.key
            
            completionHandler(error)
            
        }
    }
    
}
