//
//  RelationshipChatViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 12/25/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit
import Firebase
import CoreData
import MobileCoreServices
import AVFoundation

class RelationshipChatViewController: UICollectionViewController, UINavigationControllerDelegate  {
    
    
    private struct Constants {
        static let ContainerViewHeight : CGFloat = 50
        static let SendButtonWidth : CGFloat = 80
        static let MediaSendImageWidthHeight : CGFloat = 34
        static let PaddingValueLeftInputTextField : CGFloat = 8
        static let SeparatorViewHeight : CGFloat = 1
        static let SeparatorViewBackgroundColor = UIColor.flatGray()
        static let SendButtonTitle = "Send"
        static let InputTextFieldPlaceHolderText = "Enter Message..."
        
        static let DefaultCellIdentifier = "CellID"
        
        static let messageCellHeight : CGFloat = 80
        static let imageMessageCellWidth : CGFloat = 200
        static let collectionViewBottomInsertPadding : CGFloat = 58
        
        static let OutgoingCellColor = UIColor.flatPurple()
        static let OutgoingCellTextColor = UIColor.white
        static let IncmoingCellColor = UIColor(red: 240, green: 240, blue: 240, alpha: 0)
        static let IncomingCellTextColor = UIColor.black
        
        static let ImageZoomAnimationDuration : TimeInterval = 0.5
    }
    
    //MARK: - VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserInformation()
        
        //Reenable if not using input accessory view as text input
        setupKeyboardObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Model
    
    var messages = [RelationshipChatMessage]()
    
    //MARK: - Instance Properties
    
    //Starting frame for image before it is zoomed in, used for animation to return the animation after the zoom is dismissed
    fileprivate var startingZoomFrame : CGRect?
    fileprivate var zoomBackgroundView : UIView?
    fileprivate var imageViewToZoom : UIImageView?
    
    private var currentUser : RelationshipChatUser?
    private var secondaryUser : RelationshipChatUser? {
        didSet {
            if secondaryUser != nil {
            navigationItem.title = secondaryUser?.fullName
            } else {
                navigationItem.title = nil
            }
        }
    }
    private var currentRelationship : RelationshipChatRelationship? {
        didSet {
            if currentRelationship != nil {
                loadMessages()
            }
        }
    }
    
    private lazy var inputTextField : UITextField = {
        let textField = UITextField()
        textField.placeholder = Constants.InputTextFieldPlaceHolderText
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    private var lastSentMessage : RelationshipChatMessage?
    
    private var containerViewBottomAnchor : NSLayoutConstraint?
    
    //Setup the container view for the input accessory view that sticks on top of the keyboard
//    lazy var inputContainerView: UIView = {
//        let containerView = UIView()
//        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: Constants.ContainerViewHeight)
//        containerView.backgroundColor = UIColor.white
//
//        //Create send button
//        let sendButton = UIButton(type: .system)
//        sendButton.setTitle(Constants.SendButtonTitle, for: .normal)
//        sendButton.translatesAutoresizingMaskIntoConstraints = false
//        sendButton.tintColor = UIColor.flatPurple()
//        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
//        containerView.addSubview(sendButton)
//
//        //Setup send button constraints
//        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
//        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        sendButton.widthAnchor.constraint(equalToConstant: Constants.SendButtonWidth).isActive = true
//        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
//
//        //Add text field to container view
//        containerView.addSubview(inputTextField)
//
//        //Setup text field constraints
//        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: Constants.PaddingValueLeftInputTextField).isActive = true
//        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
//        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
//        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
//
//
//        //Setup line separating textfield and send button from texts
//        let separatorLineView = UIView()
//        separatorLineView.backgroundColor = Constants.SeparatorViewBackgroundColor
//        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
//        containerView.addSubview(separatorLineView)
//        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
//        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
//        separatorLineView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
//        separatorLineView.heightAnchor.constraint(equalToConstant: Constants.SeparatorViewHeight).isActive = true
//
//
//        return containerView
//    }()
//
    
//
//    override var inputAccessoryView: UIView? {
//        get {
//            return inputContainerView
//        }
//    }
//
    //Needed to show input accessory view
//    override var canBecomeFirstResponder: Bool {
//        return true
//    }
    
    // MARK: - Keyboard show/hidden animation
    
    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: Notification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc
    func handleKeyboardDidShow(notification : NSNotification) {
        finishedSendingMessage()
    }
    
    @objc
    func handleKeyboardWillShow(notification : NSNotification) {
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double {
            
            //Adjust input area
            containerViewBottomAnchor?.constant = -keyboardFrame.height + (tabBarController?.tabBar.frame.height)!
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            })
            
        }
    }
    
    @objc
    func handleKeyboardWillHide(notification : NSNotification) {
        
        if let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double {
            containerViewBottomAnchor?.constant = 0
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    //MARK: - UI setup functions
    
    private func setupUI() {
        
        collectionView?.collectionViewLayout = UICollectionViewFlowLayout()
        collectionView?.register(RelationshipChatCollectionViewCell.self, forCellWithReuseIdentifier: Constants.DefaultCellIdentifier)
        collectionView?.backgroundColor = UIColor.white
        
        
        collectionView?.contentInset = UIEdgeInsetsMake(ChatBubbleConstants.textviewBubblePaddingPhoneInside, 0, Constants.collectionViewBottomInsertPadding, 0)
        collectionView?.scrollIndicatorInsets = UIEdgeInsetsMake(ChatBubbleConstants.textviewBubblePaddingPhoneInside, 0, 50, 0)
        
        //collectionView?.keyboardDismissMode = .interactive
        
        //Comment back if you want to do keyboard animation separate instead of using input accessory view as the input
        //Create container view for text field and send button
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.white
        
        //Create the select media button
        let mediaUploadView = UIImageView()
        mediaUploadView.image = UIImage(named: "PaperClip")
        containerView.addSubview(mediaUploadView)
        mediaUploadView.isUserInteractionEnabled = true
        mediaUploadView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectMessageMedia)))
        mediaUploadView.translatesAutoresizingMaskIntoConstraints = false
        mediaUploadView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        mediaUploadView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        mediaUploadView.widthAnchor.constraint(equalToConstant: Constants.MediaSendImageWidthHeight).isActive = true
        mediaUploadView.heightAnchor.constraint(equalToConstant: Constants.MediaSendImageWidthHeight).isActive = true

        view.addSubview(containerView)
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        containerViewBottomAnchor?.isActive = true

        containerView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: Constants.ContainerViewHeight).isActive = true

        //Create send button
        let sendButton = UIButton(type: .system)
        sendButton.setTitle(Constants.SendButtonTitle, for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.tintColor = UIColor.flatPurple()
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        containerView.addSubview(sendButton)

        //Setup send button constraints
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: Constants.SendButtonWidth).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true

        //Add text field to container view
        containerView.addSubview(inputTextField)

        //Setup text field constraints
        inputTextField.leftAnchor.constraint(equalTo: mediaUploadView.rightAnchor, constant: Constants.PaddingValueLeftInputTextField).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true


        //Setup line separating textfield and send button from texts
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = Constants.SeparatorViewBackgroundColor
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: Constants.SeparatorViewHeight).isActive = true
    }
    
    //MARK: - Load User Information methods
    private func loadUserInformation() {
        
        //Pull current user information
        RelationshipChatUser.pullUserFromFB(uid: Auth.auth().currentUser!.uid) { (currentPulledUser, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            if currentPulledUser != nil {
                self.currentUser = currentPulledUser
                
                //Pull current relationship information
                RelationshipChatRelationship.fetchRelationship(withUID: currentPulledUser!.relationship!, completionHandler: { (pulledRelationship, error) in
                    guard error == nil else {
                        print(error!)
                        return
                    }
                    
                    if pulledRelationship != nil {
                        //Find secondary user ID from relationship
                        self.currentRelationship = pulledRelationship
                        
                        let secondaryUserID = pulledRelationship?.relationshipMembers.filter {
                            $0 != Auth.auth().currentUser!.uid
                        }.first!
                        
                        //Pull secondary user information
                        RelationshipChatUser.pullUserFromFB(uid: secondaryUserID!, completionHandler: { (pulledSecondaryUser, error) in
                            
                            guard error == nil else {
                                print(error!)
                                return
                            }
                            
                            if pulledSecondaryUser != nil {
                                DispatchQueue.main.async {
                                    self.secondaryUser = pulledSecondaryUser
                                }
                                //Else statement if secondary user couldn't be fetched
                            } else {
                                self.secondaryUser = nil
                                self.currentRelationship = nil
                            }
                            
                        })
                        //Else statement if relationship couldn't be fetched
                    } else {
                        self.currentRelationship = nil
                        self.secondaryUser = nil
                    }
                    
                })
                
            }
        }
    }
    
    //MARK: - Saving/Loading Messages
    
    private func loadMessages() {
        
        func addDownloadedMessage(messageFromFB : RelationshipChatMessage) {
            DispatchQueue.main.async {
                
                self.messages.append(messageFromFB)
                self.messages.sort(by: { (message1, message2) -> Bool in
                    message1.timeStamp < message2.timeStamp
                })
                self.collectionView?.reloadData()
            }
            
        }
        
        //Convenience function to convert coreDB message to RelationshipChatMessage
        func convertCoreDBtoRelationshipChatMessage(messageToConvert : Message) -> RelationshipChatMessage {
            
            
            if let savedImageData = messageToConvert.image, let savedImage = UIImage(data: savedImageData) {
                
                let imageMessage = RelationshipChatMediaMessage()
                imageMessage.senderDisplayName = messageToConvert.senderDisplayName!
                imageMessage.relationshipID = messageToConvert.relationshipUID!
                imageMessage.image = savedImage
                imageMessage.imageName = messageToConvert.imageName!
                imageMessage.imageWidth = savedImage.size.width
                imageMessage.imageHeight = savedImage.size.height
                imageMessage.sendingUserID = messageToConvert.senderUID!
                imageMessage.receivingUserID = messageToConvert.receivingUserUID!
                imageMessage.timeStamp = messageToConvert.created!
                imageMessage.messageUID = messageToConvert.messageUID!
                imageMessage.video = messageToConvert.video
                imageMessage.videoName = messageToConvert.videoName
                if let downloadURLString = messageToConvert.videoDownloadURL {
                    imageMessage.videoDownloadURL = URL(string: downloadURLString)
                }
                
                
                return imageMessage

            } else {
                
                let textMessage = RelationshipChatTextMessage()
                textMessage.senderDisplayName = messageToConvert.senderDisplayName!
                textMessage.relationshipID = messageToConvert.relationshipUID!
                textMessage.sendingUserID = messageToConvert.senderUID!
                textMessage.receivingUserID = messageToConvert.receivingUserUID!
                textMessage.timeStamp = messageToConvert.created!
                textMessage.messageUID = messageToConvert.messageUID!
                textMessage.text = messageToConvert.text!
                
                return textMessage
                
            }
        }
        
        //Fetch all messages from DB
        let messageRequest : NSFetchRequest<Message> = Message.fetchRequest()
        messageRequest.predicate = NSPredicate(format: "relationshipUID = %@", currentRelationship!.relationshipUID)
        messageRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]
        
        CoreDataDB.Context.perform {
            if let fetchedMessages = try? CoreDataDB.Context.fetch(messageRequest) {
                
                for coreDBMessage in fetchedMessages {
                    
                    let convertedMessage = convertCoreDBtoRelationshipChatMessage(messageToConvert: coreDBMessage)
                    
                    DispatchQueue.main.async {
                        self.messages.append(convertedMessage)
                    }
                    if convertedMessage.sendingUserID == self.currentUser!.userUID {
                        self.lastSentMessage = convertedMessage
                    }
                    
                }
            }
            
            DispatchQueue.main.async {
                self.messages.sort {
                    $0.timeStamp < $1.timeStamp
                }
                self.collectionView?.reloadData()
                self.finishedSendingMessage()
            }
        }
        FirebaseDB.MainDatabase.child(FirebaseDB.MessageByRelationshipFanOutKey).child(currentRelationship!.relationshipUID).observe(.childAdded) { [weak self] (snapshot) in
            
            if let dictValues = snapshot.value as? [String : Any] {
                
                let messageID = snapshot.key
                let sendingUserID = dictValues[messageID] as! String
                
                guard sendingUserID == self?.currentUser?.userUID else {
                    return
                }
                
                if self?.messages.contains(where: { (message) -> Bool in
                    message.messageUID == messageID
                }) == false {
                    
                    if dictValues[RelationshipChatMessageKeys.MessageText] != nil {
                        RelationshipChatTextMessage.pullTextMessageFromFB(uid: messageID, completionHandler: { (messageFromFB) in
                            if messageFromFB != nil {
                            addDownloadedMessage(messageFromFB: messageFromFB!)
                            }
                        })
                    } else if dictValues[RelationshipChatMessageKeys.ImageURL] != nil {
                        RelationshipChatMediaMessage.pullMessageFromFB(uid: messageID, completionHandler: { (messageFromFB) in
                            if messageFromFB != nil {
                                addDownloadedMessage(messageFromFB: messageFromFB!)
                            }
                        })
                    }
                    
                }
            }
        }
        
    }
    
    @objc private func sendMessage() {
        
        guard inputTextField.text != nil, !inputTextField.text!.isEmpty, !inputTextField.text!.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        let newTextMessage = RelationshipChatTextMessage()
        newTextMessage.senderDisplayName = self.currentUser!.fullName
        newTextMessage.text = self.inputTextField.text!
        newTextMessage.relationshipID = self.currentRelationship!.relationshipUID
        newTextMessage.sendingUserID = self.currentUser!.userUID!
        newTextMessage.receivingUserID = self.secondaryUser!.userUID!
        newTextMessage.timeStamp = Date()

        let enteredText = self.inputTextField.text!
        inputTextField.text = nil
        
        newTextMessage.saveMessageToFB() { (error, referenceKey) in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                self.messages.append(newTextMessage)
                self.collectionView?.reloadData()
                self.finishedSendingMessage()
            }
            
            FirebaseDB.sendNotification(toTokenID: self.secondaryUser!.tokenID, titleText: self.currentUser!.fullName, bodyText: enteredText, dataDict: nil, contentAvailable: false, completionHandler: { (error) in
                guard error == nil else {
                    print(error!)
                    return
                }
            })
            newTextMessage.messageUID = referenceKey!
            self.saveMessageToCoreData(message: newTextMessage)
            
        }
    }
    
    private func saveMessageToCoreData(message : RelationshipChatMessage) {
        
        let coreDataMessage = Message(context: CoreDataDB.Context)
        coreDataMessage.created = message.timeStamp
        coreDataMessage.messageUID = message.messageUID
        coreDataMessage.receivingUserUID = message.receivingUserID
        coreDataMessage.relationshipUID = message.relationshipID
        coreDataMessage.senderDisplayName = message.senderDisplayName
        coreDataMessage.senderUID = message.sendingUserID
        
        if let textMessage = message as? RelationshipChatTextMessage {
     
            coreDataMessage.text = textMessage.text
            
        } else if let mediaMessage = message as? RelationshipChatMediaMessage {
            coreDataMessage.image = UIImageJPEGRepresentation(mediaMessage.image!, 1.0)
            coreDataMessage.imageName = mediaMessage.imageName!
            coreDataMessage.video = mediaMessage.video
            coreDataMessage.videoName = mediaMessage.videoName
            coreDataMessage.videoDownloadURL = mediaMessage.videoDownloadURL?.absoluteString
        }
        CoreDataDB.Container.performBackgroundTask { (_) in
            try? CoreDataDB.Context.save()
        }
    }
    
    fileprivate func saveVideoToFB(videoURL : URL) {
        
        let videoName = NSUUID().uuidString
        
        
        let videoStorageRef = FirebaseDB.FBStorage.child(FirebaseDB.UserUploadedMediaNodeKey).child(currentRelationship!.relationshipUID).child(videoName)
        
        let storeImageTask = videoStorageRef.putFile(from: videoURL, metadata: nil) { (metaData, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            if let savedVideoDownloadURL = metaData?.downloadURL()?.absoluteString {
                
                if let thumbnailImage = self.thumbnailImageForVideo(fileURL: videoURL) {
                    
                     let videoName = NSUUID().uuidString + ".mov"
                    let thumbnailImageName = videoName + ".thumbnail"
                    let thumbnailAsData = UIImageJPEGRepresentation(thumbnailImage, 0.2)
                    
                    //Save thumbnail image first
                    FirebaseDB.FBStorage.child(FirebaseDB.UserUploadedMediaNodeKey).child(self.currentRelationship!.relationshipUID).child(thumbnailImageName).putData(thumbnailAsData!, metadata: nil, completion: { (savedThumbnailMeta, error) in
                        
                        let thumbnailURL = savedThumbnailMeta?.downloadURL()?.absoluteString
              
                        let newVideoMessage = RelationshipChatMediaMessage()
                        newVideoMessage.senderDisplayName = self.currentUser!.fullName
                        newVideoMessage.relationshipID = self.currentRelationship!.relationshipUID
                        newVideoMessage.image = thumbnailImage
                        newVideoMessage.imageName = videoName + ".thumbnail"
                        newVideoMessage.imageWidth = thumbnailImage.size.width
                        newVideoMessage.imageHeight = thumbnailImage.size.height
                        newVideoMessage.sendingUserID = self.currentUser!.userUID!
                        newVideoMessage.receivingUserID = self.secondaryUser!.userUID!
                        newVideoMessage.timeStamp = Date()
                        newVideoMessage.videoName = videoName
                        newVideoMessage.videoDownloadURL = metaData?.downloadURL()
                        //TODO, set actual video file 
             
                        newVideoMessage.saveMediaMessageToFB(imageUrlString : thumbnailURL!, imageWidth: thumbnailImage.size.width, imageHeight: thumbnailImage.size.height, videoURL: savedVideoDownloadURL, videoName: videoName, completionHandler: { (error, messageID) in
                            
                            guard error == nil else {
                                print(error!.localizedDescription)
                                return
                            }
                            
                            DispatchQueue.main.async {
                                self.messages.append(newVideoMessage)
                                self.collectionView?.reloadData()
                                self.finishedSendingMessage()
                            }
                            
                            FirebaseDB.sendNotification(toTokenID: self.secondaryUser!.tokenID, titleText: self.currentUser!.fullName, bodyText: "You got a video!", dataDict: nil, contentAvailable: false, completionHandler: { (error) in
                                guard error == nil else {
                                    print(error!)
                                    return
                                }
                            })
                            
                            newVideoMessage.messageUID = messageID!
                            self.saveMessageToCoreData(message: newVideoMessage)
                        })
                        
                    })

                }
                //Create message
                //Save created message to FB with
                //Send notification
            }
            
        }
        
        storeImageTask.observe(.progress) { (snapshot) in
            print(snapshot.progress?.completedUnitCount)
        }
        
        storeImageTask.observe(.success) { (snapshot) in
            
        }
        
    }
    
    private func thumbnailImageForVideo(fileURL : URL) -> UIImage? {
        let asset = AVAsset(url: fileURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
                    let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)

        } catch let error {
            print(error)
        }

        return nil
    }
    
    fileprivate func saveImageToFB(image : UIImage) {
        
        //Generate image name
        let imageName = NSUUID().uuidString
       let storageRef = FirebaseDB.FBStorage.child(FirebaseDB.UserUploadedMediaNodeKey).child(currentRelationship!.relationshipUID).child(imageName)
        
        if let imageAsData = UIImageJPEGRepresentation(image, 0.2) {
            let imageSaveTask = storageRef.putData(imageAsData, metadata: nil, completion: { (savedImageMetaData, error) in
                guard error == nil else {
                    print(error!)
                    return
                }
                
                if let savedImageURL = savedImageMetaData?.downloadURL()?.absoluteString {
                    
                    let newImageMessage = RelationshipChatMediaMessage()
                    newImageMessage.senderDisplayName = self.currentUser!.fullName
                    newImageMessage.relationshipID = self.currentRelationship!.relationshipUID
                    newImageMessage.image = image
                    newImageMessage.imageName = imageName
                    newImageMessage.imageWidth = image.size.width
                    newImageMessage.imageHeight = image.size.height
                    newImageMessage.sendingUserID = self.currentUser!.userUID!
                    newImageMessage.receivingUserID = self.secondaryUser!.userUID!
                    newImageMessage.timeStamp = Date()


                    newImageMessage.saveMediaMessageToFB(imageUrlString : savedImageURL, imageWidth: image.size.width, imageHeight: image.size.height, videoURL: nil, videoName: nil, completionHandler: { (error, messageID) in
                        
                        guard error == nil else {
                            print(error!.localizedDescription)
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.messages.append(newImageMessage)
                            self.collectionView?.reloadData()
                            self.finishedSendingMessage()
                        }
                        
                        FirebaseDB.sendNotification(toTokenID: self.secondaryUser!.tokenID, titleText: self.currentUser!.fullName, bodyText: "You got a picture!", dataDict: nil, contentAvailable: false, completionHandler: { (error) in
                            guard error == nil else {
                                print(error!)
                                return
                            }
                        })
                        
                        newImageMessage.messageUID = messageID!
                        self.saveMessageToCoreData(message: newImageMessage)
                    })
                }
                
            })
            
            imageSaveTask.observe(.progress, handler: { (snapshot) in
                print(snapshot.progress?.completedUnitCount)
            })
            
            
            imageSaveTask.observe(.success, handler: { (snapshot) in
                
            })
            
        }
        
    }
    
    //MARK: - Collection view data source
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.DefaultCellIdentifier, for: indexPath) as! RelationshipChatCollectionViewCell
        let message = messages[indexPath.row]
        cell.delegate = self
        
        setupChatCell(cell: cell, message: message)
        return cell
    }
    
    private func setupChatCell(cell : RelationshipChatCollectionViewCell, message : RelationshipChatMessage) {
    
        //Setup cell for incoming and outgoing 
        if message.sendingUserID == Auth.auth().currentUser?.uid {
            //setup message for outgoing
            cell.setupForOutgoingCell()
            
        } else {
            
            //setup message for incoming
            cell.setupForIncomingCell()
            secondaryUser?.getUsersProfileImage(completionHandler: { (fetchedUserImage, _) in
                if fetchedUserImage != nil {
                    cell.cellImage = fetchedUserImage
                }
            })

        }
        
        
        if let textMessage = message as? RelationshipChatTextMessage {
            cell.messageImageView.isHidden = true
            cell.textView.text = textMessage.text
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: textMessage.text).width + ChatBubbleConstants.bubbleWidthPadding
            cell.textView.isHidden = false
            cell.playButton.isHidden = true
        } else if let mediaMessage = message as? RelationshipChatMediaMessage {
            cell.messageImageView.isHidden = false
            cell.messageImageView.image = mediaMessage.image
            cell.bubbleView.backgroundColor = UIColor.clear
            cell.bubbleWidthAnchor?.constant = Constants.imageMessageCellWidth
            cell.textView.isHidden = true
            cell.playButton.isHidden = mediaMessage.videoName == nil
            cell.videoURL = mediaMessage.videoDownloadURL
            
            //Setup for image or video TODO
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    //MARK: - Animation Methods
    private func finishedSendingMessage() {
        
        guard messages.count > 2 else {
            return
        }
        
        collectionView?.scrollToItem(at: IndexPath(row: messages.count - 1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: true)
    }
    
    //MARK: - Media Selection methods
    @objc
    private func selectMessageMedia() {
        let imagePickerController = UIImagePickerController()

        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            imagePickerController.mediaTypes = [kUTTypeImage as! String, kUTTypeMovie as! String]
            imagePickerController.allowsEditing = true
            imagePickerController.delegate = self
            present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    //MARK: - Formatting Methods
    fileprivate func estimateFrameForText(text : String) -> CGRect {
        let size = CGSize(width: ChatBubbleConstants.bubbleWidth, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: ChatBubbleConstants.fontSize)], context: nil)
    }
    
}

extension RelationshipChatViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.text?.isEmpty)! {
            return false
        } else {
            textField.resignFirstResponder()
        sendMessage()
        return true
        }
    }
}

extension RelationshipChatViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let message = messages[indexPath.row]
        var height: CGFloat = 80
        
        if let textMessage = message as? RelationshipChatTextMessage {
            height = estimateFrameForText(text: textMessage.text).height + 20

        } else if let imageMessage = message as? RelationshipChatMediaMessage {
            //Determine cell height for image based on saved width/height from firebase
            height = CGFloat(imageMessage.imageHeight! / imageMessage.imageWidth! * Constants.imageMessageCellWidth)
        }
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
}

extension RelationshipChatViewController : UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        //Check for imageVideo URL
        if let videoURL = info[UIImagePickerControllerMediaURL] as? URL {
            saveVideoToFB(videoURL: videoURL)
            dismiss(animated: true, completion: nil)
            return
        }
        
        var selectedImage: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImage = editedImage
        } else if let unalteredImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImage = unalteredImage
        }
        
        if selectedImage != nil {
            saveImageToFB(image: selectedImage!)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
extension RelationshipChatViewController : RelationshipChatCollectionViewCellDelegate {
    
    func imageZoom(imageViewToZoom: UIImageView) {
        
       self.imageViewToZoom = imageViewToZoom
        self.imageViewToZoom?.isHidden = true
       startingZoomFrame = imageViewToZoom.superview?.convert(imageViewToZoom.frame, to: nil)
        
        
        let zoomingIV = UIImageView(frame: startingZoomFrame!)
        zoomingIV.backgroundColor = UIColor.red
        zoomingIV.image = imageViewToZoom.image
        zoomingIV.isUserInteractionEnabled = true
        zoomingIV.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissImageZoom)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            zoomBackgroundView = UIView(frame: keyWindow.frame)
            zoomBackgroundView!.backgroundColor = UIColor.black
            zoomBackgroundView!.alpha = 0
            keyWindow.addSubview(zoomBackgroundView!)
            
            keyWindow.addSubview(zoomingIV)
            
            UIView.animate(withDuration: Constants.ImageZoomAnimationDuration, delay: 0, options: .curveEaseOut, animations: {
                self.zoomBackgroundView!.alpha = 1
                let height = self.startingZoomFrame!.height / self.startingZoomFrame!.width * keyWindow.frame.width
                
                zoomingIV.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingIV.center = keyWindow.center
                
            }, completion: nil)
        }
    }
    
    @objc func dismissImageZoom(tapGesture : UITapGestureRecognizer) {
        if let imageViewToZoomOutOf = tapGesture.view {
            
            imageViewToZoomOutOf.layer.cornerRadius = 16
            imageViewToZoomOutOf.clipsToBounds = true
            
            UIView.animate(withDuration: Constants.ImageZoomAnimationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                imageViewToZoomOutOf.frame = self.startingZoomFrame!
                self.zoomBackgroundView?.alpha = 0.0
            }, completion: { (_) in
                self.zoomBackgroundView?.removeFromSuperview()
                imageViewToZoomOutOf.removeFromSuperview()
                self.imageViewToZoom?.isHidden = false
            })

        }
    }
}
