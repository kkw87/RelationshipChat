//
//  NewActivityViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 5/13/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import CloudKit
import MapKit

class NewActivityViewController: UITableViewController {
    
    // MARK : - Constants
    struct Constants {
        static let DefaultErrorMessageTitle = "There seems to be a problem"
        static let NoLocationSelectedMessage = "This activity has no location specified"
        static let NoActivityTitleEnteredMessage = "You need to enter a title for the activity"
        static let AlphabeticalOnlyErrorMessage = "Please only enter alphabetical characters"
        static let DescriptionBoxIsEmptyErrorMessage = "Please enter a description for the activity"
        
        static let ActivitySavedTitle = "Great, your activity is done!"
        static let ActivitySaveBody = "Your activity was successfully created!"
        
        static let AlphaValue : CGFloat = 0.3
    }
    
    struct Storyboard {
        static let FindLocationSegue = "Find Location Segue"
        static let ProfileUnwindSegue = "Back to profile unwind segue"
    }
    
    // MARK : - Outlets
    @IBOutlet weak var activityTitleTextField: UITextField! {
        didSet {
            activityTitleTextField.delegate = self
        }
    }
    

    
    @IBOutlet weak var descriptionBox: UITextView! {
        didSet {
            descriptionBox.delegate = self
            descriptionBox.roundEdges()
        }
    }
    @IBOutlet weak var datePicker: UIDatePicker! {
        didSet {
            datePicker.minimumDate = Date()
        }
    }
    
    @IBOutlet weak var locationDisplayButton: UIButton! {
        didSet {
            locationDisplayButton.roundEdges()
            locationDisplayButton.isEnabled = false
            locationDisplayButton.clipsToBounds = true
        }
    }

    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    @IBOutlet weak var findLocationButton: UIButton! {
        didSet {
            findLocationButton.roundEdges()
            findLocationButton.backgroundColor = UIColor.flatPurple()
            findLocationButton.clipsToBounds = true
            findLocationButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    // MARK : - Instance properties
    var relationship : CKRecord?
    var activityLocation : MKPlacemark? {
        didSet {
            if activityLocation == nil {
                locationDisplayButton.setTitle(Constants.NoLocationSelectedMessage, for: .normal)
                locationDisplayButton.isEnabled = false
            } else {
                locationDisplayButton.isEnabled = true
                let stringAddress = MKPlacemark.parseAddress(selectedItem: activityLocation!)
                locationDisplayButton.setTitle(stringAddress, for: .normal)
            }
        }
    }
    
    fileprivate var newActivity = CKRecord(recordType: Cloud.Entity.RelationshipActivity)
    
    // MARK : - VC Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        locationDisplayButton.setTitleColor(UIColor.systemBlue, for: .normal)
        locationDisplayButton.backgroundColor = UIColor.white

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK : - Outlet actions
    @IBAction func saveActivity(_ sender: Any) {
        
        activityTitleTextField.resignFirstResponder()
        descriptionBox.resignFirstResponder()
        
        guard let activityTitle = activityTitleTextField.text, !(activityTitleTextField.text?.isEmpty)! else {
            displayAlertWithTitle(Constants.DefaultErrorMessageTitle, withBodyMessage: Constants.NoActivityTitleEnteredMessage, withBlock: nil)
            activityTitleTextField.backgroundColor = UIColor.red.withAlphaComponent(Constants.AlphaValue)
            return
        }
        
        guard let activityDescription = descriptionBox.text, !descriptionBox.text.isEmpty else {
            displayAlertWithTitle(Constants.DefaultErrorMessageTitle, withBodyMessage: Constants.DescriptionBoxIsEmptyErrorMessage, withBlock: nil)
            descriptionBox.backgroundColor = UIColor.red.withAlphaComponent(Constants.AlphaValue)
            return
        }

            let newActivity = CKRecord(recordType: Cloud.Entity.RelationshipActivity)
            let activityDate = datePicker.date
            
            newActivity[Cloud.RelationshipActivityAttribute.Relationship] = CKReference(record: relationship!, action: .deleteSelf) as CKRecordValue?
            newActivity[Cloud.RelationshipActivityAttribute.CreationDate] = activityDate as CKRecordValue?
            newActivity[Cloud.RelationshipActivityAttribute.Message] = activityDescription as CKRecordValue?
            newActivity[Cloud.RelationshipActivityAttribute.Name] = activityTitle as CKRecordValue?
            newActivity[Cloud.RecordKeys.RecordType] = Cloud.Entity.RelationshipActivity as CKRecordValue?
        
        
        var relationshipActivityArray = relationship![Cloud.RelationshipAttribute.Activities] as! [CKReference]
        let activityReference = CKReference(record: newActivity, action: .none)
        relationshipActivityArray.append(activityReference)
        
        
        relationship![Cloud.RelationshipAttribute.Activities] = relationshipActivityArray as CKRecordValue?
        
            if activityLocation != nil {
                
                let activityTitle = (activityLocation?.name)!
                let stringAddress = MKPlacemark.parseAddress(selectedItem: activityLocation!)

                newActivity[Cloud.RelationshipActivityAttribute.LocationStringName] = activityTitle as CKRecordValue?
                newActivity[Cloud.RelationshipActivityAttribute.LocationStringAddress] = stringAddress as CKRecordValue?
                newActivity[Cloud.RelationshipActivityAttribute.Location] = CLLocation(latitude: activityLocation!.coordinate.latitude, longitude: activityLocation!.coordinate.longitude) as CKRecordValue?
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            saveButton.isEnabled = false
            findLocationButton.isEnabled = false
        
        //save new activity and relationship 
        
        let saveActivityOp = CKModifyRecordsOperation(recordsToSave: [newActivity, relationship!], recordIDsToDelete: nil)
        
        saveActivityOp.modifyRecordsCompletionBlock = { [weak self] in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.saveButton.isEnabled = true
                self?.findLocationButton.isEnabled = true
            }
            guard $2 == nil else {
                _ = Cloud.errorHandling($2!, sendingViewController: nil)
                return
            }

            let savedActivity = $0?.filter { ($0[Cloud.RecordKeys.RecordType] as? String) == Cloud.Entity.RelationshipActivity }.first
            
            NotificationCenter.default.post(name: CloudKitNotifications.ActivityUpdateChannel, object: nil, userInfo: [CloudKitNotifications.ActivityUpdateKey : savedActivity!])
            
            self?.displayAlertWithTitle(Constants.ActivitySavedTitle, withBodyMessage: Constants.ActivitySaveBody) { _ in
                self?.performSegue(withIdentifier: Storyboard.ProfileUnwindSegue, sender: self)
            }
            
        }
        
        Cloud.CloudDatabase.PublicDatabase.add(saveActivityOp)
    }
    
    @IBAction func getDirectionsToSelectedAddress(_ sender: UIButton) {
        if let selectedPin = activityLocation {
            let mapItem = MKMapItem(placemark: selectedPin)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.FindLocationSegue:
                if let alsvc = segue.destination as? ActivityLocationSelectionViewController {
                    alsvc.delegate = self
                }
            default:
                break
            }
        }
    }
}

// MARK: - HandlePickedLocation protocol functions

extension NewActivityViewController : HandlePickedLocation {
    func newLocationSelectedFrom(placemark: MKPlacemark) {
        activityLocation = placemark
    }
    
}

// MARK : - UITextField delegate methods


extension NewActivityViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let enteredText = textField.text, enteredText.onlyAlphabetical() else {
            displayAlertWithTitle(Constants.DefaultErrorMessageTitle, withBodyMessage: Constants.AlphabeticalOnlyErrorMessage, withBlock: nil)
            textField.backgroundColor = UIColor.red.withAlphaComponent(Constants.AlphaValue)
            return false
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.backgroundColor = UIColor.white
    }
    
}

//MARK : - UITextView Delegates

extension NewActivityViewController : UITextViewDelegate {
        func textViewDidBeginEditing(_ textView: UITextView) {
        textView.backgroundColor = UIColor.white
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        
        guard (textView.text) != nil else {
            textView.backgroundColor = UIColor.red.withAlphaComponent(Constants.AlphaValue)
            displayAlertWithTitle(Constants.DefaultErrorMessageTitle, withBodyMessage: Constants.DescriptionBoxIsEmptyErrorMessage, withBlock: nil)
            return false
        }
        
        textView.resignFirstResponder()
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    
}


