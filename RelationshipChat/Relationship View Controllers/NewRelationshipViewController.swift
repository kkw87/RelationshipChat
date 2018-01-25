//
//  NewRelationshipViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 10/14/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import Firebase

protocol RelationshipCellDelegate : class {
    func displayAlertWithTitle(_ titleMessage : String, withBodyMessage : String, completion: ((UIAlertAction)->Void)? )
    func presentViewController(_ viewControllerToPresent : UIViewController)
    
    func popBackToRoot()
}

@available(iOS 10.0, *)
class NewRelationshipViewController: UITableViewController {
    
    // MARK: - Constants
    struct Constants {
        static let NoUsersAlertTitle = "Unable to find any users"
        static let NoUsersAlertMessage = "We were unable to find any users that are not in a relationship with the current search name."
        
        static let TextFieldPlaceHolder = "Search for users"
    }
    
    struct Storyboard {
        static let cellID = "Relationship Cell"
    }
    

    // MARK: - Instance variables
    
    fileprivate var usersFromSearch = [RelationshipChatUser]()
    
    var currentUser : RelationshipChatUser?
    
    private var userSearchController : UISearchController?
    
    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideEmptyCells()
        setupSearchBar()
        
    }
    // MARK: - Class Methods
    
    
    @IBAction func cancel(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    private func setupSearchBar() {
        userSearchController = UISearchController(searchResultsController: nil)
        userSearchController?.searchResultsUpdater = self
        userSearchController?.searchBar.tintColor = UIColor.white
        
        let textField = userSearchController?.searchBar.value(forKey: "searchField") as! UITextField
        textField.borderStyle = .none
        textField.placeholder = Constants.TextFieldPlaceHolder
        textField.backgroundColor = UIColor.white
        
        navigationItem.searchController = userSearchController
        navigationItem.hidesSearchBarWhenScrolling = false
        userSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return usersFromSearch.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.cellID, for: indexPath) as! RelationshipTableViewCell
        
        cell.selectedUser = usersFromSearch[indexPath.row]
        cell.currentUser = currentUser
        cell.delegate = self
        
        return cell
    }
}

//MARK : - Relationship Cell Delegate
@available(iOS 10.0, *)
extension NewRelationshipViewController : RelationshipCellDelegate {
    func displayAlertWithTitle(_ titleMessage: String, withBodyMessage: String, completion : ((UIAlertAction)->Void)?) {
        displayAlertWithTitle(titleMessage, withBodyMessage: withBodyMessage, withBlock: completion)
    }
    
    func presentViewController(_ viewControllerToPresent: UIViewController) {
        present(viewControllerToPresent, animated: true, completion: nil)
    }
    
    func popBackToRoot() {
        dismiss(animated: true) {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

extension NewRelationshipViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
        let searchText = searchController.searchBar.text!
        
        FirebaseDB.MainDatabase.child(FirebaseDB.RelationshipUserNodeKey).queryOrdered(byChild: RelationshipChatUserKeys.FullName).queryEqual(toValue: searchText).observeSingleEvent(of: .value) { [weak self](fetchedUsers) in
            
            for downloadedChild in fetchedUsers.children {
                let snapshot = downloadedChild as! DataSnapshot
                let valueDictionary = snapshot.value as! [String : Any]

                guard snapshot.key != self?.currentUser?.userUID!, valueDictionary[RelationshipChatUserKeys.RelationshipKey] == nil else {
                    return
                }
                
                //Make new user from information
                let userFromSearch = RelationshipChatUser.makeUserWithValues(userValues: valueDictionary, snapshotKey: snapshot.key)
                self?.usersFromSearch.append(userFromSearch)
                self?.tableView.reloadData()
            }
            
        }
    }
}

