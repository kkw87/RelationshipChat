//
//  EditProfileViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/12/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import Firebase

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
        
        static let ErrorLoadingProfileAlertTitle = "We couldn't load your profile"
        static let ErrorLoadingProfileAlertBody = "There was an error in loading your profile information, either it doesn't exist or there was a problem fetching it."
        
        static let ErrorAlertTitle = "Oops!"
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
    
    var mainUserRecord : RelationshipChatUser? {
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
                return UsersGender.Male
            default :
                return UsersGender.Female
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
        
        guard mainUserRecord != nil else {
            displayAlertWithTitle(Constants.ErrorLoadingProfileAlertTitle, withBodyMessage: Constants.ErrorLoadingProfileAlertBody, withBlock: { (_) in
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            })
            return
        }
        
        deleteProfileButton?.backgroundColor = UIColor.red
        firstNameLabel?.text = mainUserRecord?.firstName
        lastNameLabel?.text = mainUserRecord?.lastName
        mainUserRecord?.getUsersProfileImage() { [weak self](image, error) in
            guard error == nil else {
                self?.displayAlertWithTitle(Constants.ErrorLoadingProfileAlertTitle, withBodyMessage: error!.localizedDescription, withBlock: nil)
                return
            }
            
            DispatchQueue.main.async {
                self?.usersImage = image
                
            }
        }
        birthdayPicker?.setDate(mainUserRecord!.birthday, animated: true)
        originalBirthday = mainUserRecord!.birthday
        
        if let gender = mainUserRecord?.gender {
            switch gender {
            case UsersGender.Male:
                genderPicker?.selectedSegmentIndex = 0
            default:
                genderPicker?.selectedSegmentIndex = 1
            }
        }
    }
    
    
    @IBAction func updateUserInfo(_ sender: Any) {
        firstNameLabel.resignFirstResponder()
        lastNameLabel.resignFirstResponder()
        
        if mainUserRecord != nil  {
            
            mainUserRecord?.gender = userGender
            mainUserRecord?.birthday = birthdayPicker.date
            mainUserRecord?.firstName = firstNameLabel.text ?? ""
            mainUserRecord?.lastName = lastNameLabel.text ?? ""
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            saveButton.isEnabled = false
            
            
            mainUserRecord?.saveUserToDB(userImage: usersImage, completionBlock: { [weak self](completed, error) in
                guard error == nil else {
                    self?.displayAlertWithTitle(Constants.ErrorAlertTitle, withBodyMessage: error!.localizedDescription, withBlock: nil)
                    return
                }
                if completed {
                    
                    //Update birthday activity
                    FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(self!.mainUserRecord!.userUID!).observeSingleEvent(of: .value, with: { (snapshot) in
                        let userValues = snapshot.value as! [String : Any]
                        if let birthdayActivityID = userValues[RelationshipChatUserKeys.BirthdayActivityID] as? String {
                            FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipActivityNodeKey).child(birthdayActivityID).updateChildValues([ActivityKeys.ActivityDate : self!.mainUserRecord!.birthday.timeIntervalSince1970])
                        }
                        
                    })
                    
                    self?.displayAlertWithTitle(Constants.FinishedSavingAlertTitle, withBodyMessage: Constants.FinishedSavingAlertBody) { _ in
                        self?.performSegue(withIdentifier: Storyboard.UnwindBackToProfileSegue, sender: self)
                    }
                    
                }
            })
            
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
            
            self?.mainUserRecord?.deleteUser(completionHandler: { (error) in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.deleteProfileButton.isEnabled = true
                    self?.saveButton.isEnabled = true
                    self?.navigationItem.leftBarButtonItem?.isEnabled = true
                }
                
                guard error == nil else {
                    self?.displayAlertWithTitle(Constants.ErrorAlertTitle, withBodyMessage: error!.localizedDescription, withBlock: nil)
                    return
                }
                
                self?.displayAlertWithTitle(Constants.AccountDeletedTitle, withBodyMessage: Constants.AccountDeletedBody) { _ in
                    self?.mainUserRecord?.deleteUser(completionHandler: { (error) in
                        guard error == nil else {
                            print(error!)
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self?.mainUserRecord = nil
                            
                            self?.performSegue(withIdentifier: Storyboard.UnwindBackToProfileSegue, sender: self)
                        }
                        
                    })

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
        
        if let editedPic = info[UIImagePickerControllerEditedImage] as? UIImage {
            usersImage = editedPic
        } else if let regularPic = info[UIImagePickerControllerOriginalImage] as? UIImage {
            usersImage = regularPic
        }
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
