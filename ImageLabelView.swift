//
//  ImageLabelView.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 6/26/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import UIKit

class ImagelabelView: UIView{
    
    //MARK : - Constants
    struct Constants {
        
        static let topPadding:CGFloat = 10.0
        static let height:CGFloat = 18.0
    }
    
    //MARK : - Instance Properties
    var imageView: UIImageView!
    var label: UILabel!
    
    //MARK : - Init methods
    override init(frame: CGRect){
        super.init(frame: frame)
        imageView = UIImageView()
        label = UILabel()
    }
    
    init(frame: CGRect, image: UIImage, text: String) {
        
        super.init(frame: frame)
        constructImageView(image: image)
        constructLabel(text: text)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    //MARK : - Class Methods
    func constructImageView(image:UIImage) -> Void{
        
        let framex = CGRect(x: (self.bounds.width - image.size.width * 1.95), y: Constants.topPadding, width: image.size.width, height: image.size.height)

        imageView = UIImageView(frame: framex)
        imageView.image = image
        addSubview(self.imageView)
    }
    
    func constructLabel(text:String) -> Void{
        let frame2 = CGRect(x: 0, y: self.imageView.frame.maxY, width: self.bounds.width, height: Constants.height)
            
        self.label = UILabel(frame: frame2)
        label.text = text
        addSubview(label)
        
    }
}
