//
//  RelationshipConfirmationViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 2/16/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import Firebase
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
        
        static let NotificationAcceptedTitleMessage = "Your relationship request was accepted!"
        static let NotificationAcceptedTrailingBodyMessage = " has accepted your relationship request."
        
        static let NotificationDeclinedTitleMessage = "Your relationship request was declined!"
        static let NotificationDeclinedTrailingBodyMessage = " has declined your relationship request."
        
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
    
    
    var sendingUsersUID : String?
    var requestedRelationshipUID : String?
    private var sendingUserToken : String?
    
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
        
        RelationshipChatUser.pullUserFromFB(uid: sendingUsersUID!) { [weak self] (fetchedUser, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            guard let user = fetchedUser else {
                print("unable to fetch user from relationship confirmation")
                return
            }
            
            self?.messageLabel.text = "\(user.fullName)\(Constants.RelationshipRequestMessageTrailing)"
            
            self?.sendingUserToken = user.tokenID
            self?.swipeView = ConfirmationView(frame: (self?.mainViewFrame)!, recordOfUserToShow: user, options: options)
            self?.view.addSubview((self?.swipeView!)!)
            
            self?.constructLikedButton()
            self?.constructDeclineButton()
        }
    }
    
    //TODO, setup swipe to accept accept relationship 
    func acceptRelationship() {
        //Fetch the relationship from FB
        
        let relationshipMembers = [sendingUsersUID, (Auth.auth().currentUser?.uid)!]
        let relationshipStartDate = Date().timeIntervalSince1970
        let relationshipStatus = RelationshipStatus.Dating
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipRelationshipNodeKey).child(requestedRelationshipUID!).updateChildValues([RelationshipKeys.Members : relationshipMembers, RelationshipKeys.StartDate : relationshipStartDate, RelationshipKeys.Status : relationshipStatus], withCompletionBlock: { [weak self] (error, _) in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    self?.displayAlertWithTitle(Constants.ErrorTitle, withBodyMessage: error!.localizedDescription) { _ in
                        self?.presentingViewController?.dismiss(animated: true, completion: nil)
                    }
                }
                
                
                
                return
            }
            
            FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(Auth.auth().currentUser!.uid).updateChildValues([RelationshipChatUserKeys.RelationshipKey : self!.requestedRelationshipUID!], withCompletionBlock: { (error, _) in
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        self?.displayAlertWithTitle(Constants.ErrorTitle, withBodyMessage: error!.localizedDescription) { _ in
                            self?.presentingViewController?.dismiss(animated: true, completion: nil)
                        }
                    }
                    return
                }
                
                let newAnniversaryActivity = RelationshipChatActivity()
                newAnniversaryActivity.creationDate = Date()
                newAnniversaryActivity.description = SystemActivity.AnniversaryActivityDescription
                newAnniversaryActivity.title = SystemActivity.AnniversaryActivityTitle
                newAnniversaryActivity.systemActivity = SystemActivity.Anniversary
                newAnniversaryActivity.relationship = self!.requestedRelationshipUID!
                newAnniversaryActivity.saveActivity(completionHandler: { (error, activityID) in
                    guard error == nil else {
                        print(error!)
                        return
                    }
                    
                    FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipRelationshipNodeKey).child(self!.requestedRelationshipUID!).updateChildValues([RelationshipKeys.AnniversaryRecordID : activityID!])
                    
                })
                
                FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    let currentUserValues = snapshot.value as! [String : Any]
                    let currentUsersBirthday = Date(timeIntervalSince1970: currentUserValues[RelationshipChatUserKeys.BirthdayKey] as! TimeInterval)
                    let currentUsersFirstName = currentUserValues[RelationshipChatUserKeys.FirstNameKey] as! String
                    
                    
                    let currentUserBirthdayActivity = RelationshipChatActivity()
                    currentUserBirthdayActivity.title = "\(currentUsersFirstName)\(SystemActivity.BirthdayActivityTrailingTitle)"
                    currentUserBirthdayActivity.description = "\(currentUsersFirstName)\(SystemActivity.BirthdayActivityTrailingBody)"
                    currentUserBirthdayActivity.creationDate = currentUsersBirthday
                    currentUserBirthdayActivity.systemActivity = SystemActivity.Birthday
                    currentUserBirthdayActivity.relationship = self!.requestedRelationshipUID!
                    currentUserBirthdayActivity.saveActivity(completionHandler: { (error, activityID) in
                        guard error == nil else {
                            print(error!)
                            return
                        }
                        
                        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(Auth.auth().currentUser!.uid).updateChildValues([RelationshipChatUserKeys.BirthdayActivityID : activityID!])
                    })
                    
                })
                
                FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(self!.sendingUsersUID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    let sendingUserValues = snapshot.value as! [String : Any]
                    let sendingUsersBirthday = Date(timeIntervalSince1970: sendingUserValues[RelationshipChatUserKeys.BirthdayKey] as! TimeInterval)
                    let sendingUsersFirstName = sendingUserValues[RelationshipChatUserKeys.FirstNameKey] as! String
                    
                    
                    let sendingUserBirthdayActivity = RelationshipChatActivity()
                    sendingUserBirthdayActivity.title = "\(sendingUsersFirstName)\(SystemActivity.BirthdayActivityTrailingTitle)"
                    sendingUserBirthdayActivity.description = "\(sendingUsersFirstName)\(SystemActivity.BirthdayActivityTrailingBody)"
                    sendingUserBirthdayActivity.creationDate = sendingUsersBirthday
                    sendingUserBirthdayActivity.systemActivity = SystemActivity.Birthday
                    sendingUserBirthdayActivity.relationship = self!.requestedRelationshipUID!
                    sendingUserBirthdayActivity.saveActivity(completionHandler: { (error, activityID) in
                        guard error == nil else {
                            print(error!)
                            return
                        }
                        
                        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).child(self!.sendingUsersUID!).updateChildValues([RelationshipChatUserKeys.BirthdayActivityID : activityID!])
                    })
                    
                    
                })
                
                
                DispatchQueue.main.async {
                    self?.displayAlertWithTitle(Constants.RelationshipAcceptedTitle, withBodyMessage: Constants.RelationshipAcceptedBody, withBlock: { _ in
                        self?.presentingViewController?.dismiss(animated: true, completion: nil)
                    })
                }
                
                
            })
            
        })
    }
    
    
    //TODO, setup relationship confirmation decline relationship
    func declineRelationship() {
        
        RelationshipChatRelationship.deleteRelationship(relationshipUID: requestedRelationshipUID!) { (error) in
            
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                self.displayAlertWithTitle(Constants.RelationshipDeclinedTitle, withBodyMessage: Constants.RelationshipDeclinedBody, withBlock: { _ in
                    FirebaseDB.sendNotification(toTokenID: self.sendingUserToken!, titleText: Constants.NotificationDeclinedTitleMessage, bodyText: Constants.NotificationDeclinedTrailingBodyMessage, dataDict: nil, contentAvailable: false, completionHandler: { (error) in
                        
                    })
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                })
            }
            
        }
        
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
