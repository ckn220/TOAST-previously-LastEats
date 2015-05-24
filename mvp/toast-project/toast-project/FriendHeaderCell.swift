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

    @IBOutlet weak var friendPictureButton: ReviewerButton!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var topToastHeightConstraint: NSLayoutConstraint!
    
    override func configure(#friend: PFUser,myDelegate:ReviewHeaderDelegate,isTopToast: Bool) {
        super.configure(friend: friend, myDelegate: myDelegate,isTopToast:isTopToast)
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
        configureReviewerPicture(friendPictureButton.layer)
        if let pictureURL = user["pictureURL"] as? String{
            let cache = Shared.imageCache
            
            cache.fetch(URL: NSURL(string:pictureURL)!, failure: { (error) -> () in
                NSLog("configurePicture error: \(error!.description)")
                }, success: {(image) -> () in
                    self.friendPictureButton.myImage = image
            })
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
