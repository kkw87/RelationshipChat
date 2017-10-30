//
//  RelationshipConfirmationViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 2/16/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import CloudKit
import MDCSwipeToChoose


@available(iOS 10.0, *)
class RelationshipConfirmationViewController: UIViewController {
    
    //MARK : - Constants
    struct Constants {
        
        //Text Constants
        static let RelationshipAcceptedTitle = "Success!"
        static let RelationshipAcceptedBody = "You are now in a relationship!"
        static let RelationshipDeclinedTitle = "You Declined the relationship request."
        static let RelationshipDeclinedBody = "You have declined request to enter the relationship."
        static let ErrorTitle = "Oops!"
        static let UserAnswerActivityMessage = "Sending your response"
        static let RelationshipRequestMessageTrailing = " has requested a relationship with you!"
        
        //Numerical Constants
        static let mainViewHorizontalPadding : CGFloat = 20.0
        static let topPadding : CGFloat = 60.0
        static let bottomPadding : CGFloat = 200.0
        
        static let AcceptDeclineButtonHorizontalPadding : CGFloat = 80.0
        static let AcceptDeclineButtonVerticalPadding : CGFloat = 20.0
    }
    
    //MARK: - Outlets
    @IBOutlet weak var messageLabel: UILabel! {
        didSet {
            messageLabel.backgroundColor = UIColor.flatPurple()
            messageLabel.textColor = UIColor.white
            messageLabel.clipsToBounds = true
            messageLabel.roundEdges()
        }
    }
    //MARK: - Instance Properties
    
    fileprivate var swipeView: ConfirmationView?
    
    fileprivate lazy var mainViewFrame : CGRect = {
        return CGRect(x: Constants.mainViewHorizontalPadding, y: Constants.topPadding, width: self.view.frame.width - (Constants.mainViewHorizontalPadding * 2), height: self.view.frame.height - Constants.bottomPadding)
    }()
    
    var usersRecord : CKRecord?
    var relationshipRequestID : CKRecordID?
    var sendersRecord : CKRecord?
    var relationship : CKRecord?
    
    
    //MARK: - VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    //MARK: - Class Functions
    
    private func setup() {
        let options = MDCSwipeToChooseViewOptions()
        options.delegate = self
        options.likedText = "Yes!"
        options.likedColor = UIColor.green
        options.nopeText = "Nope!"
        options.nopeColor = UIColor.red
        
        let senderUserInformation = Cloud.pullUserInformationFrom(usersRecordToLoad: sendersRecord!)
        messageLabel?.text = "\(senderUserInformation.usersFirstName)\(Constants.RelationshipRequestMessageTrailing)"
        
        //Setup swipe view
        swipeView = ConfirmationView(frame: mainViewFrame, recordOfUserToShow: sendersRecord!, options: options)
        view.addSubview(swipeView!)
        constructLikedButton()
        constructDeclineButton()
    }
    
    func acceptRelationship() {
        
        let saveRecordsOperation = makeChangesToRecordsForSave()
        
        //Secondary user subscription updates
        Cloud.saveMessageSubscription(relationship!, currentUser: usersRecord!)
        Cloud.addsubscriptionToSecondaryUserChanges(currentRelationship: relationship!, currentUserRecord: usersRecord!)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        saveRecordsOperation.savePolicy = .changedKeys
        
        saveRecordsOperation.modifyRecordsCompletionBlock = { [weak self] (savedRecords, deletedRecords, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: self)
                return
            }
            
                DispatchQueue.main.async {
                    self?.displayAlertWithTitle(Constants.RelationshipAcceptedTitle, withBodyMessage: Constants.RelationshipAcceptedBody, withBlock: { _ in
                        
                        NotificationCenter.default.post(name: CloudKitNotifications.RelationshipUpdateChannel, object: nil, userInfo: [CloudKitNotifications.RelationshipUpdateKey : self?.relationship as Any])
                        self?.presentingViewController?.dismiss(animated: true, completion: nil)
                    })
                }
            
            
        }
        
        
        Cloud.CloudDatabase.PublicDatabase.add(saveRecordsOperation)
    }
    
    
    
    func declineRelationship() {
        
        Cloud.CloudDatabase.PublicDatabase.delete(withRecordID: relationship!.recordID) { [weak self] (deletedRelationship, error) in
            if error != nil {
                _ = Cloud.errorHandling(error!, sendingViewController: nil)
            } else {
                //Create new response with "Declined", directed back to user
                let declinedResponseRecord = CKRecord(recordType: Cloud.Entity.RelationshipRequestResponse)
                declinedResponseRecord[Cloud.RelationshipRequestResponseAttribute.StatusUpdate] = Cloud.Status.Declined as CKRecordValue?
                declinedResponseRecord[Cloud.RelationshipRequestResponseAttribute.UserToSendTo] = CKReference(record: (self?.sendersRecord)!, action: .none) as CKRecordValue?
                declinedResponseRecord[Cloud.RecordKeys.RecordType] = Cloud.Entity.RelationshipRequestResponse as CKRecordValue?
                
                let declinedResponseRecordsOp = CKModifyRecordsOperation(recordsToSave: [declinedResponseRecord], recordIDsToDelete: [(self?.relationshipRequestID)!])
                declinedResponseRecordsOp.modifyRecordsCompletionBlock = { (savedRecords, deletedRecords, error) in
                    
                    guard error == nil else {
                        _ = Cloud.errorHandling(error!, sendingViewController: self)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.displayAlertWithTitle(Constants.RelationshipDeclinedTitle, withBodyMessage: Constants.RelationshipDeclinedBody, withBlock: { _ in
                            self?.presentingViewController?.dismiss(animated: true, completion: nil)
                        })
                    }
                    
                    
                }
                Cloud.CloudDatabase.PublicDatabase.add(declinedResponseRecordsOp)
                
            }
        }
    }
    
    
    private func makeChangesToRecordsForSave() -> CKModifyRecordsOperation {
        
        relationship![Cloud.RelationshipAttribute.StartDate] = Date() as CKRecordValue?
        relationship![Cloud.RelationshipAttribute.Status] = Cloud.RelationshipStatus.Dating as CKRecordValue?
        
        if var userArray = relationship![Cloud.RelationshipAttribute.Users] as? [CKReference] {
            userArray.append(CKReference(record: usersRecord!, action: .deleteSelf))
            relationship![Cloud.RelationshipAttribute.Users] = userArray as CKRecordValue?
            
        } else {
            let userReference = CKReference(record: usersRecord!, action: .deleteSelf)
            relationship![Cloud.RelationshipAttribute.Users] = [userReference] as CKRecordValue?
        }
        
        usersRecord![Cloud.UserAttribute.Relationship] = CKReference(record: relationship!, action: .none)
        
        let acceptedResponse = CKRecord(recordType: Cloud.Entity.RelationshipRequestResponse)
        acceptedResponse[Cloud.RelationshipRequestResponseAttribute.StatusUpdate] = Cloud.Status.Accepted as CKRecordValue?
        acceptedResponse[Cloud.RelationshipRequestResponseAttribute.UserToSendTo] = CKReference(record: sendersRecord!, action: .deleteSelf) as CKRecordValue?
        acceptedResponse[Cloud.RecordKeys.RecordType] = Cloud.Entity.RelationshipRequestResponse as CKRecordValue?
        
        let usersName = usersRecord![Cloud.UserAttribute.FirstName] as! String
        let usersBirthdayActivity = CKRecord(recordType: Cloud.Entity.RelationshipActivity)
        
        let usersBirthdayDate = usersRecord![Cloud.UserAttribute.Birthday] as! Date
        usersBirthdayActivity[Cloud.RelationshipActivityAttribute.CreationDate] = usersBirthdayDate as CKRecordValue?
        usersBirthdayActivity[Cloud.RelationshipActivityAttribute.Message] = "Today is \(usersName)'s birthday!" as CKRecordValue?
        usersBirthdayActivity[Cloud.RelationshipActivityAttribute.Name] = "\(usersName)'s birthday" as CKRecordValue?
        usersBirthdayActivity[Cloud.RelationshipActivityAttribute.SystemCreated] = Cloud.RelationshipActivitySystemCreatedTypes.Birthday as CKRecordValue?
        usersBirthdayActivity[Cloud.RelationshipActivityAttribute.Relationship] = CKReference(record: relationship!, action: .deleteSelf) as CKRecordValue?
        usersBirthdayActivity[Cloud.RecordKeys.RecordType] = Cloud.Entity.RelationshipActivity as CKRecordValue?
        
        
        if var relationshipActivityArray = relationship![Cloud.RelationshipAttribute.Activities] as? [CKReference] {
            
            let newActivityReference = CKReference(record: usersBirthdayActivity, action: .none)
            
            relationshipActivityArray.append(newActivityReference)
            relationship![Cloud.RelationshipAttribute.Activities] = relationshipActivityArray as CKRecordValue?
            
        } else {
            let newActivityReference = CKReference(record: usersBirthdayActivity, action: .none)
            relationship![Cloud.RelationshipAttribute.Activities] = [newActivityReference] as CKRecordValue?
        }
        
        return CKModifyRecordsOperation(recordsToSave: [relationship!, acceptedResponse, usersRecord!, usersBirthdayActivity], recordIDsToDelete: [self.relationshipRequestID!])
    }
    
    //MARK : - View Construction Methods
    private func constructDeclineButton() -> Void{
        let button:UIButton =  UIButton(type: UIButtonType.system)
        let image = UIImage(named: "Dislike Filled-50")!
        button.frame = CGRect(x: Constants.AcceptDeclineButtonHorizontalPadding, y: self.swipeView!.frame.maxY + Constants.AcceptDeclineButtonVerticalPadding, width: image.size.width, height: image.size.height)
        button.setBackgroundImage(image, for: .normal)
        button.addTarget(self, action: #selector(declineButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        button.backgroundColor = UIColor.clear
        self.view.addSubview(button)
    }
    
    private func constructLikedButton() -> Void{
        let button:UIButton = UIButton(type: UIButtonType.system)
        let image = UIImage(named: "Hearts Filled-50")!
        button.frame = CGRect(x: self.view.frame.maxX - image.size.width - Constants.AcceptDeclineButtonHorizontalPadding, y: self.swipeView!.frame.maxY + Constants.AcceptDeclineButtonVerticalPadding, width: image.size.width, height: image.size.height)
        button.setBackgroundImage(image, for: .normal)
        button.addTarget(self, action: #selector(acceptButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        button.backgroundColor = UIColor.clear
        self.view.addSubview(button)
        
    }
}

@available(iOS 10.0, *)
extension RelationshipConfirmationViewController : MDCSwipeToChooseDelegate  {
    
    // This is called when a user swipes the view fully left or right.
    func view(_ view: UIView, wasChosenWith: MDCSwipeDirection) -> Void {
        if wasChosenWith == .left {
            declineRelationship()
        } else {
            acceptRelationship()
        }
    }
    
    
    @objc func declineButtonPressed(_ sender : UIButton) -> Void {
        self.swipeView?.mdc_swipe(.left)
    }
    
    @objc func acceptButtonPressed(_ sender : UIButton) -> Void {
        self.swipeView?.mdc_swipe(.right)
    }
    
    
    
}
