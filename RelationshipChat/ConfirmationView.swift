//
//  ConfirmationView.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 6/26/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import MDCSwipeToChoose
import UIKit
import CloudKit

class ConfirmationView : MDCSwipeToChooseView {

    //MARK: - Constants
    struct Constants {
        static let imageLabelWidth : CGFloat = 42.0
        static let rightPadding:CGFloat = 10.0
        
        static let leftPadding : CGFloat = 12.0
        static let topPadding : CGFloat = 17.0
        
        static let bottomHeight : CGFloat = 60.0

    }
    
    //MARK: - Instance properties
    fileprivate var nameLabel: UILabel!
    fileprivate var informationView: UIView!
    fileprivate var ageImageLabelView:ImagelabelView!
    fileprivate var genderImageLabelView: ImagelabelView!
    fileprivate var nameToUse = " "
    fileprivate var age = 0
    fileprivate var gender = ""
    
    //MARK: - Initializers
    init(frame: CGRect, recordOfUserToShow : RelationshipChatUser, options: MDCSwipeToChooseViewOptions) {
        super.init(frame: frame, options: options)
        
        let calendar = NSCalendar.current
        
        self.imageView.contentMode = .scaleAspectFill
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        recordOfUserToShow.getUsersProfileImage { [weak self] (userImage, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                self?.imageView.image = userImage!
            }
            
        }
        self.imageView.backgroundColor = UIColor.white
        self.nameToUse = recordOfUserToShow.fullName
        self.gender = recordOfUserToShow.gender
        
        let currentDate = calendar.startOfDay(for: Date())
        let usersBirthday = calendar.startOfDay(for: (recordOfUserToShow.birthday))
        
        self.age = calendar.dateComponents([.year], from: usersBirthday, to: currentDate).year!
        
        self.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth,
        UIViewAutoresizing.flexibleBottomMargin]
        
        self.imageView.autoresizingMask = self.autoresizingMask
        
        constructInformationView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    //MARK : - Class methods
    
    func constructInformationView() -> Void{
        let bottomFrame: CGRect = CGRect(x: 0, y: self.bounds.height - Constants.bottomHeight, width: self.bounds.width, height: Constants.bottomHeight)
        self.informationView = UIView(frame:bottomFrame)
        self.informationView.backgroundColor = UIColor.white
        self.informationView.clipsToBounds = true
        self.informationView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleTopMargin]
        self.addSubview(self.informationView)
        constructNameLabel()
        constructAgeImageLabelView()
        constructGenderImageLabelView()
    }
    
    func constructNameLabel() -> Void{

        let frame:CGRect = CGRect(x: Constants.leftPadding, y: Constants.topPadding, width: floor(self.informationView.frame.width/2), height: self.informationView.frame.height - Constants.topPadding)
        self.nameLabel = UILabel(frame:frame)
        self.nameLabel.text = self.nameToUse
        self.nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        
        self.informationView .addSubview(self.nameLabel)
    }
    
    func constructAgeImageLabelView() -> Void{
        let image:UIImage = UIImage(named:"Age")!
        self.ageImageLabelView = buildImageLabelViewLeftOf(x: self.informationView.bounds.width, image : image, text: "\(age)")
        self.informationView.addSubview(self.ageImageLabelView)
    }
    
    func constructGenderImageLabelView() -> Void{
        
        var imageName = ""
        switch gender {
        case UsersGender.Male :
            imageName = "MaleIcon"
        default :
            imageName = "FemaleIcon"
        }
        
        let image: UIImage = UIImage(named: imageName)!
        self.genderImageLabelView = self.buildImageLabelViewLeftOf(x: self.ageImageLabelView.frame.minX, image: image, text: "")
        self.informationView.addSubview(self.genderImageLabelView)
    }
    
    
    func buildImageLabelViewLeftOf(x:CGFloat, image:UIImage, text:String) -> ImagelabelView{
        let frame = CGRect(x: x - Constants.imageLabelWidth, y: 0, width: Constants.imageLabelWidth, height: self.informationView.bounds.height)
            
        let view:ImagelabelView = ImagelabelView(frame:frame, image:image, text:text)
        view.autoresizingMask = UIViewAutoresizing.flexibleLeftMargin
        return view
    }
    
    
    
}
