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

    @IBOutlet weak var friendFriendPictureView: BackgroundImageView!
    @IBOutlet weak var friendfriendNameLabel: UILabel!
    @IBOutlet weak var friendfriendSubtitleLabel: UILabel!
    @IBOutlet weak var friendPictureView: BackgroundImageView!
    @IBOutlet weak var topToastHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topToastBottomSpacingConstraint: NSLayoutConstraint!
    var friend:PFUser?

    override func configure(#friend: PFUser, friendFriend: PFUser,myDelegate:ReviewHeaderDelegate,superView:UIView,isTopToast: Bool) {
        super.configure(friend: friend, friendFriend: friendFriend, myDelegate: myDelegate,superView:superView,isTopToast: isTopToast)
        configureTopToast(isTopToast)
        configureFriend(friend)
        configureFriendofFriend(friendFriend)
    }
    
    private func configureTopToast(isTopToast:Bool){
        if isTopToast{
            topToastHeightConstraint.constant = 22
            subtitleHeightConstraint.constant = 17
            topToastBottomSpacingConstraint.constant = 4
        }else{
            topToastHeightConstraint.constant = 0
            topToastBottomSpacingConstraint.constant = 0
            subtitleHeightConstraint.constant = 34
        }
        self.layoutIfNeeded()
    }

    private func configureFriend(friend:PFUser){
        self.friend = friend
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
            friendPictureView.setImage(URL: pictureURL)
        }
    }
    
    private func configureFriendName(friend:PFUser){
        let name = friend["name"] as! String
        friendfriendSubtitleLabel.text = "Friends with \(correctedName(name))\r\non Facebook"
    }
    
    //MARK: - Friend of friend methods
    private func configureFriendOfFriendPicture(friendFriend:PFUser){
        configureReviewerPicture(friendFriendPictureView.layer)
        if let pictureURL = friendFriend["pictureURL"] as? String{
            self.friendFriendPictureView.setImage(URL: pictureURL, completion: { () -> Void in
                self.myDelegate?.reviewHeaderDoneLoading()
            })
        }
    }

    private func configureFriendOfFriendName(friendFriend:PFUser){
        let name = friendFriend["name"] as! String
        friendfriendNameLabel.text = correctedName(name)
        
        if topToastHeightConstraint.constant > 0{
            friendfriendNameLabel.text = friendfriendNameLabel.text!+"'s"
        }
    }
    
    override func reviewerButtonPressed(sender: ReviewerButton) {
        myDelegate?.friendPicturePressed(friend)
    }
}
