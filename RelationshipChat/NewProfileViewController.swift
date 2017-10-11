//
//  NewProfileViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/20/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import CloudKit

class NewProfileViewController: UITableViewController, UINavigationControllerDelegate {
    
    //MARK: - Constants
    struct Constants {
        static let LabelCornerRadius = 5
        static let DefaultErrorText = " "
        static let DefaultAlphaColorValue : CGFloat = 0.2
        static let FirstNameErrorText = "You need to enter your first name. "
        static let LastNameErrorText = "You need to enter your last name."
        static let GenderErrorText = "You need to enter your gender."
        static let AlertViewCreationText = "Creating your account..."
        static let AlertViewErrorText = "We were unable to make your account..."
        static let ErrorAlertTitleText = "Oops!"
    }
    
    //MARK: - Outlets
    
    
    @IBOutlet fileprivate weak var pictureButton: UIButton! {
        didSet {
            pictureButton.backgroundColor = UIColor.flatPurple()
            pictureButton.clipsToBounds = true
            pictureButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    @IBOutlet weak var userImageView: UIImageView! {
        didSet {
            userImageView.roundEdges()
            userImageView.clipsToBounds = true
            userImageView.contentMode = .scaleAspectFill
        }
    }
    
    @IBOutlet fileprivate weak var firstNameTextField: UITextField! {
        didSet {
            firstNameTextField.delegate = self
        }
    }
    @IBOutlet fileprivate weak var lastNameTextField: UITextField! {
        didSet {
            lastNameTextField.delegate = self
        }
    }
    
    @IBOutlet weak var genderPicker: UISegmentedControl!
    @IBOutlet weak var birthdayPicker: UIDatePicker! {
        didSet {
            birthdayPicker.datePickerMode = .date
            birthdayPicker.maximumDate = Date.init()
        }
    }
    
    //MARK: - Instance Variables
    fileprivate var userImage : UIImage? {
        get {
            return userImageView.image
        } set {
            userImageView.image = newValue
        }
    }
    
    fileprivate var imageURL : URL?
    
    fileprivate var selectedGender : String {
        get {
            switch genderPicker.selectedSegmentIndex {
            case 0:
                return Cloud.Gender.Male
            default:
                return Cloud.Gender.Female
            }
        }
    }
    
    fileprivate var errorText : String? {
        didSet {
            if errorText != nil {
                let errorAlert = UIAlertController(title: Constants.ErrorAlertTitleText, message: errorText!, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: nil))
                present(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate var loadingView = ActivityView(withMessage: "")
    
    //MARK: - VC Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pictureButton.backgroundColor = UIColor.clear
        
    }
    
    //MARK: - Class Methods
    @IBAction fileprivate func pickProfilePicture(_ sender: UIButton) {
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            
            let picturePicker = UIImagePickerController()
            picturePicker.delegate = self
            picturePicker.sourceType = .photoLibrary
            picturePicker.allowsEditing = true
            self.present(picturePicker, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 10.0, *)
    @IBAction fileprivate func createNewProfile(_ sender: AnyObject) {
        
        firstNameTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        
        guard firstNameTextField.hasText else {
            firstNameTextField.backgroundColor = UIColor.red.withAlphaComponent(Constants.DefaultAlphaColorValue)
            errorText = Constants.FirstNameErrorText
            return
        }
        
        guard lastNameTextField.hasText else {
            lastNameTextField.backgroundColor = UIColor.red.withAlphaComponent(Constants.DefaultAlphaColorValue)
            errorText = Constants.LastNameErrorText
            return
        }
        
        let currentUser = CKRecord(recordType : Cloud.Entity.User)
        currentUser[Cloud.UserAttribute.FirstName] = firstNameTextField.text! as CKRecordValue?
        currentUser[Cloud.UserAttribute.LastName] = lastNameTextField.text! as CKRecordValue?
        currentUser[Cloud.UserAttribute.Birthday] = birthdayPicker.date as CKRecordValue?
        currentUser[Cloud.UserAttribute.Gender] = selectedGender as CKRecordValue?
        currentUser[Cloud.RecordKeys.RecordType] = Cloud.Entity.User as CKRecordValue?
        
        if imageURL != nil {
            currentUser[Cloud.UserAttribute.ProfileImage] = CKAsset(fileURL: imageURL!)
            RCCache.shared[currentUser.recordID.recordName as AnyObject] = self.userImage
        }
        
        view.addSubview(loadingView)
        loadingView.updateMessageWith(message: Constants.AlertViewCreationText)
        loadingView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        
        Cloud.CloudDatabase.PublicDatabase.save(currentUser) {[weak self] (record, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: nil)
                return
            }
            
            self?.setupSubscriptions(record!)
            NotificationCenter.default.post(name: CloudKitNotifications.CurrentUserRecordUpdateChannel, object: nil, userInfo: [CloudKitNotifications.CurrentUserRecordUpdateKey : currentUser])
            
        }
    }
    
    
    @available(iOS 10.0, *)
    fileprivate func setupSubscriptions(_ usersRecord : CKRecord) {
        let subscriptionOp = CKModifySubscriptionsOperation()
        
        let relationshipUpdatePredicate = NSPredicate(format: "users CONTAINS %@", usersRecord.recordID)
        
        let requestPredicate = NSPredicate(format: "to = %@", usersRecord.recordID)
        
        let responsePredicate = NSPredicate(format: "to = %@", usersRecord.recordID)
        
        let relationUpdateInfo = CKNotificationInfo()
        relationUpdateInfo.shouldBadge = false
        relationUpdateInfo.alertBody = "Relationship updated"
        relationUpdateInfo.shouldSendContentAvailable = true
        relationUpdateInfo.desiredKeys = [Cloud.RecordKeys.RecordType]
        
        let requestInfo = CKNotificationInfo()
        requestInfo.alertBody = Cloud.Messages.RelationshipRequestMessage
        requestInfo.shouldBadge = false
        requestInfo.soundName = "default"
        requestInfo.shouldSendContentAvailable = true
        requestInfo.desiredKeys = [Cloud.RelationshipRequestAttribute.Relationship, Cloud.RecordKeys.RecordType, Cloud.RelationshipRequestAttribute.Sender]
        
        
        let responseInfo = CKNotificationInfo()
        responseInfo.alertBody = Cloud.Messages.RelationshipResponseMessage
        responseInfo.shouldSendContentAvailable = true
        responseInfo.soundName = "default"
        responseInfo.desiredKeys = [Cloud.RelationshipRequestResponseAttribute.StatusUpdate, Cloud.RecordKeys.RecordType]
        
        let relationshipRequestSubscription = CKQuerySubscription(recordType: Cloud.Entity.RelationshipRequest, predicate: requestPredicate, options: [CKQuerySubscriptionOptions.firesOnRecordCreation])
        
        let relationResponseSubscription = CKQuerySubscription(recordType: Cloud.Entity.RelationshipRequestResponse, predicate: responsePredicate, options: [CKQuerySubscriptionOptions.firesOnRecordCreation])
        
        let relationshipUpdateSubscription = CKQuerySubscription(recordType: Cloud.Entity.Relationship, predicate: relationshipUpdatePredicate, options: [CKQuerySubscriptionOptions.firesOnRecordUpdate, .firesOnRecordDeletion])
        
        
        relationshipUpdateSubscription.notificationInfo = relationUpdateInfo
        relationshipRequestSubscription.notificationInfo = requestInfo
        relationResponseSubscription.notificationInfo = responseInfo
        
        subscriptionOp.subscriptionsToSave = [relationshipRequestSubscription, relationResponseSubscription, relationshipUpdateSubscription]
        
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        subscriptionOp.modifySubscriptionsCompletionBlock = { (savedSubscriptons, deletedSubscriptions, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                print(error!)
                _ = Cloud.errorHandling(error!, sendingViewController: self)
            }
        }
        
        Cloud.CloudDatabase.PublicDatabase.add(subscriptionOp)
    }
}

//MARK: - ImagePickerController Delegate Methods

extension NewProfileViewController : UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let imageInformation = picker.savePickedImageLocally(info)
        
        imageURL = imageInformation.fileURL
        userImage = imageInformation.image
        self.dismiss(animated: true, completion: nil)
    }
    
    
}

//MARK: - TextField Delegation


extension NewProfileViewController : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.onlyAlphabetical() {
            return true
        } else {
            return false
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let enteredText = textField.text {
            if enteredText.onlyAlphabetical(){
                textField.resignFirstResponder()
                return true
            } else {
                return false
            }
        }
        return false
    }
}
