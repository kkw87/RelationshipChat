//
//  Extensions.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 11/4/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import CloudKit
import MapKit
import ChameleonFramework
//MARK: - Global Constants

struct Constants {
    static let defaultImageButtonText = "Profile Picture"
    static let pictureButtonBorderWidth : CGFloat = 2.0
    static let defaultAlphaColorValue : CGFloat = 0.2
}

//MARK: - String extensions
extension String {
    func onlyAlphabetical() -> Bool {
        let decimalCharacters = CharacterSet.decimalDigits
        let whiteSpace = CharacterSet.whitespaces
        
        if self.rangeOfCharacter(from: decimalCharacters) == nil && self.rangeOfCharacter(from: whiteSpace) == nil {
            return true
        } else {
            return false
        }
    }
    
    func isValidEmailAddress() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) != nil
    }
}

//MARK: - UIColor extensions

extension UIColor {
    static var systemBlue : UIColor {
        return UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
    }
    
}

//MARK : - UIViewController extensions

extension UIViewController {
    
    func displayAlertWithTitle(_ titleMessage: String, withBodyMessage: String, withBlock : ((UIAlertAction) -> Void)?) {
        
        let alertController = UIAlertController(title: titleMessage, message: withBodyMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: withBlock))
        present(alertController, animated: true, completion: nil)
    }
    
    
}

//MARK: - UIImagePickerController extensions

extension UIImagePickerController {
    
    
    func savePickedImageLocally(_ info : [String : Any]) -> (image : UIImage, fileURL : URL?) {
        
        var savedPath : URL?
        let image = info[UIImagePickerControllerEditedImage] as! UIImage
        let pickerImageURL = info[UIImagePickerControllerImageURL] as? URL
        let imageName = pickerImageURL?.lastPathComponent
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let photoURL = URL(fileURLWithPath: documentDirectory)
        let localPath = photoURL.appendingPathComponent(imageName!)
        
        do {
            try UIImageJPEGRepresentation(image, 1.0)?.write(to: localPath)
            savedPath = localPath
        } catch {
            print("error saving image")
        }
        
        return (image, savedPath)
        
    }
}


//MARK: - TableViewController
extension UITableViewController {
    func hideEmptyCells() {
        tableView.tableFooterView = UIView(frame: .zero)
    }
}

//MARK: - CKAsset
extension CKAsset {
    func convertToImage() -> UIImage? {
        let pictureData = try? Data(contentsOf: self.fileURL)
        if pictureData != nil {
            let convertedImage = UIImage(data: pictureData!)
            return convertedImage
        } else {
            return nil
        }
        
    }
    
}

//MARK: - Image
extension UIImage {
    func convertedToCKAsset() -> CKAsset {
        let data = UIImagePNGRepresentation(self)
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString+".dat")
        
        do {
            try data!.write(to: url)
        } catch let error {
            _ = Cloud.errorHandling(error, sendingViewController: nil)
        }
        return CKAsset(fileURL: url)
        
    }
}

//MARK: - View
extension UIView {
    func circularView() {
        self.layer.cornerRadius = 0.5 * self.bounds.size.width
        self.clipsToBounds = true
    }
    
    func roundEdges() {
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
    
}

//MARK: - Tab Bar Controller

extension UITabBarController {
    var chatBarItem : UITabBarItem? {
        return self.tabBar.items?[1] 
    }
    
    var relationshipBarItem : UITabBarItem? {
        return self.tabBar.items?[2]
    }
}

//MARK: - MKPlacemark
extension MKPlacemark {
    static func parseAddress(selectedItem : MKPlacemark) -> String {
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(format: "%@%@%@%@%@%@%@", selectedItem.subThoroughfare ?? "", firstSpace, selectedItem.thoroughfare ?? "", comma, selectedItem.locality ?? "", secondSpace, selectedItem.administrativeArea ?? "")
        
        return addressLine
    }
}

//MARK: - Date 
extension Date {
    
    func returnDayAndDateAsString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MM/dd/yyyy"
        
        return formatter.string(from: self)
    }
    
}

//MARK: - Navigation Controller
extension UINavigationController {
    var contentViewController : UIViewController  {
        get {
            if let visibleVC = self.visibleViewController {
                return visibleVC
            } else {
                return self
            }
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.barTintColor = UIColor.flatPurple()
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
    }
}




