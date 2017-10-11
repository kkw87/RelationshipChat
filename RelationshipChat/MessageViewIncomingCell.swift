//
//  messageViewIncoming.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 3/30/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import JSQMessagesViewController

class MessageViewIncomingCell: JSQMessagesCollectionViewCellIncoming {
    
    
    @IBOutlet weak var timeStamp: UILabel!
 
    override func awakeFromNib() {
        super.awakeFromNib()
        self.messageBubbleTopLabel.textAlignment = NSTextAlignment.left
        self.cellBottomLabel.textAlignment = NSTextAlignment.left
    }

    
    override class func nib() -> UINib {
        return UINib(nibName: "MessageViewIncomingCell", bundle: nil)
    }
    
    override class func cellReuseIdentifier() -> String {
        return "MessageViewIncomingCell"
    }
    
    override class func mediaCellReuseIdentifier() -> String {
        return "MessageViewIncomingCell_JSQMedia"
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
