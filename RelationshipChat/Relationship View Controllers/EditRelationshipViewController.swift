//
//  EditRelationshipViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 3/9/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import CloudKit

class EditRelationshipViewController: UITableViewController {
    
    // MARK : - Constants
    struct Constants {
        static let SaveMessage = "Saving relationship changes"
        static let DeleteMessage = "Deleting relationship"
        static let SaveSuccessTitle = "Relationship updated!"
        static let SaveSuccessBody = "You have saved the changes in your relationship"
        static let DeleteSuccessTitle = "Relationship Ended"
        static let DeleteSuccessBody = "You are no longer in a relationship"
        static let DeleteConfirmationTitle = "Are you sure you wish to end your relationship?"
        static let DeleteConfirmationBody = "You are attempting to end your current relationship"
        static let EndRelationshipButtonTitle = "End it"
        static let EndRelationshipCancelButtonTitle = "Cancel"
        
        static let NoRelationshipChangesAlertTitle = "No changes were made"
        static let NoRelationshipChangesAlertBody = "Your relationship has its original values"
    }
    
    struct Storyboard {
        static let EditRelationshipUnwindSegue = "Edit Relationship Unwind"
    }
    
    //MARK : - Instance Properties
    var relationship : CKRecord?
    
    fileprivate var relationshipStatus : String {
        get {
            return statusArray[statusPicker.selectedRow(inComponent: 0)]
        }
    }
    fileprivate var originalRelationshipDate : Date?
    fileprivate var originalRelationshipStatus : String?
    
    fileprivate let statusArray = [Cloud.RelationshipStatus.Dating, Cloud.RelationshipStatus.Married, Cloud.RelationshipStatus.Complicated]
    
    fileprivate let loadingView = ActivityView(withMessage: "")
    
    //MARK : - Outlets
    @IBOutlet weak var statusPicker: UIPickerView! {
        didSet {
            statusPicker.delegate = self
            statusPicker.dataSource = self
        }
    }
    
    @IBOutlet weak var relationshipStartDatePicker: UIDatePicker! {
        didSet {
            relationshipStartDatePicker.datePickerMode = .date
            relationshipStartDatePicker.maximumDate = Date()
        }
    }
    
    
    @IBOutlet weak var endButton: UIButton! {
        didSet {
            endButton.roundEdges()
            endButton.clipsToBounds = true
            endButton.backgroundColor = UIColor.flatPurple()
            endButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    // MARK : - Methods
    @IBAction func saveUpdates(_ sender: Any) {

        if originalRelationshipDate == relationshipStartDatePicker.date && originalRelationshipStatus == statusArray[statusPicker.selectedRow(inComponent: 0)] {
            
            let noChangesMadeAlertController = UIAlertController(title: Constants.NoRelationshipChangesAlertTitle, message: Constants.NoRelationshipChangesAlertBody, preferredStyle: .alert)
            noChangesMadeAlertController.addAction(UIAlertAction(title: Constants.EndRelationshipCancelButtonTitle, style: .cancel, handler: nil))
            present(noChangesMadeAlertController, animated: true, completion: nil)
            return
        }
        
        relationship![Cloud.RelationshipAttribute.Status] = relationshipStatus as CKRecordValue?
        relationship![Cloud.RelationshipAttribute.StartDate] = relationshipStartDatePicker.date as CKRecordValue?
        
        
        saveButton.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        view.addSubview(loadingView)
        loadingView.updateMessageWith(message: Constants.SaveMessage)
        loadingView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        Cloud.CloudDatabase.PublicDatabase.save(relationship!) { [weak self] (savedRelationship, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.saveButton.isEnabled = true
                self?.loadingView.removeFromSuperview()
            }
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: self)
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                if self?.originalRelationshipDate != self?.relationshipStartDatePicker.date {
                    self?.updateAnniversaryRecord()
                }
            }
            
            
            NotificationCenter.default.post(name: CloudKitNotifications.RelationshipUpdateChannel, object: nil, userInfo: [CloudKitNotifications.RelationshipUpdateKey : (self?.relationship)!])
            
            DispatchQueue.main.async {
                self?.displayAlertWithTitle(Constants.SaveSuccessTitle, withBodyMessage: Constants.SaveSuccessBody, withBlock: { (alert) in
                    
                    self?.performSegue(withIdentifier: Storyboard.EditRelationshipUnwindSegue, sender: self)
                    
                })
            }
            
        }
        
    }
    
    @IBAction func endRelationship(_ sender: Any) {

        let confirmationVC = UIAlertController(title: Constants.DeleteConfirmationTitle, message: Constants.DeleteConfirmationBody, preferredStyle: .alert)
        
        let cancelRelationship = UIAlertAction(title: Constants.EndRelationshipButtonTitle, style: .destructive) { [weak self] (alertAction) in
            
            self!.loadingView.updateMessageWith(message: Constants.DeleteMessage)
            self!.view.addSubview(self!.loadingView)
            self!.loadingView.center = CGPoint(x: self!.view.bounds.midX, y: self!.view.bounds.midY)

            UIApplication.shared.isNetworkActivityIndicatorVisible = true

            Cloud.CloudDatabase.PublicDatabase.delete(withRecordID: (self?.relationship!.recordID)!) { (deletedRelationship, error) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.loadingView.removeFromSuperview()
                }
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    return
                }
                
                self?.relationship = nil

                DispatchQueue.main.async {
                    self?.displayAlertWithTitle(Constants.DeleteSuccessTitle, withBodyMessage: Constants.DeleteSuccessBody, withBlock: { (action) in
                        NotificationCenter.default.post(name: CloudKitNotifications.RelationshipUpdateChannel, object: nil, userInfo: nil)
                        self?.performSegue(withIdentifier: Storyboard.EditRelationshipUnwindSegue, sender: self)
                    })
                }
                
                
            }
        }
        
        confirmationVC.addAction(cancelRelationship)
        confirmationVC.addAction(UIAlertAction(title: Constants.EndRelationshipCancelButtonTitle, style: .cancel, handler: nil))
        present(confirmationVC, animated: true, completion: nil)
        
    }
    
    
    // MARK : - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        endButton.backgroundColor = UIColor.red
        setupUI()
    }
    
    // MARK: - Class Methods
    fileprivate func setupUI() {
        
        guard relationship != nil else {
            return
        }

        let relationshipStartDate = relationship![Cloud.RelationshipAttribute.StartDate] as! Date
        originalRelationshipDate = relationshipStartDate
        
        let relationshipStatus = relationship![Cloud.RelationshipAttribute.Status] as! String
        originalRelationshipStatus = relationshipStatus
        
        relationshipStartDatePicker.setDate(relationshipStartDate, animated: true)
        statusPicker.selectRow(statusArray.index(of: relationshipStatus)!, inComponent: 0, animated: true)
    }
    
    fileprivate func updateAnniversaryRecord() {
        
        let recordTypePredicate = NSPredicate(format: "systemActivity = %@", Cloud.RelationshipActivitySystemCreatedTypes.Anniversary)
        let relationshipPredicate = NSPredicate(format: "relationship = %@", relationship!)
        
        let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [recordTypePredicate, relationshipPredicate])
        
        let query = CKQuery(recordType: Cloud.Entity.RelationshipActivity, predicate: searchPredicate)
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: { [weak self] (fetchedRecords, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard error == nil else {
                print(error!)
                _ = Cloud.errorHandling(error!, sendingViewController: self)
                return
            }
            
            guard let anniversaryRecord = fetchedRecords?.first else {
                print("Unable to find anniversary record ")
                return
            }

            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                anniversaryRecord[Cloud.RelationshipActivityAttribute.CreationDate] = self?.relationshipStartDatePicker.date as CKRecordValue?
            }
            
            Cloud.CloudDatabase.PublicDatabase.save(anniversaryRecord, completionHandler: { (savedRecord, error) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    print(error!)
                    return
                }
                NotificationCenter.default.post(name: CloudKitNotifications.ActivityUpdateChannel, object: nil, userInfo: [CloudKitNotifications.ActivityUpdateKey : savedRecord!])
                
            })
        })
        
    }
    
}



// MARK: - PickerView Delegation
extension EditRelationshipViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return statusArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return statusArray[row]
    }
}
