//
//  EditProfileViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/12/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import CloudKit

class EditProfileViewController: UITableViewController, UINavigationControllerDelegate {
    
    //MARK : - Constants
    struct Constants {
        static let SavingChangesText = "Saving your changes"
        static let FinishedSavingAlertTitle = "Settings updated"
        static let FinishedSavingAlertBody = "Your profile was successfully updated"
        static let LoadingMessage = "Fetching your profile"
        static let AlertButtonTitle = "Done"
        static let AlertControllerDeleteTitle = "Arey you sure you want to delete your profile?"
        static let AlertControllerDeleteBody = "Deleting your profile will also end your current relationship"
        
        static let AccountDeletedTitle = "Account Deleted"
        static let AccountDeletedBody = "Your account has been successfully deleted"
    }
    
    struct Storyboard {
        static let UnwindBackToProfileSegue = "Profile Change Segue"
    }
    
    //MARK : - Outlets
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    @IBOutlet weak var firstNameLabel: UITextField! {
        didSet {
            firstNameLabel?.delegate = self
        }
    }
    
    @IBOutlet weak var lastNameLabel: UITextField! {
        didSet {
            lastNameLabel?.delegate = self
        }
    }
    
    @IBOutlet weak var deleteProfileButton: UIButton! {
        didSet {
            deleteProfileButton.roundEdges()
            deleteProfileButton.backgroundColor = UIColor.flatPurple()
            deleteProfileButton.clipsToBounds = true
            deleteProfileButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    @IBOutlet fileprivate weak var changeImageButton: UIButton! {
        didSet {
            changeImageButton.roundEdges()
            changeImageButton.titleLabel?.textColor = UIColor.white
        }
    }
    
    @IBOutlet weak var userImageView: UIImageView! {
        didSet {
            userImageView.roundEdges()
            userImageView.clipsToBounds = true
        }
    }
    
    @IBOutlet fileprivate weak var birthdayPicker: UIDatePicker! {
        didSet {
            birthdayPicker.datePickerMode = .date
            birthdayPicker.maximumDate = Date.init()
        }
    }
    @IBOutlet weak var genderPicker: UISegmentedControl!
    
    //MARK : - Model
    
    var mainUserRecord : CKRecord? {
        didSet {
            if mainUserRecord != nil {
                setupUI()
            }
        }
    }
    
    //MARK : - Instance properties
    
    var userGender : String {
        get {
            switch genderPicker.selectedSegmentIndex {
            case 0 :
                return Cloud.Gender.Male
            default :
                return Cloud.Gender.Female
            }
        }
    }
    
    
    fileprivate var usersImage : UIImage? {
        get {
            return userImageView?.image
        } set {
            userImageView?.image = newValue
        }
    }
    
    fileprivate var originalBirthday : Date?
    
    //MARK : - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func setupUI() {
        
        deleteProfileButton?.backgroundColor = UIColor.red
        let usersInfo = Cloud.pullUserInformationFrom(usersRecordToLoad: mainUserRecord!)
        
        firstNameLabel?.text = usersInfo.usersFirstName
        lastNameLabel?.text = usersInfo.usersLastName
        usersImage = usersInfo.usersImage
        birthdayPicker?.setDate(usersInfo.usersBirthday, animated: true)
        originalBirthday = usersInfo.usersBirthday
        
        let gender = usersInfo.usersGender
        switch gender {
        case Cloud.Gender.Male:
            genderPicker?.selectedSegmentIndex = 0
        default:
            genderPicker?.selectedSegmentIndex = 1
        }
    }
    
    
    @IBAction func updateUserInfo(_ sender: Any) {
        firstNameLabel.resignFirstResponder()
        lastNameLabel.resignFirstResponder()
        
        if mainUserRecord != nil  {
            
            mainUserRecord![Cloud.UserAttribute.Gender] = userGender as CKRecordValue?
            mainUserRecord![Cloud.UserAttribute.Birthday] = birthdayPicker.date as CKRecordValue?
            mainUserRecord![Cloud.UserAttribute.FirstName] = firstNameLabel.text as CKRecordValue?
            mainUserRecord![Cloud.UserAttribute.LastName] = lastNameLabel.text as CKRecordValue?
            
            //If user's birthday is different, find activity made by user and make sure it is birthday, then change that date 
            if originalBirthday != birthdayPicker.date {
                //Fetch activity                 
                let recordTypePredicate = NSPredicate(format: "systemActivity = %@", Cloud.RelationshipActivitySystemCreatedTypes.Birthday)
                let creatorPredicate = NSPredicate(format: "creatorUserRecordID = %@", mainUserRecord!.creatorUserRecordID!)
                let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [recordTypePredicate, creatorPredicate])
                
                let query = CKQuery(recordType: Cloud.Entity.RelationshipActivity, predicate: searchPredicate)
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: {  [weak self] (fetchedRecords, error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    
                    guard error == nil else {
                        _ = Cloud.errorHandling(error!, sendingViewController: self)
                        return
                    }
                    
                    guard let birthdayActivty = fetchedRecords?.first else {
                        print("error fetching updaed user record, edit profile ")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        birthdayActivty[Cloud.RelationshipActivityAttribute.CreationDate] = self?.birthdayPicker.date as CKRecordValue?
                    }
                    Cloud.CloudDatabase.PublicDatabase.save(birthdayActivty, completionHandler: { (savedRecord, error) in
                        
                        guard error == nil else {
                            _ = Cloud.errorHandling(error!, sendingViewController: self)
                            return
                        }
                        
                        NotificationCenter.default.post(name: CloudKitNotifications.ActivityUpdateChannel, object: nil, userInfo: [CloudKitNotifications.ActivityUpdateKey : savedRecord!])
                        
                    })
                    
                    
                    
                })
                
                
            }
            
            RCCache.shared[mainUserRecord?.recordID.recordName as AnyObject] = usersImage!
            
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            saveButton.isEnabled = false
            let modifyRecordsOp = CKModifyRecordsOperation(recordsToSave: [mainUserRecord!], recordIDsToDelete: nil)
            modifyRecordsOp.savePolicy = .changedKeys
            
            modifyRecordsOp.modifyRecordsCompletionBlock = { [weak self] (savedRecords, deletedRecords, error) in
                self?.saveButton.isEnabled = true
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if error == nil {
                        self?.displayAlertWithTitle(Constants.FinishedSavingAlertTitle, withBodyMessage: Constants.FinishedSavingAlertBody) { _ in
                            self?.performSegue(withIdentifier: Storyboard.UnwindBackToProfileSegue, sender: self)
                        }
                    } else {
                        _ = Cloud.errorHandling(error!, sendingViewController: nil)
                    }
                }
                
            }
            
            Cloud.CloudDatabase.PublicDatabase.add(modifyRecordsOp)
            
        }
    }
    
    @IBAction func deleteProfile(_ sender: Any) {
        
        firstNameLabel.resignFirstResponder()
        lastNameLabel.resignFirstResponder()
        let alertController = UIAlertController(title: Constants.AlertControllerDeleteTitle, message: Constants.AlertControllerDeleteBody, preferredStyle: .alert)
        deleteProfileButton.isEnabled = false
        saveButton.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (alertAction) in
            
            Cloud.CloudDatabase.PublicDatabase.delete(withRecordID: (self?.mainUserRecord!.recordID)!, completionHandler: { (deletedRecordID, error) in
                
                DispatchQueue.main.async {
                    
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    self?.deleteProfileButton.isEnabled = true
                    self?.saveButton.isEnabled = true
                    self?.navigationItem.leftBarButtonItem?.isEnabled = true
                    
                    
                    if error != nil {
                        _ = _ = Cloud.errorHandling(error!, sendingViewController: nil)
                    } else {
                        
                        if let currentRelationship = self?.mainUserRecord?[Cloud.UserAttribute.Relationship] as? CKReference {
                            Cloud.CloudDatabase.PublicDatabase.delete(withRecordID: currentRelationship.recordID, completionHandler: { (deletedRecordID, error) in
                                if error != nil {
                                    _ = _ = Cloud.errorHandling(error!, sendingViewController: nil)
                                }
                            })
                        }
                        
                        self?.displayAlertWithTitle(Constants.AccountDeletedTitle, withBodyMessage: Constants.AccountDeletedBody) { _ in
                            self?.mainUserRecord = nil
                            NotificationCenter.default.post(name: CloudKitNotifications.CurrentUserRecordUpdateChannel, object: nil, userInfo: nil)
                            self?.performSegue(withIdentifier: Storyboard.UnwindBackToProfileSegue, sender: self)
                        }
                    }
                    
                }
            })
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func changeUserImage(_ sender: UIButton) {
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picturePicker = UIImagePickerController()
            picturePicker.delegate = self
            picturePicker.sourceType = .photoLibrary
            picturePicker.allowsEditing = true
            picturePicker.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPhotoPicking))
            self.present(picturePicker, animated: true, completion: nil)
        }
        
    }
    
    //MARK: - Selector Methods
    @objc
    fileprivate func cancelPhotoPicking() {
        dismiss(animated: true, completion: nil)
    }
    
}



//MARK : - Image Picker controller delegate methods

extension EditProfileViewController : UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let imageInfo = picker.savePickedImageLocally(info)
        mainUserRecord?[Cloud.UserAttribute.ProfileImage] = CKAsset(fileURL: imageInfo.fileURL!) as CKRecordValue?
        usersImage = imageInfo.image
        self.dismiss(animated: true, completion: nil)
        
    }
}

//MARK : - UITextFieldDelegate Methods
extension EditProfileViewController : UITextFieldDelegate  {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text!.isEmpty {
            return false
        } else {
            textField.resignFirstResponder()
            return true
        }
    }
    
    
}
