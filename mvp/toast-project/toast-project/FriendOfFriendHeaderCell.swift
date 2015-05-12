//
//  FriendOfFriendHeaderCell.swift
//  toast-project
//
//  Created by Diego Cruz on 4/29/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

class FriendOfFriendHeaderCell: ReviewHeaderCell {

    @IBOutlet weak var friendFriendPictureButton: ReviewerButton!
    @IBOutlet weak var friendfriendNameLabel: UILabel!
    @IBOutlet weak var friendfriendSubtitleLabel: UILabel!
    @IBOutlet weak var friendPictureView: BackgroundImageView!

    override func configure(#friend: PFUser, friendFriend: PFUser,myDelegate:ReviewHeaderDelegate) {
        super.configure(friend: friend, friendFriend: friendFriend, myDelegate: myDelegate)
        configureFriend(friend)
        configureFriendofFriend(friendFriend)
    }

    private func configureFriend(friend:PFUser){
        configureFriendPicture(friend)
        configureFriendName(friend)
    }
    
    private func configureFriendofFriend(friendFriend:PFUser){
        configureFriendOfFriendPicture(friendFriend)
        configureFriendOfFriendName(friendFriend)
    }
    
    //MARK: - Friend methods
    private func configureFriendPicture(friend:PFUser){
        configureReviewerPicture(friendPictureView.layer)
        if let pictureURL = friend["pictureURL"] as? String{
            let cache = Shared.imageCache
            
            cache.fetch(URL: NSURL(string:pictureURL)!, failure: { (error) -> () in
                NSLog("configurePicture error: \(error!.description)")
                }, success: {(image) -> () in
                    self.friendPictureView.myImage = image
            })
        }
    }
    
    private func configureFriendName(friend:PFUser){
        let name = friend["name"] as! String
        friendfriendSubtitleLabel.text = "Friends with\r\n\(correctedName(name)) on Facebook"
    }
    
    //MARK: - Friend of friend methods
    private func configureFriendOfFriendPicture(friendFriend:PFUser){
        configureReviewerPicture(friendFriendPictureButton.layer)
        if let pictureURL = friendFriend["pictureURL"] as? String{
            let cache = Shared.imageCache
            
            cache.fetch(URL: NSURL(string:pictureURL)!, failure: { (error) -> () in
                NSLog("configurePicture error: \(error!.description)")
                }, success: {(image) -> () in
                    self.friendFriendPictureButton.myImage = image
            })
        }
    }

    private func configureFriendOfFriendName(friendFriend:PFUser){
        let name = friendFriend["name"] as! String
        friendfriendNameLabel.text = correctedName(name)
    }
}
