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
    
    override func configure(#friend: PFUser,myDelegate:ReviewHeaderDelegate) {
        super.configure(friend: friend, myDelegate: myDelegate)
        configurePicture(friend)
        configureName(friend)
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
    }
    
}
