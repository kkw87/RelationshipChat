//
//  NewProfileViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/20/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import Firebase

class NewProfileViewController: UITableViewController, UINavigationControllerDelegate {
    
    //MARK: - Constants
    struct Constants {
        static let LabelCornerRadius = 5
        static let DefaultErrorText = " "
        static let DefaultAlphaColorValue : CGFloat = 0.2
        
        static let FirstNameErrorText = "You need to enter your first name. "
        static let LastNameErrorText = "You need to enter your last name."
        
        static let EmailLoginNoTextErrorText = "You need to enter an email address"
        static let EmailLoginInvalidText = "You need to enter a valid email address"
        
        static let PasswordNoTextErrorText = "You need to enter a password"
        
        static let GenderErrorText = "You need to enter your gender."
        
        static let AlertViewCreationText = "Creating your account..."
        static let AlertViewErrorText = "We were unable to make your account..."
        
        static let ErrorAlertTitleText = "Oops!"
        static let UnselectedEULAErrorMessage = "The EULA has to be agreed to."
        
        static let ProfileCreationError = "We were unable to create your profile"
        
        static let ErrorHighlightColor = UIColor.red.withAlphaComponent(Constants.DefaultAlphaColorValue)
    }
    
    struct Storyboard {
        static let ProfileUnwindSegue = "Unwind to profile"
    }
    
    //MARK: - Outlets
    
    @IBOutlet weak var emailLoginNameTextField: UITextField! {
        didSet {
            emailLoginNameTextField.delegate = self
        }
    }
    
    @IBOutlet weak var passwordLoginNameTextField: UITextField! {
        didSet {
            passwordLoginNameTextField.delegate = self
        }
    }
    
    @IBOutlet fileprivate weak var pictureButton: UIButton! {
        didSet {
            pictureButton.clipsToBounds = true
            pictureButton.setTitleColor(UIColor.flatPurple(), for: .normal)
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
    
    @IBOutlet weak var eulaAgreementSegment: UISegmentedControl!
    
    //MARK: - Instance Variables
    private var userImage : UIImage? {
        get {
            return userImageView.image
        } set {
            userImageView.image = newValue
        }
    }
    
    private var selectedGender : String {
        get {
            switch genderPicker.selectedSegmentIndex {
            case 0:
                return UsersGender.Male
            default:
                return UsersGender.Female
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
    @IBAction private func createNewProfile(_ sender: AnyObject) {
        firstNameTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        
        guard emailLoginNameTextField.hasText else {
            emailLoginNameTextField.backgroundColor = Constants.ErrorHighlightColor
            errorText = Constants.EmailLoginNoTextErrorText
            return
        }
        
        guard emailLoginNameTextField.text!.isValidEmailAddress() else {
            emailLoginNameTextField.backgroundColor = Constants.ErrorHighlightColor
            errorText = Constants.EmailLoginInvalidText
            return
        }
        
        guard passwordLoginNameTextField.hasText else {
            passwordLoginNameTextField.backgroundColor = Constants.ErrorHighlightColor
            errorText = Constants.PasswordNoTextErrorText
            return
        }
        
        guard firstNameTextField.hasText else {
            firstNameTextField.backgroundColor = Constants.ErrorHighlightColor
            errorText = Constants.FirstNameErrorText
            return
        }
        
        guard lastNameTextField.hasText else {
            lastNameTextField.backgroundColor = Constants.ErrorHighlightColor
            errorText = Constants.LastNameErrorText
            return
        }
        
        guard eulaAgreementSegment.selectedSegmentIndex == 1 else {
            errorText = Constants.UnselectedEULAErrorMessage
            return
        }
        
        view.addSubview(loadingView)
        loadingView.updateMessageWith(message: Constants.AlertViewCreationText)
        loadingView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        Auth.auth().createUser(withEmail: emailLoginNameTextField.text!, password: passwordLoginNameTextField.text!) { [weak self] (user, error) in
            
            guard error == nil else {
                self?.displayAlertWithTitle(Constants.ProfileCreationError, withBodyMessage: error!.localizedDescription, withBlock: nil)
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.loadingView.removeFromSuperview()
                }
                
                return
            }
            
            let newUser = RelationshipChatUser()
            newUser.firstName = self?.firstNameTextField.text! ?? ""
            newUser.lastName = self?.lastNameTextField.text! ?? ""
            newUser.birthday = self?.birthdayPicker.date ?? Date()
            newUser.gender = self?.selectedGender ?? UsersGender.Male
            newUser.userUID = user?.uid
            
            //This needs a completion block
            //Add loading view
            newUser.saveUserToDB(userImage: self?.userImage, completionBlock: {[weak self] (completed, error) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    
                    guard error == nil else {
                        DispatchQueue.main.async {
                            self?.displayAlertWithTitle(Constants.DefaultErrorText, withBodyMessage: error!.localizedDescription, withBlock: nil)
                        }
                        return
                    }
                    
                    UserDefaults.standard.set(self?.emailLoginNameTextField.text!, forKey: FireBaseUserDefaults.UsersLoginName)
                    UserDefaults.standard.set(self?.passwordLoginNameTextField.text!, forKey: FireBaseUserDefaults.UsersPassword)
                    //Set user defaults 
                    self?.performSegue(withIdentifier: Storyboard.ProfileUnwindSegue, sender: self)
                }
            })
        }
    }
    
}

//    @available(iOS 10.0, *)
//    fileprivate func setupSubscriptions(_ usersRecord : CKRecord) {
//        let subscriptionOp = CKModifySubscriptionsOperation()
//
//        let relationshipUpdatePredicate = NSPredicate(format: "users CONTAINS %@", usersRecord.recordID)
//
//        let requestPredicate = NSPredicate(format: "to = %@", usersRecord.recordID)
//
//        let responsePredicate = NSPredicate(format: "to = %@", usersRecord.recordID)
//
//        let relationUpdateInfo = CKNotificationInfo()
//        relationUpdateInfo.shouldBadge = false
//        relationUpdateInfo.alertBody = "Relationship updated"
//        relationUpdateInfo.shouldSendContentAvailable = true
//        relationUpdateInfo.desiredKeys = [Cloud.RecordKeys.RecordType]
//
//        let requestInfo = CKNotificationInfo()
//        requestInfo.alertBody = Cloud.Messages.RelationshipRequestMessage
//        requestInfo.shouldBadge = false
//        requestInfo.soundName = "default"
//        requestInfo.shouldSendContentAvailable = true
//        requestInfo.desiredKeys = [Cloud.RelationshipRequestAttribute.Relationship, Cloud.RecordKeys.RecordType, Cloud.RelationshipRequestAttribute.Sender]
//
//
//        let responseInfo = CKNotificationInfo()
//        responseInfo.alertBody = Cloud.Messages.RelationshipResponseMessage
//        responseInfo.shouldSendContentAvailable = true
//        responseInfo.soundName = "default"
//        responseInfo.desiredKeys = [Cloud.RelationshipRequestResponseAttribute.StatusUpdate, Cloud.RecordKeys.RecordType]
//
//        let relationshipRequestSubscription = CKQuerySubscription(recordType: Cloud.Entity.RelationshipRequest, predicate: requestPredicate, options: [CKQuerySubscriptionOptions.firesOnRecordCreation])
//
//        let relationResponseSubscription = CKQuerySubscription(recordType: Cloud.Entity.RelationshipRequestResponse, predicate: responsePredicate, options: [CKQuerySubscriptionOptions.firesOnRecordCreation])
//
//        let relationshipUpdateSubscription = CKQuerySubscription(recordType: Cloud.Entity.Relationship, predicate: relationshipUpdatePredicate, options: [CKQuerySubscriptionOptions.firesOnRecordUpdate, .firesOnRecordDeletion])
//
//
//        relationshipUpdateSubscription.notificationInfo = relationUpdateInfo
//        relationshipRequestSubscription.notificationInfo = requestInfo
//        relationResponseSubscription.notificationInfo = responseInfo
//
//        subscriptionOp.subscriptionsToSave = [relationshipRequestSubscription, relationResponseSubscription, relationshipUpdateSubscription]
//
//
//        DispatchQueue.main.async {
//            UIApplication.shared.isNetworkActivityIndicatorVisible = true
//        }
//
//        subscriptionOp.modifySubscriptionsCompletionBlock = { (savedSubscriptons, deletedSubscriptions, error) in
//
//            DispatchQueue.main.async {
//                UIApplication.shared.isNetworkActivityIndicatorVisible = false
//            }
//
//            if error != nil {
//                _ = Cloud.errorHandling(error!, sendingViewController: self)
//            }
//        }
//
//        Cloud.CloudDatabase.PublicDatabase.add(subscriptionOp)
//    }
//}

//MARK: - ImagePickerController Delegate Methods

extension NewProfileViewController : UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImage : UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImage = originalImage
        }
        
        userImage = selectedImage
        self.dismiss(animated: true, completion: nil)
    }
    
    
}

//MARK: - TextField Delegation


extension NewProfileViewController : UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.backgroundColor = UIColor.white
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        //make sure text field is either first name or last name
        
        if textField == firstNameTextField || textField == lastNameTextField {
            if string.onlyAlphabetical() {
                return true
            } else {
                return false
            }
        }
        
        return true
        
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
