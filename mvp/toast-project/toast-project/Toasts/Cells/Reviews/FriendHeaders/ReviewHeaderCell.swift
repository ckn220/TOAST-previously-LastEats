//
//  ReviewHeaderCell.swift
//  toast-project
//
//  Created by Diego Cruz on 4/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol ReviewHeaderDelegate{
    func friendPicturePressed(ffriend:PFUser?)
    func reviewHeaderDoneLoading()
}

class ReviewHeaderCell: UITableViewCell {

    var myDelegate:ReviewHeaderDelegate?
    
    func configure(#friend:PFUser,myDelegate:ReviewHeaderDelegate,superView:UIView,isTopToast: Bool){
        self.frame = superView.bounds
        //superView.addSubview(self)
        self.myDelegate = myDelegate
    }
    
    func configure(#friend:PFUser,friendFriend:PFUser,myDelegate:ReviewHeaderDelegate,superView:UIView,isTopToast: Bool){
        self.frame = superView.bounds
        self.myDelegate = myDelegate
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureReviewerPicture(pictureLayer:CALayer){
        pictureLayer.cornerRadius = CGRectGetWidth(pictureLayer.bounds)/2.0
        pictureLayer.borderWidth = 1
        pictureLayer.borderColor = UIColor(white: 1, alpha: 0.7).CGColor
        //pictureLayer.shouldRasterize = true
    }
    
    func correctedName(name:String)->String{
        let originalCount = count(name)
        let limit = 14
        if originalCount > limit{
            var words = name.componentsSeparatedByString(" ")
            let newLastName = (words[1] as NSString).substringToIndex(1)
            return "\(words[0]) \(newLastName)."
        }else{
            return name
        }
    }
    
    //MARK: - Action methods
    @IBAction func reviewerButtonPressed(sender: ReviewerButton) {
        myDelegate?.friendPicturePressed(nil)
    }
}
