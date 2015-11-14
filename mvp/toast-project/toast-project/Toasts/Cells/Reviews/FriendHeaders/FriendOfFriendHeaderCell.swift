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
    //MARK: - Properties
    //MARK: IBOutlets
    @IBOutlet weak var friendFriendPictureView: BackgroundImageView!
    @IBOutlet weak var friendfriendNameLabel: UILabel!
    @IBOutlet weak var friendfriendSubtitleLabel: UILabel!
    @IBOutlet weak var friendPictureView: BackgroundImageView!
    @IBOutlet weak var topToastView: UIView!
    var friend:PFUser?
    //MARK: Variables
    var isTopToast:Bool? = false

    //MARK: - AwakeFromNib methods
    override func awakeFromNib() {
        super.awakeFromNib()
        configureReviewerPicture(friendPictureView.layer)
        configureReviewerPicture(friendFriendPictureView.layer)
    }
    
    //MARK: - Configure methods
    override func configure(friend friend: PFUser, friendFriend: PFUser,myDelegate:ReviewHeaderDelegate,superView:UIView,isTopToast: Bool) {
        super.configure(friend: friend, friendFriend: friendFriend, myDelegate: myDelegate,superView:superView,isTopToast: isTopToast)
        configureTopToast(isTopToast)
        configureFriend(friend)
        configureFriendofFriend(friendFriend)
    }
    
    private func configureTopToast(isTopToast:Bool){
        func insertTopToast(){
            if topToastView.superview == nil{
                let parent = friendfriendNameLabel.superview!
                parent.addSubview(topToastView)
                let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[topToast]", options: [], metrics: nil, views: ["topToast":topToastView])
                let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("[name]-4.0-[topToast]-4.0-[description]", options: [], metrics: nil, views: ["name":friendfriendNameLabel,"topToast":topToastView,"description":friendfriendSubtitleLabel])
                parent.addConstraints(hConstraints)
                parent.addConstraints(vConstraints)
                parent.layoutIfNeeded()
            }
        }
        
        func removeTopToast(){
            topToastView.removeFromSuperview()
        }
        //
        self.isTopToast = isTopToast
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            if isTopToast{
                insertTopToast()
            }else{
                removeTopToast()
            }
        }
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
        friendPictureView.setImage(user: friend)
    }
    
    private func configureFriendName(friend:PFUser){
        let name = friend["name"] as! String
        friendfriendSubtitleLabel.text = "Friends with \(correctedName(name))"
        if let isTopToast = isTopToast where !isTopToast{
            friendfriendSubtitleLabel.text?.appendContentsOf("\non Facebook")
        }
    }
    
    //MARK: - Friend of friend methods
    private func configureFriendOfFriendPicture(friendFriend:PFUser){
        configureReviewerPicture(friendFriendPictureView.layer)
        friendFriendPictureView.setImage(user: friendFriend) { () -> () in
            self.myDelegate?.reviewHeaderDoneLoading()
        }
    }

    private func configureFriendOfFriendName(friendFriend:PFUser){
        let name = friendFriend["name"] as! String
        friendfriendNameLabel.text = correctedName(name)
        
        if let isTopToast = isTopToast where !isTopToast{
            friendfriendNameLabel.text = friendfriendNameLabel.text!+"'s"
        }
    }
    
    override func reviewerButtonPressed(sender: ReviewerButton) {
        myDelegate?.friendPicturePressed(friend)
    }
}
