//
//  RelationshipChatActivity .swift
//  RelationshipChat
//
//  Created by Kevin Wang on 12/14/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation

struct SystemActivity {
    static let Birthday = "birthday"
    static let Anniversary = "anniversary"
    
    static let AnniversaryActivityTitle = "Your Anniversary"
    static let AnniversaryActivityDescription = "It all started on this day!"
    
    static let BirthdayActivityTrailingTitle = "'s Birthday!"
    static let BirthdayActivityTrailingBody = "'s special day!"
}

struct ActivityKeys {
    static let ActivityTitle = "title"
    static let ActivityDescription = "description"
    static let ActivityDate = "date"
    static let RelationshipID = "relationshipUID"
    static let SystemActivity = "system_activity"
    static let LocationName = "location_name"
    static let LocationAddressName = "location_address_name"
    static let LocationLongitude = "location_longitude"
    static let LocationLatitude = "location_latitude"
}

class RelationshipChatActivity {
    var title = String()
    var creationDate = Date()
    var description = String()
    var relationship = String()
    var systemActivity : String?
    var location : CLLocationCoordinate2D?
    var locationStringName : String?
    var locationStringAddress : String?
    var activityUID = String()
    var daysUntil : Int {
        get {
            
            let calendar = NSCalendar.current
            let currentDate = calendar.startOfDay(for: Date())
            let currentYear = calendar.component(.year, from: currentDate)
            
            var activityDateComponents = calendar.dateComponents([.year, .month, .day], from: creationDate)
            activityDateComponents.year = currentYear
            
            if systemActivity != nil {
                var systemMadeActivityDate = calendar.date(from: activityDateComponents)!
                
                let dateComparison = calendar.compare(systemMadeActivityDate, to: currentDate, toGranularity: .day)
                
                if dateComparison == .orderedAscending {
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: systemMadeActivityDate)
                    dateComponents.year = currentYear + 1
                    systemMadeActivityDate = calendar.date(from: dateComponents)!
                }
                
                let dayDifference = calendar.dateComponents([.day], from: currentDate, to: systemMadeActivityDate).day!
                                return dayDifference
            } else {
                let activityDate = calendar.date(from: activityDateComponents)!
                
                let days = calendar.dateComponents([.day], from: currentDate, to: activityDate).day!
                return days
            }
        }
    }
    
    static func deleteActivity(activityID : String, completionHandler : @escaping (Error?)->Void) {
        
        //Get the relationID that the activity is associated with
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipActivityNodeKey).child(activityID).observeSingleEvent(of: .value) { (snapshot) in
            
            let relationshipID = (snapshot.value as! [String : Any])[ActivityKeys.RelationshipID] as! String
            
            FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipActivityNodeKey).child(activityID).removeValue { (error, _) in
                guard error == nil else {
                    completionHandler(error!)
                    return
                }
                
                //Delete activity references located inside the fan out
                FirebaseDB.MainDatabase.child(FirebaseDB.ActivityByRelationshipFanOutKey).child(relationshipID).child(activityID) .removeValue(completionBlock: { (error, _) in
                    
                    guard error == nil else {
                        completionHandler(error!)
                        return
                    }
                    
                    completionHandler(nil)
                    
                })
                
            }
            
            
        }
    }
    
    private func returnValuesAsDictionary() -> [String : Any] {
        
        var valuesToUpdate = [ActivityKeys.ActivityTitle : title, ActivityKeys.ActivityDescription : description, ActivityKeys.ActivityDate : creationDate.timeIntervalSince1970, ActivityKeys.RelationshipID : relationship] as [String : Any]
        
        if systemActivity != nil {
            valuesToUpdate[ActivityKeys.SystemActivity] = systemActivity
        } else if location != nil, locationStringAddress != nil, locationStringName != nil {
            valuesToUpdate[ActivityKeys.LocationName] = locationStringName!
            valuesToUpdate[ActivityKeys.LocationAddressName] = locationStringAddress!
            
            valuesToUpdate[ActivityKeys.LocationLatitude] = location!.latitude
            valuesToUpdate[ActivityKeys.LocationLongitude] = location!.longitude
        }
        
        return valuesToUpdate
        
    }
    
    static func fetchActivity(withUID activityID : String, completionHandler : @escaping (RelationshipChatActivity?)->Void) {
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipActivityNodeKey).child(activityID).observe(.value) { (snapshot) in
            
            if let values = snapshot.value as? [String : Any] {
            let activityToReturn = RelationshipChatActivity()
            
            guard let activityName = values[ActivityKeys.ActivityTitle] as? String, let activityDescription = values[ActivityKeys.ActivityDescription] as? String, let activityDate = values[ActivityKeys.ActivityDate] as? TimeInterval, let relationshipUID = values[ActivityKeys.RelationshipID] as? String else {
                completionHandler(nil)
                return
            }
            
            activityToReturn.title = activityName
            activityToReturn.description = activityDescription
            activityToReturn.creationDate = Date(timeIntervalSince1970: activityDate)
            activityToReturn.relationship = relationshipUID
            activityToReturn.activityUID = snapshot.key
            
            if let systemActivityType = values[ActivityKeys.SystemActivity] as? String {
                activityToReturn.systemActivity = systemActivityType
            }
            
            if let locationTitle = values[ActivityKeys.LocationName] as? String, let locationAddressName = values[ActivityKeys.LocationAddressName] as? String, let locationLatitude = values[ActivityKeys.LocationLatitude] as? CLLocationDegrees, let locationLongitude = values[ActivityKeys.LocationLongitude] as? CLLocationDegrees  {
                
                activityToReturn.locationStringName = locationTitle
                activityToReturn.locationStringAddress = locationAddressName
                activityToReturn.location = CLLocationCoordinate2D(latitude: locationLatitude, longitude: locationLongitude)
                
            }
            
            completionHandler(activityToReturn)
            } else {
                completionHandler(nil)
            }
            
        }
    }
    
    func updateCurrentActivity(completionHandler : @escaping (Error?)->Void) {
        
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipActivityNodeKey).child(activityUID).updateChildValues(returnValuesAsDictionary()) { (error, _) in
            
            completionHandler(error)
            
        }

    }
    
    func saveActivity(completionHandler : @escaping (Error?, String?)->Void) {
        
        let valuesToSave = returnValuesAsDictionary()
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipActivityNodeKey).childByAutoId().updateChildValues(valuesToSave) { (error, savedRef) in
            
            guard error == nil else {
                completionHandler(error, nil)
                return
            }
                        FirebaseDB.MainDatabase.child(FirebaseDB.ActivityByRelationshipFanOutKey).child(self.relationship).updateChildValues([savedRef.key : Auth.auth().currentUser!.uid], withCompletionBlock: { (error, _) in
                completionHandler(nil, savedRef.key)
            })
            
            

            
        }
        
        
    }
    
}

