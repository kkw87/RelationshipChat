//
//  RelationshipChatLocation.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 12/14/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase

struct LocationKeys {
    static let CreatingUserName = "creating_user"
    static let LocationLongitude = "location_longitude"
    static let LocationLatitude = "location_latitude"
    static let LocationName = "location_name"
    static let LocationAddressName = "location_address"
    static let RelationshipID = "relationshipID"
    static let CreationDate = "date"
}

struct RelationshipChatLocation  {
    let creatingUserName : String
    let location : CLLocationCoordinate2D
    let locationName : String
    let locationAddressName : String
    let relationship : String
    let creationDate : Date
    var uid : String
    
    private func returnValuesAsDictionary() -> [String : Any] {
        
        var locationValuesAsDictionary = [LocationKeys.CreatingUserName : creatingUserName, LocationKeys.LocationLongitude : location.longitude, LocationKeys.LocationLatitude : location.latitude, LocationKeys.LocationName : locationName, LocationKeys.LocationAddressName : locationAddressName, LocationKeys.RelationshipID : relationship, LocationKeys.CreationDate : creationDate.timeIntervalSince1970] as [String : Any]
        
        return locationValuesAsDictionary
    }
    
    static func fetchLocation(withUID : String, completionHandler : @escaping (RelationshipChatLocation?)->Void) {
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipLocationNodeKey).child(withUID).observe(.value, with: { (snapshot) in
            if let locationValueDictionary = snapshot.value as? [String : Any] {
                
                guard let userName = locationValueDictionary[LocationKeys.CreatingUserName] as? String, let locationLongitude = locationValueDictionary[LocationKeys.LocationLongitude] as? CLLocationDegrees, let locationLatitude = locationValueDictionary[LocationKeys.LocationLatitude] as? CLLocationDegrees, let locationTitle = locationValueDictionary[LocationKeys.LocationName] as? String, let addressTitle = locationValueDictionary[LocationKeys.LocationAddressName] as? String, let relationshipID = locationValueDictionary[LocationKeys.RelationshipID] as? String, let locationDate = locationValueDictionary[LocationKeys.CreationDate] as? TimeInterval else {
                    
                    completionHandler(nil)
                    
                    return
                }
                
                let newLocation = RelationshipChatLocation(creatingUserName: userName, location: CLLocationCoordinate2DMake(locationLatitude, locationLongitude), locationName: locationTitle, locationAddressName: addressTitle, relationship: relationshipID, creationDate: Date(timeIntervalSince1970: locationDate), uid: snapshot.key)
                completionHandler(newLocation)
                
            }
        }, withCancel: nil)
        
    }
    
    static func deleteLocationFromDB(withUID : String, completionHandler : @escaping (Error?)->Void) {
        
        //
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipLocationNodeKey).child(withUID).observeSingleEvent(of: .value) { (snapshot) in
            
            let relationshipID = (snapshot.value as! [String : Any])[LocationKeys.RelationshipID] as! String
           
            FirebaseDB.MainDatabase.child(FirebaseDB.LocationsByRelationshipFanOutKey).child(relationshipID).child(withUID).removeValue(completionBlock: { (error, _) in
                guard error == nil else {
                    completionHandler(error)
                    return
                }
                
                
                FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipLocationNodeKey).child(withUID).removeValue(completionBlock: { (error, _) in
                    guard error == nil else {
                        completionHandler(error!)
                        return
                    }
                    
                    completionHandler(nil)
                })
                
                
                
            })
        }
        
        //TODO, implement delete location 
    }
    
    func saveLocationToDB(completionHandler : @escaping (Error?, String?)->Void) {
        
        let valuesToSave = returnValuesAsDictionary()
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipLocationNodeKey).childByAutoId().updateChildValues(valuesToSave) { (error, savedRef) in
            guard error == nil else {
                completionHandler(error!, nil)
                return
            }
            
            FirebaseDB.MainDatabase.child(FirebaseDB.LocationsByRelationshipFanOutKey).child(self.relationship).updateChildValues([savedRef.key : Auth.auth().currentUser!.uid], withCompletionBlock: { (error, ref) in
                
                guard error == nil else {
                    completionHandler(error!, nil)
                    return
                }
                
                completionHandler(nil, savedRef.key)
                
            })
        }
        
    }
}
