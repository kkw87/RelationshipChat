//
//  NewRelationshipViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 10/14/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
//import Contacts
import CloudKit

protocol RelationshipCellDelegate : class {
    func displayAlertWithTitle(_ titleMessage : String, withBodyMessage : String, completion: ((UIAlertAction)->Void)? )
    func presentViewController(_ viewControllerToPresent : UIViewController)
    func popBackToRoot()
}

@available(iOS 10.0, *)
class NewRelationshipViewController: UITableViewController {
    
    // MARK: - Constants
    struct Constants {
        static let NoUsersAlertTitle = "Unable to find any users"
        static let NoUsersAlertMessage = "We were unable to find any users in your contacts with the app installed."
    }
    
    struct Storyboard {
        static let cellID = "Relationship Cell"
    }
    // MARK: - Instance variables
    
    fileprivate var contactsWithApp = [CKRecord]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    fileprivate var cloudUsersID = [CKRecordID]()
    
    fileprivate let store = CNContactStore()
    
    var userRecord : CKRecord? {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadContacts()
        hideEmptyCells()
    }
    // MARK: - Class Methods
    
    
    @IBAction func cancel(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func loadContacts() {
        
        CKContainer.default().requestApplicationPermission(.userDiscoverability) { (status, error) in
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: self)
                return
            }
            
            switch status {
            case .denied:
                let deniedAlert = UIAlertController(title: "Unable to discover users", message: "Access to contacts was denied", preferredStyle: .alert)
                deniedAlert.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
                
                DispatchQueue.main.async {
                    self.present(deniedAlert, animated: true, completion: nil)
                }
            case .granted:
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                let cloudDiscover = CKDiscoverAllUserIdentitiesOperation()
                cloudDiscover.queuePriority = .high
                
                cloudDiscover.discoverAllUserIdentitiesCompletionBlock = { [weak self] error -> Void in
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                    }
                    
                    guard error == nil else{
                        print(error!)
                        _ = Cloud.errorHandling(error!, sendingViewController: self)
                        return
                    }
                    
                    
                    
                    guard (self?.cloudUsersID.count)! > 0 else {
                        DispatchQueue.main.async {
                            self?.displayAlertWithTitle(Constants.NoUsersAlertTitle, withBodyMessage: Constants.NoUsersAlertMessage, withBlock: nil)
                        }
                        return
                    }
                    
                    for recordID in (self?.cloudUsersID)! {
                        
                        let predicate = NSPredicate(format: "creatorUserRecordID = %@", recordID)
                        let query = CKQuery(recordType: Cloud.Entity.User, predicate: predicate)
                        
                        DispatchQueue.main.async {
                            UIApplication.shared.isNetworkActivityIndicatorVisible = true
                        }
                        Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: { (fetchedAccounts, error) in
                            DispatchQueue.main.async {
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            }
                            
                            guard error == nil else {
                                _ = Cloud.errorHandling(error!, sendingViewController: self)
                                return
                            }
                            
                            guard let userWithAccount = fetchedAccounts?.first, userWithAccount.recordID != self?.userRecord?.recordID else {
                                return
                            }
                            
                            DispatchQueue.main.async {
                                self?.contactsWithApp.append(userWithAccount)
                                self?.tableView.reloadData()
                            }
                        })
                    }
                }
                
                cloudDiscover.userIdentityDiscoveredBlock = { [weak weakSelf = self] user -> Void in
                    if user.hasiCloudAccount {
                        if user.userRecordID != weakSelf?.userRecord?.creatorUserRecordID {
                            weakSelf?.cloudUsersID.append(user.userRecordID!)
                        }
                    }
                }
                CKContainer.default().add(cloudDiscover)
                
            default : break
            }
            
        }
        
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return contactsWithApp.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.cellID, for: indexPath) as! RelationshipTableViewCell
        
        cell.userRecord = userRecord
        
        cell.clickedUsersRecord = contactsWithApp[indexPath.row]
        cell.delegate = self
        
        return cell
    }
}

//MARK : - Relationship Cell Delegate
@available(iOS 10.0, *)
extension NewRelationshipViewController : RelationshipCellDelegate {
    func displayAlertWithTitle(_ titleMessage: String, withBodyMessage: String, completion : ((UIAlertAction)->Void)?) {
        displayAlertWithTitle(titleMessage, withBodyMessage: withBodyMessage, withBlock: completion)
    }
    
    func presentViewController(_ viewControllerToPresent: UIViewController) {
        present(viewControllerToPresent, animated: true, completion: nil)
    }
    
    func popBackToRoot() {
        self.navigationController?.popToRootViewController(animated: true)
    }
}
