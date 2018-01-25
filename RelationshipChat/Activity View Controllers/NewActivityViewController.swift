//
//  NewActivityViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 5/13/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class NewActivityViewController: UITableViewController{
    
    // MARK : - Constants
    struct Constants {
        static let DefaultErrorMessageTitle = "There seems to be a problem"
        static let NoLocationSelectedMessage = "This activity has no location specified"
        static let NoActivityTitleEnteredMessage = "You need to enter a title for the activity"
        static let AlphabeticalOnlyErrorMessage = "Please only enter alphabetical characters"
        static let DescriptionBoxIsEmptyErrorMessage = "Please enter a description for the activity"
        
        
        
        static let ActivitySavingMessage = "Saving your activity"
        
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
    
    fileprivate var loadingView = ActivityView(withMessage: "")
    
    // MARK : - VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationDisplayButton.setTitleColor(UIColor.systemBlue, for: .normal)
        locationDisplayButton.backgroundColor = UIColor.white
        navigationItem.largeTitleDisplayMode = .never
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
        
        //Pull relationship ID from user
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value) { (snapshot) in
            let userValues = snapshot.value as! [String : Any]
            let currentUserName = userValues[RelationshipChatUserKeys.FirstNameKey] as! String
            let relationshipID = userValues[RelationshipChatUserKeys.RelationshipKey] as! String
            
            
            
            
            let newActivity = RelationshipChatActivity()
            newActivity.title = activityTitle
            newActivity.description = activityDescription
            newActivity.relationship = relationshipID
            newActivity.creationDate = self.datePicker.date
            
            
            if self.activityLocation != nil, let activityTitle = self.activityLocation?.name {
                
                let stringAddress = MKPlacemark.parseAddress(selectedItem: self.activityLocation!)
                newActivity.locationStringName = activityTitle
                newActivity.locationStringAddress = stringAddress
                newActivity.location = CLLocationCoordinate2D(latitude: self.activityLocation!.coordinate.latitude, longitude: self.activityLocation!.coordinate.longitude)
                
            }
            
            DispatchQueue.main.async {
                
                self.view.addSubview(self.loadingView)
                self.loadingView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
                self.loadingView.updateMessageWith(message: Constants.ActivitySavingMessage)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                
                
            }
            newActivity.saveActivity(completionHandler: { (error, activityID) in
                guard error == nil else {
                    print(error!)
                    return
                }
                
                DispatchQueue.main.async {
                    self.loadingView.removeFromSuperview()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.performSegue(withIdentifier: Storyboard.ProfileUnwindSegue, sender: self)
                    
                }
                
                FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipRelationshipNodeKey).child(relationshipID).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    let secondaryUserValues = (snapshot.value as! [String : Any])[RelationshipKeys.Members] as! [String]
                    let secondaryUserID = secondaryUserValues.filter {
                        $0 != Auth.auth().currentUser?.uid
                        }.first
                    
                    FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(secondaryUserID!).observeSingleEvent(of: .value, with: { (userSnapshot) in
                        let secondaryUserTokenID = (userSnapshot.value as! [String : Any])[RelationshipChatUserKeys.NotificationTokenID] as! String
                        
                        FirebaseDB.sendNotification(toTokenID: secondaryUserTokenID, titleText: "\(currentUserName) set a new activity!", bodyText: newActivity.description, dataDict: nil, contentAvailable: false, completionHandler: { (error) in
                            guard error == nil else {
                                print(error)
                                return 
                            }
                        })
                        
                    })
                    
                })
                
                
            })
            
        }
        
    }
    
    @IBAction func getDirectionsToSelectedAddress(_ sender: UIButton) {
        if let selectedPin = activityLocation {
            let mapItem = MKMapItem(placemark: selectedPin)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    
    @IBAction func cancelActivity(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
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


