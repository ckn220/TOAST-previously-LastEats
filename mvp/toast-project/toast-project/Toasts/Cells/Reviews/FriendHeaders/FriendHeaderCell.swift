//
//  FriendHeaderCell.swift
//  toast-project
//
//  Created by Diego Cruz on 4/29/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

class FriendHeaderCell: ReviewHeaderCell {


    @IBOutlet weak var friendPictureView: BackgroundImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var topToastHeightConstraint: NSLayoutConstraint!
    
    override func configure(friend friend: PFUser,myDelegate:ReviewHeaderDelegate,superView:UIView,isTopToast: Bool) {
        super.configure(friend: friend, myDelegate: myDelegate,superView:superView,isTopToast:isTopToast)
        configureTopToast(isTopToast)
        configurePicture(friend)
        configureName(friend)
    }
    
    private func configureTopToast(isTopToast:Bool){
        if isTopToast{
            topToastHeightConstraint.constant = 22
        }else{
            topToastHeightConstraint.constant = 0
        }
        self.layoutIfNeeded()
    }
    
    private func configurePicture(user:PFUser){
        configureReviewerPicture(friendPictureView.layer)
        friendPictureView.setImage(user: user) { () -> () in
            self.myDelegate?.reviewHeaderDoneLoading()
        }
    }
    
    private func configureName(user:PFUser){
        let name = user["name"] as! String
        friendNameLabel.text = correctedName(name)
        
        if topToastHeightConstraint.constant > 0{
            friendNameLabel.text = friendNameLabel.text!+"'s"
        }
    }
    
}
