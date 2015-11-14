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
    //MARK: - Properties
    //MARK: IBOutlets
    @IBOutlet weak var friendPictureView: BackgroundImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var topToastView: UIView!
    //MARK: Variables
    var isTopToast:Bool? = false
    
    //MARK: - AwakeFromNib methods
    override func awakeFromNib() {
        super.awakeFromNib()
        configureReviewerPicture(friendPictureView.layer)
    }
    
    //MARK: - Configure methods
    override func configure(friend friend: PFUser,myDelegate:ReviewHeaderDelegate,superView:UIView,isTopToast: Bool) {
        super.configure(friend: friend, myDelegate: myDelegate,superView:superView,isTopToast:isTopToast)
        configureTopToast(isTopToast)
        configurePicture(friend)
        configureName(friend)
    }
    
    //MARK: TopToast
    private func configureTopToast(isTopToast:Bool){
        func insertTopToast(){
            if topToastView.superview == nil{
                let parent = friendNameLabel.superview!
                parent.addSubview(topToastView)
                let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[topToast]", options: [], metrics: nil, views: ["topToast":topToastView])
                let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("[name]-4.0-[topToast]|", options: [], metrics: nil, views: ["name":friendNameLabel,"topToast":topToastView])
                parent.addConstraints(hConstraints)
                parent.addConstraints(vConstraints)
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
    
    //MARK: Picture
    private func configurePicture(user:PFUser){
        friendPictureView.setImage(user: user) { () -> () in
            self.myDelegate?.reviewHeaderDoneLoading()
        }
    }
    
    //MARK: Name
    private func configureName(user:PFUser){
        let name = user["name"] as! String
        friendNameLabel.text = correctedName(name)
        
        if let isTopToast = isTopToast where !isTopToast{
            friendNameLabel.text = friendNameLabel.text!+"'s"
        }
    }
    
}
