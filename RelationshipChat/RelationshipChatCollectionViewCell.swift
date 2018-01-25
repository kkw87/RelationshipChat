//
//  RelationshipChatCollectionViewCell.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 1/20/18.
//  Copyright © 2018 KKW. All rights reserved.
//

import UIKit
import AVFoundation

protocol RelationshipChatCollectionViewCellDelegate {
    func imageZoom(imageViewToZoom : UIImageView)
}

struct ChatBubbleConstants {
    static let fontSize : CGFloat = 16
    static let bubbleWidth : CGFloat = 200
    static let textviewBubblePaddingPhoneInside : CGFloat = 8
    static let textviewBubblePaddingPhoneOutside : CGFloat = -8
    static let bubbleWidthPadding : CGFloat = 30
    static let chatBubbleCornerRadius : CGFloat = 16
    
    static let PlayButtonWidthHeight : CGFloat = 50
    
    static let imageViewWidthHeight : CGFloat = 32
    static let imageViewCornerRadies : CGFloat = 16
    
    static let OutgoingCellColor = UIColor.flatPurple()
    static let OutgoingCellTextColor = UIColor.white
    static let IncomingCellColor = UIColor(red: 240, green: 240, blue: 240, alpha: 0)
    static let IncomingCellTextColor = UIColor.black
}

class RelationshipChatCollectionViewCell: UICollectionViewCell {
    
    //MARK: - Views
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    lazy var playButton: UIButton = {
       let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let playButtonImage = UIImage(named: "PlayButton")
        button.tintColor = UIColor.white
        button.setImage(playButtonImage, for: .normal)
        button.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
        return button
    }()
    
    let textView : UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: ChatBubbleConstants.fontSize)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = UIColor.clear
        tv.textColor = UIColor.white
        tv.isEditable = false
        return tv
    }()
    
    let bubbleView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.flatPurple()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = ChatBubbleConstants.chatBubbleCornerRadius
        view.layer.masksToBounds = true
        return view
    }()
    
    let imageView : UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "DefaultPicture")
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = ChatBubbleConstants.chatBubbleCornerRadius
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    lazy var messageImageView : UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = ChatBubbleConstants.chatBubbleCornerRadius
        iv.contentMode = .scaleAspectFill
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))
        return iv
    }()
    
    //MARK: - Instance properties
    var delegate : RelationshipChatCollectionViewCellDelegate?
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor : NSLayoutConstraint?
    var bubbleViewLeftAnchor : NSLayoutConstraint?
    var videoURL : URL?
    private var playerLayer : AVPlayerLayer?
    private var player : AVPlayer?
    
    var cellImage : UIImage? {
        get {
            return imageView.image ?? UIImage(named: "DefaultPicture")!
        } set {
            if newValue == nil {
                imageView.image = UIImage(named: "DefaultPicture")!
            } else {
                imageView.image = newValue
            }
        }
    }
    
    private var chatBubbleBackgroundColor : UIColor {
        get {
            return bubbleView.backgroundColor!
        } set {
            bubbleView.backgroundColor = newValue
        }
    }
    
    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bubbleView)
        addSubview(imageView)
        
        bubbleView.addSubview(messageImageView)
        messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true 
        messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        messageImageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
        messageImageView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
        
        bubbleView.addSubview(playButton)
        playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: ChatBubbleConstants.PlayButtonWidthHeight).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: ChatBubbleConstants.PlayButtonWidthHeight).isActive = true
        
        bubbleView.addSubview(activityIndicatorView)
        activityIndicatorView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        activityIndicatorView.widthAnchor.constraint(equalToConstant: ChatBubbleConstants.PlayButtonWidthHeight).isActive = true
        activityIndicatorView.heightAnchor.constraint(equalToConstant: ChatBubbleConstants.PlayButtonWidthHeight).isActive = true
        
        
        imageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: ChatBubbleConstants.textviewBubblePaddingPhoneInside
            ).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: ChatBubbleConstants.imageViewWidthHeight).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: ChatBubbleConstants.imageViewWidthHeight).isActive = true
        
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: ChatBubbleConstants.textviewBubblePaddingPhoneOutside)
        bubbleViewRightAnchor?.isActive = true
        
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: ChatBubbleConstants.textviewBubblePaddingPhoneInside)
        bubbleViewLeftAnchor?.isActive = false
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: ChatBubbleConstants.bubbleWidth)
        bubbleWidthAnchor?.isActive = true
        
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        addSubview(textView)
        
        //        textView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: ChatBubbleConstants.textviewBubblePaddingPhoneInside).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true 
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Cell UI setup functions
    func setupForOutgoingCell() {
        textView.textColor = ChatBubbleConstants.OutgoingCellTextColor
        chatBubbleBackgroundColor = ChatBubbleConstants.OutgoingCellColor!
        bubbleViewRightAnchor?.isActive = true
        bubbleViewLeftAnchor?.isActive = false
        imageView.isHidden = true
        //Check for image
    }
    
    func setupForIncomingCell() {
        imageView.isHidden = false
        chatBubbleBackgroundColor = ChatBubbleConstants.IncomingCellColor
        textView.textColor = ChatBubbleConstants.IncomingCellTextColor
        bubbleViewRightAnchor?.isActive = false
        bubbleViewLeftAnchor?.isActive = true
        
        //Check for image
    }
    
    //MARK: - Selector methods
    @objc func handleZoomTap(gesture : UITapGestureRecognizer) {
        
        if videoURL != nil {
            return
        }
        if let viewToZoom = gesture.view as? UIImageView {
            delegate?.imageZoom(imageViewToZoom: viewToZoom)
        }
    }
    
    @objc func playVideo() {
        if videoURL != nil {
            player = AVPlayer(url: videoURL!)
            
            playerLayer = AVPlayerLayer(player: player!)
            playerLayer?.frame = bubbleView.bounds
            bubbleView.layer.addSublayer(playerLayer!)
            player?.play()
            activityIndicatorView.startAnimating()
            playButton.isHidden = true
        }
    }
    
    //MARK: - Override methods
    override func prepareForReuse() {
        super.prepareForReuse()
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        activityIndicatorView.stopAnimating()
    }
    
}
