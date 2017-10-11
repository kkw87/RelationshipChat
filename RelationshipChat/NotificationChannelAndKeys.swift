//
//  NotificationChannelAndKeys.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 5/10/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import Foundation

struct CloudKitNotifications {
    
    static let RelationshipRequestChannel = NSNotification.Name(rawValue: "RelationshipRequestChannel")
    static let RelationshipRequestKey = "RelationshipRequestKey"
    
    static let RelationshipRequestResponseChannel = NSNotification.Name(rawValue: "RelationshipRequestResponseChannel")
    static let RelationshipRequestResponseKey = "RelationshipRequestResponseKey"
    
    static let TypingIndicatorChannel = NSNotification.Name(rawValue: "TypingIndicatorChannel")
    static let TypingChannelKey = NSNotification.Name(rawValue : "TypingIndicatorKey")
    
    static let MessageChannel = NSNotification.Name(rawValue: "MessageChannel")
    static let MessagKey = NSNotification.Name(rawValue: "MessageKey")
    
    
    static let CurrentUserRecordUpdateChannel = NSNotification.Name(rawValue: "CurrentUserChannel")
    static let CurrentUserRecordUpdateKey = "CurrentUserKey"
    
    
    static let RelationshipUpdateChannel = NSNotification.Name(rawValue: "RUChannel")
    static let RelationshipUpdateKey = "RUKey"
    
    
    static let SecondaryUserUpdateChannel = NSNotification.Name(rawValue: "SUChannel")
    static let SecondaryUserUpdateKey = "SUKey"
    
    static let ActivityUpdateChannel = NSNotification.Name(rawValue: "ActivityChannel")
    static let ActivityUpdateKey = "ActivityKey"
    
    static let ActivityDeletedChannel = NSNotification.Name(rawValue: "ActivityDeletedChannel")
    static let ActivityDeletedKey = "ActivityDeletedKey"
    
    static let UserLocationUpdateChannel = NSNotification.Name(rawValue: "UsersLocationAdded")
    static let UserLocationUpdateKey = "UsersLocationUpdateKey"
    
    static let LocationDeletedUpdateChannel = NSNotification.Name("LocationDeletedChannel")
    static let LocationDeletedKey = "LocationDeletedKey"
}
