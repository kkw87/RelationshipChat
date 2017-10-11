//
//  Cache.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 10/22/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit

final class RCCache: NSCache<AnyObject, UIImage> {
    
    static let shared = RCCache()
    
    //Observer to purge cache upon memory pressure
    fileprivate var memoryWarningObserver: NSObjectProtocol!
    
    
    fileprivate override init() {
        super.init()
        memoryWarningObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil, queue: nil, using: { (notification) in
            self.removeAllObjects()
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(memoryWarningObserver)
    }
    
    //Retrieving and storing data
    //Subscript operation to retrieve and update
    subscript(key: AnyObject) -> UIImage? {
        get {
            return object(forKey: key)
        } set {
            if let object = newValue {
                setObject(object, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
    
}
