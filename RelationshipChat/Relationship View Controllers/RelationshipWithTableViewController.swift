//
//  RelationshipWithTableViewController.swift
//  
//
//  Created by Kevin Wang on 11/10/17.
//

import UIKit
import CloudKit

class RelationshipWithTableViewController: UITableViewController {
    
    struct Constants {
        static let ActionSheetTitle = "Report User"
        static let ActionSheetBody = "How was this user behaving Inappropriately?"
        
        static let AlertCompletionTitle = "User successfully reported"
        static let AlertCompletionBody = "Your complaint will be reviewed and acted upon within 24 hours."
        
    }
    
    // MARK: - Model
    var relationshipWithRecord : CKRecord?

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
        print(relationshipWithRecord)
        guard relationshipWithRecord != nil else {
            return
        }
        
        let usersInformation = Cloud.pullUserInformationFrom(usersRecordToLoad: relationshipWithRecord!)
        
        usersImage.image = usersInformation.usersImage
        firstNameTextField.text = usersInformation.usersFirstName
        lastNameTextField.text = usersInformation.usersLastName
    }
    
    // MARK: - Outlet Actions
    
    @IBAction func reportUser(_ sender: Any) {
        
        func logMarkedUserWithReason(reason : String, completionBlock : @escaping ()->Void) {
            
            guard relationshipWithRecord != nil else {
                return
            }
            
            let markedUser = CKRecord(recordType: Cloud.Entity.MarkedUser)
            markedUser[Cloud.MarkedUserAttributes.MarkedUsersIDReference] = CKReference(record: relationshipWithRecord!, action: .deleteSelf) as CKRecordValue?
            markedUser[Cloud.MarkedUserAttributes.Reason] = reason as CKRecordValue?
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            Cloud.CloudDatabase.PublicDatabase.save(markedUser) {(savedRecord, error) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
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
        
        let spamAction = UIAlertAction(title: Cloud.FlaggedUserBehaviors.Spam, style: .default) { _ in
            logMarkedUserWithReason(reason: Cloud.FlaggedUserBehaviors.Spam, completionBlock: finishedLoggingBlock)
        }
        
        let commentsAction = UIAlertAction(title: Cloud.FlaggedUserBehaviors.InappropriateComments, style: .default) { (_) in
            logMarkedUserWithReason(reason: Cloud.FlaggedUserBehaviors.InappropriateComments, completionBlock: finishedLoggingBlock)
        }
        
        let harassmentAction = UIAlertAction(title: Cloud.FlaggedUserBehaviors.Harassment, style: .default) { (_) in
            logMarkedUserWithReason(reason: Cloud.FlaggedUserBehaviors.Harassment, completionBlock: finishedLoggingBlock)
        }
        
        userReportActionSheet.addAction(spamAction)
        userReportActionSheet.addAction(commentsAction)
        userReportActionSheet.addAction(harassmentAction)
        
        present(userReportActionSheet, animated: true, completion: nil)
        
    }
    
    // MARK: - Table view data source
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

}
