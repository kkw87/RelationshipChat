//
//  LoginViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 12/16/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    struct Constants {
        
        static let ErrorTitleMessage = "Oops!"
        static let InvalidLoginNameText = "Please enter a valid login email address"
        static let InvalidPassword = "Please enter your password"
        
        static let LoggingInMessage = "Logging in"
    }
    
    struct Storyboard {
        static let NewProfileSegue = "Create New Profile"
        static let UnwindBackToProfileSegue = "Unwind To Profile Segue"
    }
    
    //MARK: - Outlets
    
    @IBOutlet weak var loginNameTextField: UITextField! {
        didSet {
            loginNameTextField.delegate = self
        }
    }
    
    @IBOutlet weak var passwordTextField: UITextField! {
        didSet {
            passwordTextField.delegate = self
        }
    }
    
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            loginButton.roundEdges()
        }
    }
    
    //MARK: - Instance Properties
    private var loadingView = ActivityView(withMessage: "")
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.flatPurple()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        //Try to pull in user information from nsUserDefaults
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Outlet Actions
    @IBAction func login(_ sender: Any) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        loadingView.updateMessageWith(message: Constants.LoggingInMessage)
        view.addSubview(loadingView)
        loadingView.center = view.center
        loginNameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        Auth.auth().signIn(withEmail: loginNameTextField.text!, password: passwordTextField.text!) { [weak self] (user, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.loadingView.removeFromSuperview()
            }
            
            guard error == nil else {
                self?.displayAlertWithTitle(Constants.ErrorTitleMessage, withBodyMessage: error!.localizedDescription, withBlock: nil)
                return
            }
            
            UserDefaults.standard.set(self?.loginNameTextField.text!, forKey: FireBaseUserDefaults.UsersLoginName)
            UserDefaults.standard.set(self?.passwordTextField.text!, forKey: FireBaseUserDefaults.UsersPassword)
            
            self?.performSegue(withIdentifier: Storyboard.UnwindBackToProfileSegue, sender: self)
        }
    }
    
    @IBAction func createNewAccount(_ sender: Any) {
        performSegue(withIdentifier: Storyboard.NewProfileSegue, sender: nil)
    }

}

extension LoginViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == loginNameTextField {
            
            guard !loginNameTextField.text!.isEmpty, loginNameTextField.text!.isValidEmailAddress() else {
                displayAlertWithTitle(Constants.ErrorTitleMessage, withBodyMessage: Constants.InvalidLoginNameText, withBlock: nil)
                textField.resignFirstResponder()
                return false
            }
            
            textField.resignFirstResponder()
            return true
        }
        
        if textField == passwordTextField {
            
            guard !passwordTextField.text!.isEmpty else {
                displayAlertWithTitle(Constants.ErrorTitleMessage, withBodyMessage: Constants.InvalidPassword, withBlock: nil)
                textField.resignFirstResponder()
                return false
            }
            
            
            textField.resignFirstResponder()
            login(self)
            return true
            
        }
        textField.resignFirstResponder()
        return true
    }
}

