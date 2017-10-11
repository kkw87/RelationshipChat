//
//  Message.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 8/17/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import JSQMessagesViewController

class Message: NSManagedObject {
    
    struct AttributeNames {
        static let CreatedDate = "created"
        static let MediaData = "media"
        static let Relationship = "relationship"
        static let SenderDisplayName = "senderDisplayName"
        static let SenderID = "senderID"
        static let BodyMessage = "text"
        static let RecordName = "recordName"
    }

}
