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

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
