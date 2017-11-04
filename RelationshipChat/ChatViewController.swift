//
//  ChatViewController.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 9/12/16.
//  Copyright © 2016 KKW. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import JSQMessagesViewController
import Photos

@available(iOS 10.0, *)
class ChatViewController: JSQMessagesViewController, UINavigationControllerDelegate, JSQMessagesComposerTextViewPasteDelegate {
    
    
    //MARK: - Constants
    
    struct Constants {
        static let DefaultTitle = ""
        static let DefaultSenderID = "1"
        static let DefaultSenderDisplayName = " "
        static let DeliveredFooterMessage = NSAttributedString(string: "Delivered")
        static let RelationshipDeletedTitle = "Your relationship was ended"
        static let RelationshipDeletedBody = "You are no longer in a relationship!"
        static let NewRelationshipAlertButton = "Find a new relationship"
        static let AlertCancelButton = "Cancel"
        
        static let ChatProfilePictureHeight = CGFloat(40)
        static let ChatProfilePictureWidth = CGFloat(40)
        
        static let OutgoingChatTextColor = UIColor.white    //ContrastingColor
        static let IncomingChatTextColor = UIColor.black   //Contrasting color
        
        static let SendButtonColor = UIColor.white
    }
    
    struct Storyboard {
        static let RelationshipConfirmationSegueID = "Relationship Confirmation Segue"
        static let NewRelationshipSegue = "New Relationship Segue"
    }
    
    
    //MARK: - Relationship request variables
    fileprivate var sendersRecord : CKRecord?
    fileprivate var requestedRelationship : CKRecord?
    fileprivate var relationshipRequestID : CKRecordID?
    
    //MARK: - Instance Variables
    
    private var chatBarBadgeValue : Int? {
        get {
            guard let badgeValue = self.tabBarController?.chatBarItem?.badgeValue else {
                return nil
            }
            
            return Int(badgeValue)
        } set {
            
            guard newValue != nil else {
                self.tabBarController?.chatBarItem?.badgeValue = nil
                return
            }
            
            self.tabBarController?.chatBarItem?.badgeValue = String(describing: newValue)
        }
    }
    
    //Settings for JSQMessages VC
    private let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    private let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.flatPurple())
    
    
    private var messages = [JSQMessage]()
    
    //User typing indicator variables
    var currentRelationship : CKRecord? {
        didSet {
            if currentRelationship != nil {
                fetchNewMessages()
                pullMessagesFromRelationship(currentRelationship!.recordID.recordName)
                
            } else {
                tabBarController?.chatBarItem?.isEnabled = false
                secondaryUser = nil
                performSegue(withIdentifier: Storyboard.NewRelationshipSegue, sender: nil)
            }
        }
    }
    
    var currentUser : CKRecord? {
        didSet {
            if currentUser != nil {
                let userInformation = Cloud.pullUserInformationFrom(usersRecordToLoad: currentUser!)
                senderId = currentUser!.recordID.recordName
                senderDisplayName = userInformation.usersFullName
            }
        }
    }
    
    var secondaryUser : CKRecord? {
        didSet {
            if secondaryUser != nil {
                let userInformation = Cloud.pullUserInformationFrom(usersRecordToLoad: secondaryUser!)
                navigationItem.title = userInformation.usersFullName
            } else {
                navigationItem.title = "No Relationship"
            }
        }
    }
    
    private var lastSentMessage : JSQMessage?
    
    fileprivate var userIsTyping = false {
        didSet {
            let typingStatus = userIsTyping ? Cloud.UserTypingStatus.Typing : Cloud.UserTypingStatus.DoneTyping
            
            let typingIndicator = CKRecord(recordType: Cloud.Entity.UserTypingIndicator)
            typingIndicator[Cloud.UserTypingIndicatorAttributes.Relationship] = CKReference(record: currentRelationship!, action: .deleteSelf)
            typingIndicator[Cloud.UserTypingIndicatorAttributes.TypingStatus] = typingStatus as CKRecordValue?
            typingIndicator[Cloud.RecordKeys.RecordType] = Cloud.Entity.UserTypingIndicator as CKRecordValue?
            
            Cloud.CloudDatabase.PublicDatabase.save(typingIndicator) { (savedRecord, error) in
                if error != nil {
                    _ = Cloud.errorHandling(error!, sendingViewController: nil)
                }
            }
        }
    }
    
    //MARK: - VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCustomDisplayCells()
        loadUserInformation()
        addNotificationObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    //MARK: - Setup Methods
    fileprivate func setupUI() {
        tabBarController?.tabBar.isTranslucent = false
        //Set default senderID and displayname for JSQMessagesVC so it does not crash
        self.senderId = Constants.DefaultSenderID
        self.senderDisplayName = Constants.DefaultSenderDisplayName
        
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: Constants.ChatProfilePictureWidth, height: Constants.ChatProfilePictureHeight)
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: Constants.ChatProfilePictureWidth, height: Constants.ChatProfilePictureHeight)
        
        self.inputToolbar.contentView.leftBarButtonItem = nil;
        
        //TODO, implement photo sharing capabilities
    }
    
    fileprivate func setupCustomDisplayCells() {
        self.outgoingCellIdentifier = MessageViewOutgoingCell.cellReuseIdentifier()
        self.outgoingMediaCellIdentifier = MessageViewOutgoingCell.mediaCellReuseIdentifier()
        
        self.incomingCellIdentifier = MessageViewIncomingCell.cellReuseIdentifier()
        self.incomingMediaCellIdentifier = MessageViewIncomingCell.mediaCellReuseIdentifier()
        
        
        self.collectionView.register(MessageViewOutgoingCell.nib(), forCellWithReuseIdentifier: self.outgoingCellIdentifier)
        self.collectionView.register(MessageViewOutgoingCell.nib(), forCellWithReuseIdentifier: self.outgoingMediaCellIdentifier)
        
        
        self.collectionView.register(MessageViewIncomingCell.nib(), forCellWithReuseIdentifier: self.incomingCellIdentifier)
        self.collectionView.register(MessageViewIncomingCell.nib(), forCellWithReuseIdentifier: self.incomingMediaCellIdentifier)
    }
    
    
    //MARK: - Class Methods
    
    fileprivate func fetchNewMessages() {
        
        let messageSearchPredicate = NSPredicate(format: "relationship = %@", self.currentRelationship!)
        let messageFetchQuery = CKQuery(recordType: Cloud.Entity.Message, predicate: messageSearchPredicate)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        Cloud.CloudDatabase.PublicDatabase.perform(messageFetchQuery, inZoneWith: nil) { [weak self] (newMessages, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: self)
                print("error fetching new messages, chat vc")
                return
            }
            
            for newMessage in newMessages! {
                self?.saveCloudMessageToCoreData(newMessage)
            }
            
            //TODO, will be depracated
            let resetContainerBadgeCountOp = CKModifyBadgeOperation(badgeValue: 0)
            resetContainerBadgeCountOp.completionBlock = {
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    self?.chatBarBadgeValue = nil
                }
            }
            CKContainer.default().add(resetContainerBadgeCountOp)
            
        }
    }
    
    fileprivate func loadUserInformation() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        CKContainer.default().fetchUserRecordID { (userRecordID, error) in
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: nil)
                return
            }
            
            let predicate = NSPredicate(format: "creatorUserRecordID = %@", userRecordID!)
            let query = CKQuery(recordType: Cloud.Entity.User, predicate: predicate)
            
            Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: { [weak self] (fetchedRecords, error) in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: nil)
                    return
                }
                
                
                if let currentUserRecord = fetchedRecords?.first {
                    DispatchQueue.main.async {
                        self?.currentUser = currentUserRecord
                    }
                    self?.loadRelationship(fromUserRecord: currentUserRecord)
                }
                
            })
            
            
        }
    }
    
    fileprivate func loadRelationship(fromUserRecord : CKRecord?) {
        
        if let relationshipReference = fromUserRecord?[Cloud.UserAttribute.Relationship] as? CKReference {
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: relationshipReference.recordID, completionHandler: { [weak self] (fetchedRelationship, error) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    return
                }
                
                guard fetchedRelationship != nil else {
                    DispatchQueue.main.async {
                        self?.currentRelationship = nil
                        self?.performSegue(withIdentifier: Storyboard.NewRelationshipSegue, sender: nil)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.currentRelationship = fetchedRelationship!
                }
                self?.loadSecondaryUser(fromRelationship: fetchedRelationship!)
                
                
            })
            
        }
    }
    
    fileprivate func loadSecondaryUser(fromRelationship : CKRecord) {
        if let otherUsersRecordID = ((fromRelationship[Cloud.RelationshipAttribute.Users] as? [CKReference])?.filter { $0.recordID != self.currentUser?.recordID })?.first?.recordID  {
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: otherUsersRecordID, completionHandler: { [weak self](fetchedUserRecord, error) in
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard error == nil else {
                    _ = Cloud.errorHandling(error!, sendingViewController: self)
                    return
                }
                
                if fetchedUserRecord != nil {
                    DispatchQueue.main.async {
                        self?.secondaryUser = fetchedUserRecord
                    }
                }
                
            })
            
        }
    }
    
    fileprivate func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.RelationshipRequestChannel, object: nil, queue: nil) { (notification) in
            
            if let relationshipRequest = notification.userInfo?[CloudKitNotifications.RelationshipRequestKey] as? CKQueryNotification {
                
                let predicate = NSPredicate(format: "to = %@", self.currentUser!)
                let query = CKQuery(recordType: Cloud.Entity.RelationshipRequest, predicate: predicate)
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                Cloud.CloudDatabase.PublicDatabase.perform(query, inZoneWith: nil, completionHandler: { [weak self] (fetchedRecords, error) in
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    
                    if error != nil {
                        DispatchQueue.main.async {
                            _ = Cloud.errorHandling(error!, sendingViewController: self)
                        }
                    } else if let relationshipRequestRecord = fetchedRecords?.first {
                        
                        let requestSender = relationshipRequestRecord[Cloud.RelationshipRequestAttribute.Sender] as! CKReference
                        let requestRelationship = relationshipRequestRecord[Cloud.RelationshipRequestAttribute.Relationship] as! CKReference
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                        
                        Cloud.pullRelationshipRequest(fromSender: requestSender.recordID, relationshipRecordID: requestRelationship.recordID, relationshipRequestID: relationshipRequest.recordID!, presentingVC: self) {(sendingUsersRecord, requestedRelationshipRecord) in
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            DispatchQueue.main.async {
                                
                                self?.sendersRecord = sendingUsersRecord
                                self?.requestedRelationship = requestedRelationshipRecord
                                self?.relationshipRequestID = relationshipRequest.recordID!
                                self?.navigationController?.popToRootViewController(animated: true)
                                self?.performSegue(withIdentifier: Storyboard.RelationshipConfirmationSegueID, sender: nil)
                                
                            }
                            
                        }
                    }
                })
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.CurrentUserRecordUpdateChannel, object: nil, queue: nil) { [weak self](notification) in
            if let updatedUserRecord = notification.userInfo?[CloudKitNotifications.CurrentUserRecordUpdateKey] as? CKRecord {
                DispatchQueue.main.async {
                    self?.currentUser = updatedUserRecord
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.RelationshipUpdateChannel, object: nil, queue: nil) { [weak self] (notification) in
            if let updatedRelationshipRecord = notification.userInfo?[CloudKitNotifications.RelationshipUpdateKey] as? CKQueryNotification {
                Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: updatedRelationshipRecord.recordID!, completionHandler: {(newRelationshipRecord, error) in
                    guard error == nil else {
                        _ = Cloud.errorHandling(error!, sendingViewController: nil)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.currentRelationship = newRelationshipRecord!
                    }
                    
                })
            } else if let updatedRelationship = notification.userInfo?[CloudKitNotifications.RelationshipUpdateKey] as? CKRecord {
                DispatchQueue.main.async {
                    self?.currentRelationship = updatedRelationship
                }
            } else {
                self?.displayAlertWithTitle("You are no longer in a relationship", withBodyMessage: "Your relationship has ended", withBlock: nil)
                self?.currentRelationship = nil
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.SecondaryUserUpdateChannel, object: nil, queue: nil) { [weak self] (notification) in
            if let updatedSecondaryUser = notification.userInfo?[CloudKitNotifications.SecondaryUserUpdateKey] as? CKQueryNotification {
                Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: updatedSecondaryUser.recordID!, completionHandler: { (newSecondaryUserRecord, error) in
                    
                    guard error == nil else {
                        _ = Cloud.errorHandling(error!, sendingViewController: self)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.secondaryUser = newSecondaryUserRecord!
                    }
                    
                })
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.MessageChannel, object: nil, queue: nil) { [weak self] (notification) in
            if let newMessage = notification.userInfo?[CloudKitNotifications.MessagKey] as? CKQueryNotification {
                self?.addMessageFromNotification(newMessage.recordID!)
            }
        }
        
        NotificationCenter.default.addObserver(forName: CloudKitNotifications.TypingIndicatorChannel, object: nil, queue: nil) { [weak self] (notification) in
            
            //Make sure self is on screen
            
            guard self?.view.window != nil, let typingUpdate = notification.userInfo?[CloudKitNotifications.TypingChannelKey] as? CKQueryNotification, let typing = typingUpdate.recordFields?[Cloud.UserTypingIndicatorAttributes.TypingStatus] as? String  else {
                return
            }
            
            DispatchQueue.main.async {
                switch typing {
                case Cloud.UserTypingStatus.Typing:
                    self?.showTypingIndicator = true
                    self?.scrollToBottom(animated: true)
                default:
                    self?.showTypingIndicator = false
                    self?.scrollToBottom(animated: true)
                }
            }
            
            if self?.currentRelationship != nil {
                Cloud.deleteTypingIndicatorsFrom((self?.currentRelationship)!)
            }
            
            
        }
        
    }
    
    private func firstMessageOfTheDay(indexOfMessage: IndexPath) -> Bool {
        if indexOfMessage.row >= 1 {
            let messageDate = messages[indexOfMessage.row].date
            guard let previousMessageDate = messages[indexOfMessage.row - 1].date else {
                return true
            }
            let calendar = Calendar.current
            let day = calendar.component(.day, from: messageDate!)
            let previousMessageDay = calendar.component(.day, from: previousMessageDate)
            if day == previousMessageDay {
                return false
            } else {
                return true
            }
        }
        return true
    }
    
    //MARK: - Text View Delegate
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        if !userIsTyping && !textView.text.isEmpty {
            userIsTyping = true
        }
        //Updating typing status
        if userIsTyping && textView.text.isEmpty {
            userIsTyping = false
        }
        
    }
    //MARK: - JSQMessages Methods
    
    //Responding to the "Send" button
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        if currentRelationship != nil {
            if let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text) {
                self.messages.append(message)
                JSQSystemSoundPlayer.jsq_playMessageSentSound()
                self.saveMessage(message)
                
                DispatchQueue.main.async {
                    self.userIsTyping = false
                    self.finishSendingMessage()
                }
            }
        } else {
            displayAlertWithTitle("You are not in a relationship", withBodyMessage: "It seems you are not in a relationship", withBlock: nil)
        }
        
    }
    
    //Number of Messages
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        let data = self.messages[indexPath.row]
        return data
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        messages.remove(at: indexPath.row)
    }
    
    //Message "bubble" data for array index
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        switch data.senderId {
        case self.senderId:
            return self.outgoingBubble
        default:
            return self.incomingBubble
        }
    }
    
    //Message avatar image for array index
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let data = messages[indexPath.row]
        let senderID = data.senderId
        
        let defaultUserPicture = UIImage(named: "DefaultPicture")
        
        if let userImage = RCCache.shared[senderID as AnyObject] {
            return JSQMessagesAvatarImage(avatarImage: userImage, highlightedImage: userImage, placeholderImage: defaultUserPicture)
        } else {
            
            var recordIDToFetch : CKRecordID?
            
            if data.senderId == currentUser?.recordID.recordName {
                recordIDToFetch = currentUser?.recordID
            } else {
                recordIDToFetch = secondaryUser?.recordID
            }
            
            
            if recordIDToFetch != nil {
                
                Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: recordIDToFetch!, completionHandler: { (fetchedRecord, error) in
                    guard error == nil else {
                        _ = Cloud.errorHandling(error!, sendingViewController: self)
                        return
                    }
                    
                    guard let usersRecord = fetchedRecord, let imageAsset = usersRecord[Cloud.UserAttribute.ProfileImage] as? CKAsset, let convertedImage = imageAsset.convertToImage() else {
                        return
                    }
                    
                    RCCache.shared[senderID as AnyObject] = convertedImage
                })
            }
        }
        
        return JSQMessagesAvatarImage(avatarImage: defaultUserPicture, highlightedImage: defaultUserPicture, placeholderImage: defaultUserPicture)
    }
    
    //Bubble height
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        let data = self.collectionView(collectionView, messageDataForItemAt: indexPath)
        if (self.senderDisplayName == data?.senderDisplayName()) {
            return 0.0
        }
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        if firstMessageOfTheDay(indexOfMessage: indexPath) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        
        let message = self.messages[indexPath.item]
        if message == self.lastSentMessage {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0
    }
    
    
    //Set text color for bubbles
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        
        
        let message = self.messages[indexPath.item]
        if message.senderId == self.senderId {
            let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! MessageViewOutgoingCell
            cell.textView?.textColor = Constants.OutgoingChatTextColor
            cell.timeStamp.text = dateFormatter.string(from: message.date)
            return cell
        } else {
            let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! MessageViewIncomingCell
            cell.textView.textColor = Constants.IncomingChatTextColor
            cell.timeStamp.text = dateFormatter.string(from: message.date)
            return cell
        }
        
    }
    
    //Text for delivered message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return Constants.DeliveredFooterMessage
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        var stringToReturn = NSAttributedString(string: "")
        
        let messageDate = messages[indexPath.row].date!
        let currentCalendar = Calendar.current
        
        let monthDayYearFormatter = DateFormatter()
        monthDayYearFormatter.dateFormat = "MMMM d, yyyy"
        let currentDate = monthDayYearFormatter.string(from: messageDate)
        
        
        if currentCalendar.isDateInToday(messageDate) {
            stringToReturn = NSAttributedString(string: "Today")
        } else {
            stringToReturn = NSAttributedString(string: "\(currentDate)")
        }
        
        return stringToReturn
    }
    
    
    
    //Image selecion
    //    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
    //        //Perform segue showing stats about user?
    //    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        //Show camera
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picturePicker = UIImagePickerController()
            picturePicker.delegate = self
            picturePicker.sourceType = .photoLibrary
            picturePicker.allowsEditing = true
            self.present(picturePicker, animated: true, completion: nil)
        }
    }
    
    
    func composerTextView(_ textView: JSQMessagesComposerTextView!, shouldPasteWithSender sender: Any!) -> Bool {
        
        //Check if there is an image in the paste board
        if let pasteboardImage = UIPasteboard.general.image {
            let imageItem = JSQPhotoMediaItem(image: pasteboardImage)
            if let imageMessage = JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: imageItem) {
                self.messages.append(imageMessage)
                self.saveMessage(imageMessage)
                self.finishSendingMessage()
                
                return false
            }
            return true
        }
        return true
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case Storyboard.NewRelationshipSegue :
            if let nrvc = (segue.destination as? UINavigationController)?.visibleViewController as? NewRelationshipViewController {
                nrvc.userRecord = currentUser
            }
        case Storyboard.RelationshipConfirmationSegueID :
            if let rvc = segue.destination as? RelationshipConfirmationViewController {
                rvc.relationship = requestedRelationship
                rvc.sendersRecord = sendersRecord
                rvc.usersRecord = currentUser
            }
        default :
            break
        }
    }
    
}

//MARK: - Image picker delegate

@available(iOS 10.0, *)
extension ChatViewController : UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let imageInfo = picker.savePickedImageLocally(info)
        let image = imageInfo.image
        
        let mediaItem = JSQPhotoMediaItem(image: image)
        mediaItem?.appliesMediaViewMaskAsOutgoing = true
        self.dismiss(animated: true, completion: nil)
        //mediaItem?.image = UIImage(data: UIImageJPEGRepresentation(image, 0.5)!)
        let mediaMessage = JSQMessage(senderId: senderId, displayName: senderDisplayName, media: mediaItem)
        self.saveMessage(mediaMessage!)
        self.messages.append(mediaMessage!)
        self.finishSendingMessage()
    }
    
}

//MARK: - Chat View Controller extensions
@available(iOS 10.0, *)
extension ChatViewController {
    
    
    func addMessageFromNotification(_ messageID : CKRecordID) {
        
        Cloud.CloudDatabase.PublicDatabase.fetch(withRecordID: messageID) { (messageRecord, error) in
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: self)
                print("error fetching message from cloud")
                return
            }
            
            if messageRecord != nil {
                DispatchQueue.main.async {
                    self.saveCloudMessageToCoreData(messageRecord!)
                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    self.finishReceivingMessage()
                    
                    
                    Cloud.CloudDatabase.PublicDatabase.delete(withRecordID: messageRecord!.recordID, completionHandler: { (_, error) in
                        if error != nil {
                            _ = Cloud.errorHandling(error!, sendingViewController: self)
                        }
                    })
                    
                }
            }
            
        }
    }
    
    func pullMessagesFromRelationship(_ relationshipRecordName : String)  {
        
        let messageRequest : NSFetchRequest<Message> = Message.fetchRequest()
        messageRequest.predicate = NSPredicate(format: "relationship = %@", relationshipRecordName)
        messageRequest.sortDescriptors = [NSSortDescriptor(key: Message.AttributeNames.Relationship, ascending: true)]
        
        CoreDataDB.Context.perform {
            if let fetchedMessages = try? CoreDataDB.Context.fetch(messageRequest) {
                
                var relationshipMessages = [JSQMessage]()
                
                for coreDBMessage in fetchedMessages {
                    let jSQMessageFromCloud = self.convertCoreDBMessageToJSQ(coreDBMessage)
                    if jSQMessageFromCloud.senderId == self.senderId {
                        self.lastSentMessage = jSQMessageFromCloud
                    }
                    relationshipMessages.append(jSQMessageFromCloud)
                }
                
                relationshipMessages.sort {
                    $0.date < $1.date
                }
                
                DispatchQueue.main.async {
                    self.messages = relationshipMessages
                    self.finishReceivingMessage()
                }
            }
        }
    }
    
    
    
    //Send message to the cloud
    func saveMessage(_ message : JSQMessage) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let iCloudMessage = CKRecord(recordType: Cloud.Entity.Message)
        iCloudMessage[Cloud.MessageAttribute.Relationship] = CKReference(record: self.currentRelationship!, action: .deleteSelf)
        iCloudMessage[Cloud.MessageAttribute.SenderDisplayName] = message.senderDisplayName as CKRecordValue?
        iCloudMessage[Cloud.MessageAttribute.Text] = message.text as CKRecordValue?
        iCloudMessage[Cloud.RecordKeys.RecordType] = Cloud.Entity.Message as CKRecordValue?
        iCloudMessage[Cloud.MessageAttribute.SenderID] = message.senderId as CKRecordValue?
        
        if message.media != nil {
            //Set the Asset for the cloud
            if let photo = message.media as? JSQPhotoMediaItem {
                iCloudMessage[Cloud.MessageAttribute.Media] = photo.image.convertedToCKAsset()
            }
        }
        Cloud.CloudDatabase.PublicDatabase.save(iCloudMessage, completionHandler: { [weak weakSelf = self](savedMessage, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard error == nil else {
                _ = Cloud.errorHandling(error!, sendingViewController: self)
                return
            }
            
            DispatchQueue.main.async {
                weakSelf?.lastSentMessage = message
                weakSelf?.collectionView.reloadData()
            }
            
        })
        saveJSQMessageToCoreData(message)
    }
    
    //Change a downloaded CKRecord message to JSQMessage
    func convertCloudMessageToJSQMessage(_ message : CKRecord) -> JSQMessage {
        
        let bodyMessage = message[Cloud.MessageAttribute.Text] as? String
        let displayName = message[Cloud.MessageAttribute.SenderDisplayName] as? String
        let senderID = message[Cloud.MessageAttribute.SenderID] as? String
        let mediaItem = message[Cloud.MessageAttribute.Media] as? CKAsset
        
        if let messageMediaPhoto = mediaItem?.convertToImage() {
            let photoInJSQForm = JSQPhotoMediaItem(image: messageMediaPhoto)
            return JSQMessage(senderId: senderID, senderDisplayName: displayName, date: message.creationDate, media: photoInJSQForm)
        }
        
        return JSQMessage(senderId: senderID, senderDisplayName: displayName!, date: message.creationDate, text: bodyMessage!)
    }
    
    func saveCloudMessageToCoreData(_ message : CKRecord) {
        
        //newMessage needs to be added to the message array
        
        let bodyMessage = message[Cloud.MessageAttribute.Text] as? String
        let displayName = message[Cloud.MessageAttribute.SenderDisplayName] as? String
        let senderID = message[Cloud.MessageAttribute.SenderID] as? String
        let mediaItem = message[Cloud.MessageAttribute.Media] as? CKAsset
        
        let newMessage = Message(context: CoreDataDB.Context)
        newMessage.created = message.creationDate!
        newMessage.senderID = senderID
        newMessage.text = bodyMessage
        newMessage.senderDisplayName = displayName
        newMessage.relationship = currentRelationship?.recordID.recordName
        newMessage.recordName = message.recordID.recordName
        
        let messageRequest : NSFetchRequest<Message> = Message.fetchRequest()
        messageRequest.predicate = NSPredicate(format : "recordName = %@", message.recordID.recordName)
        
        CoreDataDB.Context.perform {
            
            guard let _ = (try? CoreDataDB.Context.fetch(messageRequest))?.isEmpty else {
                return
            }
            
            if let messageMediaPhoto = mediaItem?.convertToImage() {
                newMessage.media = UIImagePNGRepresentation(messageMediaPhoto)!
            }
            
            do {
                try CoreDataDB.Context.save()
                Cloud.CloudDatabase.PublicDatabase.delete(withRecordID: message.recordID, completionHandler: { [weak self] (deletedRecordID, error) in
                    guard error == nil else {
                        _ = Cloud.errorHandling(error!, sendingViewController: self)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.messages.append(self!.convertCoreDBMessageToJSQ(newMessage))
                        self?.finishReceivingMessage()
                    }
                    
                })
            } catch {
                print(error)
            }
        }
    }
    
    func saveJSQMessageToCoreData(_ message : JSQMessage) {
        
        let newMessage = Message(context: CoreDataDB.Context)
        newMessage.created = message.date
        newMessage.senderID = message.senderId
        newMessage.text = message.text
        newMessage.senderDisplayName = message.senderDisplayName
        newMessage.relationship = currentRelationship?.recordID.recordName
        
        CoreDataDB.Container.performBackgroundTask {_ in 
            try? CoreDataDB.Context.save()
        }
        
    }
    
    func convertCoreDBMessageToJSQ(_ message : Message) -> JSQMessage {
        
        let messageSenderID = message.senderID!
        let displayName = message.senderDisplayName!
        let creationDate = message.created! as Date
        let mainMessage = message.text!
        
        if let messageImage = message.media {
            if let JSQData = JSQPhotoMediaItem(image: UIImage(data: messageImage)) {
                return JSQMessage(senderId: messageSenderID, senderDisplayName: displayName, date: creationDate, media: JSQData)
            }
        }
        
        return JSQMessage(senderId: messageSenderID, senderDisplayName: displayName, date: creationDate, text: mainMessage)
    }
    
    func convertICloudMessageArrayToJSQMessages(_ messages : [CKRecord]){
        for message in messages {
            self.messages.append(self.convertCloudMessageToJSQMessage(message))
        }
    }
}




