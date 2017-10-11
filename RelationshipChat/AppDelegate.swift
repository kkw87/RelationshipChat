//
//  AppDelegate.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 8/24/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import UserNotifications
import ChameleonFramework
import CloudKit
import CoreData

@available(iOS 10.0, *)
@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UITabBar.appearance().tintColor = UIColor.flatPurple()
        UISegmentedControl.appearance().tintColor = UIColor.flatPurple()
        
        //Notification Setup
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        let ckquery = CKQueryNotification(fromRemoteNotificationDictionary: userInfo)


        
        if let typeOfRecord = ckquery.recordFields?[Cloud.RecordKeys.RecordType] as? String {
            switch typeOfRecord {
                
            case Cloud.Entity.RelationshipRequestResponse:
                NotificationCenter.default.post(name: CloudKitNotifications.RelationshipRequestChannel, object: nil, userInfo: [CloudKitNotifications.RelationshipRequestKey : ckquery])
                
            case Cloud.Entity.RelationshipRequest:
                NotificationCenter.default.post(name: CloudKitNotifications.RelationshipRequestChannel, object: nil, userInfo: [CloudKitNotifications.RelationshipRequestKey : ckquery])
                
            case Cloud.Entity.RelationshipRequestResponse:
                NotificationCenter.default.post(name: CloudKitNotifications.RelationshipRequestResponseChannel, object: nil, userInfo: [CloudKitNotifications.RelationshipRequestResponseKey : ckquery])
                
            case Cloud.Entity.UserTypingIndicator:
                NotificationCenter.default.post(name: CloudKitNotifications.TypingIndicatorChannel, object: nil, userInfo: [CloudKitNotifications.TypingChannelKey : ckquery])
                
            case Cloud.Entity.User:
                    NotificationCenter.default.post(name: CloudKitNotifications.SecondaryUserUpdateChannel, object: nil, userInfo: [CloudKitNotifications.SecondaryUserUpdateKey : ckquery])
  
            case Cloud.Entity.Relationship:
                
                if ckquery.queryNotificationReason == .recordDeleted {
                    
                    NotificationCenter.default.post(name: CloudKitNotifications.RelationshipUpdateChannel, object: nil, userInfo: nil)
                }else {
                
                    NotificationCenter.default.post(name: CloudKitNotifications.RelationshipUpdateChannel, object: nil, userInfo: [CloudKitNotifications.RelationshipUpdateKey : ckquery])
                }
                
            case Cloud.Entity.Message:
                NotificationCenter.default.post(name: CloudKitNotifications.MessageChannel, object: nil, userInfo: [CloudKitNotifications.MessagKey : ckquery])
            case Cloud.Entity.RelationshipActivity:
                
                if ckquery.queryNotificationReason == .recordDeleted {
                    NotificationCenter.default.post(name: CloudKitNotifications.ActivityDeletedChannel, object: nil, userInfo: [CloudKitNotifications.ActivityDeletedKey : ckquery])
                } else {
                
                NotificationCenter.default.post(name: CloudKitNotifications.ActivityUpdateChannel, object: nil, userInfo: [CloudKitNotifications.ActivityUpdateKey : ckquery])
                }
                
            default:
                break
            }
        }
        
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "CoreDataMessageModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

