//
//  RelationshipTableViewCell.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 12/29/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import Firebase

@available(iOS 10.0, *)
class RelationshipTableViewCell: UITableViewCell {
    
    //MARK : - Constants
    struct Constants {
        static let DefaultErrorMessageTitle = "There seems to be a problem"
        static let UserErrorMessage = "We were unable to access your account"
        static let RelationshipActivityMessage = "Requesting a relationship..."
        static let UserInARelationshipErrorMessage = "You are already in a relationship or have one pending"
        static let RequestedUserInARelationshipMessage = "The user is already in a relationship or is awaiting a response from a request"
        static let RelationshipSuccessTitle = "Relationship Request Sent"
        static let RelationshipBodyMessage = "You successfully sent a relationship request!"
        static let DoneButtonText = "Done"
        static let RequestBodyText = "has requested to start a relationship with you!"
    }
    
    //MARK : - Outlets
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var relationshipButton: UIButton! {
        didSet {
            relationshipButton.roundEdges()
            relationshipButton.clipsToBounds = true
        }
    }
    
    @IBOutlet fileprivate weak var userName: UILabel!
    
    @IBOutlet weak var userImageView: UIImageView! {
        didSet {
            userImageView.roundEdges()
            userImageView.clipsToBounds = true
            userImageView.contentMode = .scaleAspectFill
        }
    }
    
    //MARK : - Instance Properties
    var delegate : RelationshipCellDelegate?
    
    var currentUser : RelationshipChatUser?
    var selectedUser : RelationshipChatUser? {
        didSet {
            if selectedUser != nil {
                userName.text = selectedUser?.fullName
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                selectedUser?.getUsersProfileImage(completionHandler: { [weak self](usersImage, error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    
                    guard error == nil else {
                        print(error!.localizedDescription)
                        return
                    }
                    
                    self?.userImage = usersImage
                })
            }
        }
    }
    
    var userImage : UIImage? {
        get {
            return userImageView.image
        } set {
            if newValue != nil {
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    self.spinner.isHidden = true
                    self.userImageView.image = newValue!
                }
            }
        }
    }
    
    //MARK : - Outlet functions
    @IBAction func requestRelationship(_: Any) {
        
        //Make a new relationship
        let newRelationship = RelationshipChatRelationship()
        newRelationship.relationshipMembers.append(currentUser!.userUID!)
        
        newRelationship.saveNewRelationship { [weak self] (error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            
            FirebaseDB.sendNotification(toTokenID: (self?.selectedUser!.tokenID)!, titleText: "You have a relationship request!", bodyText: "\((self?.currentUser?.fullName)!) has requested a relationship with you!", dataDict: [FirebaseDB.NotificationRelationshipRequestDataKey : newRelationship.relationshipUID, FirebaseDB.NotificationRelationshipRequestSenderKey : (self?.currentUser!.userUID)!], contentAvailable: true) { (error) in
                                
                guard error == nil else {
                    self?.delegate?.displayAlertWithTitle(Constants.DefaultErrorMessageTitle, withBodyMessage: error!.localizedDescription, completion: nil)
                    return
                }
                
                //Update current User, relationship should download
                self?.currentUser?.relationship = newRelationship.relationshipUID
                
                self?.currentUser?.saveUserToDB(userImage: nil, completionBlock: { (_, error) in
                    guard error == nil else {
                        print(error!)
                        return
                    }          
                    self?.delegate?.displayAlertWithTitle(Constants.RelationshipSuccessTitle, withBodyMessage: Constants.RelationshipBodyMessage) {_ in
                        self?.delegate?.popBackToRoot()
                    }
                    
                })
                
            }
            
        }
        

        
    }
    
    //MARK : - Class functions
    

    
}
