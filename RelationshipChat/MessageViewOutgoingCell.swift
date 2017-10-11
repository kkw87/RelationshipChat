//
//  messageViewOutgoing.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 3/30/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import JSQMessagesViewController

class MessageViewOutgoingCell: JSQMessagesCollectionViewCellOutgoing {

    
    @IBOutlet weak var timeStamp: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.right
        self.cellBottomLabel.textAlignment = NSTextAlignment.right
    }


    override class func nib() -> UINib {
        return UINib(nibName: "MessageViewOutgoingCell", bundle: nil)
    }
    
    override class func cellReuseIdentifier() -> String {
        return "MessageViewOutgoingCell"
    }
    
    override class func mediaCellReuseIdentifier() -> String {
        return "MessageViewOutgoingCell_JSQMedia"
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    

}
