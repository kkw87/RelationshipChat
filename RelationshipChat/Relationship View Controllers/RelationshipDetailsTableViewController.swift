//
//  RelationshipDetailsTableViewController.swift
//  
//
//  Created by Kevin Wang on 11/10/17.
//

import UIKit
import Firebase

class RelationshipDetailsTableViewController: UITableViewController {
    
    struct Constants {
        static let ActionSheetTitle = "Report User"
        static let ActionSheetBody = "How was this user behaving Inappropriately?"
        
        static let AlertCompletionTitle = "User successfully reported"
        static let AlertCompletionBody = "Your complaint will be reviewed and acted upon within 24 hours."
        
    }
    
    // MARK: - Model
    var secondaryUser : RelationshipChatUser?

    // MARK: - Outlets
    
    @IBOutlet weak var usersImage: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var reportUserButton: UIButton! {
        didSet {
            reportUserButton.roundEdges()
            reportUserButton.clipsToBounds = true
        }
    }
    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Class Functions
    private func setupUI() {
        
        secondaryUser?.getUsersProfileImage { (userImage, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                self.usersImage.image = userImage
                self.firstNameTextField.text = self.secondaryUser?.firstName ?? ""
                self.lastNameTextField.text = self.secondaryUser?.lastName ?? ""
            }
        }

    }
    
    // MARK: - Outlet Actions
    
    @IBAction func reportUser(_ sender: Any) {
        
        func logMarkedUserWithReason(reason : String, completionBlock : @escaping ()->Void) {

            guard secondaryUser != nil else {
                return
            }

            FirebaseDB.MainDatabase.child(FirebaseDB.ReportedUserNodeKey).child(secondaryUser!.userUID!).updateChildValues([(Auth.auth().currentUser?.uid)! : reason]) { (error, _) in
                guard error == nil else {
                    print(error!)
                    return
                }
                
                DispatchQueue.main.async {
                    completionBlock()
                }
                
            }

        }

        let finishedLoggingBlock = {
            self.displayAlertWithTitle(Constants.AlertCompletionTitle, withBodyMessage: Constants.AlertCompletionBody, withBlock: nil)
        }

        let userReportActionSheet = UIAlertController(title: Constants.ActionSheetTitle, message: Constants.ActionSheetBody, preferredStyle: .actionSheet)

        let spamAction = UIAlertAction(title: FlaggedUserBehaviors.Spam, style: .default) { _ in
            logMarkedUserWithReason(reason: FlaggedUserBehaviors.Spam, completionBlock: finishedLoggingBlock)
        }

        let commentsAction = UIAlertAction(title: FlaggedUserBehaviors.InappropriateComments, style: .default) { (_) in
            logMarkedUserWithReason(reason: FlaggedUserBehaviors.InappropriateComments, completionBlock: finishedLoggingBlock)
        }

        let harassmentAction = UIAlertAction(title: FlaggedUserBehaviors.Harassment, style: .default) { (_) in
            logMarkedUserWithReason(reason: FlaggedUserBehaviors.Harassment, completionBlock: finishedLoggingBlock)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.dismiss(animated: true, completion: nil)
        }

        userReportActionSheet.addAction(spamAction)
        userReportActionSheet.addAction(commentsAction)
        userReportActionSheet.addAction(harassmentAction)
        userReportActionSheet.addAction(cancelAction)

        present(userReportActionSheet, animated: true, completion: nil)
        
    }
    
}
