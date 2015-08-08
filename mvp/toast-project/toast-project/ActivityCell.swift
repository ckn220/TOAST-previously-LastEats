//
//  ActivityCell.swift
//  toast-project
//
//  Created by Diego Cruz on 7/19/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

protocol ActivityCellDelegate{
    func activityCellUserPressed(user:PFUser)
    func activityCellPlacePressed(toast:PFObject)
    func activityCellToastCountPressed(place:PFObject,title:String)
    func activityCellLikeCountPressed(activity:PFObject)
    func activityCellAddToastPressed(place:PFObject)
}

class ActivityCell: UITableViewCell {

    let secsInMin:Double = 60
    let minsInHour:Double = 60
    let hoursInDay:Double = 24
    
    @IBOutlet weak var cardView: UIView!
    
    //Header
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var avatarsView: UIView!
    @IBOutlet weak var tetxGroupView: UIView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var clockImageView: UIImageView!
    @IBOutlet weak var userPictureView: UIImageView!
    @IBOutlet weak var friendPictureView: UIImageView!
    @IBOutlet weak var friendPIctureWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heartImageView: UIImageView!
    
    //Body
    @IBOutlet weak var bodyView: UIView!
    @IBOutlet weak var placeTextGroupView: UIView!
    @IBOutlet weak var placePictureView: UIImageView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var toastsLabel: UILabel!
    @IBOutlet weak var topToasts: UILabel!
    
    
    //Footer
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var toastCountButton: UIButton!
    @IBOutlet weak var addToastButton: UIButton!
    
    var activity:PFObject!
    var userDest:PFObject?
    var placeDest:PFObject?
    var myDelegate:ActivityCellDelegate?
    
    //MARK: - Configure methods
    func configure(activity:PFObject,delegate:ActivityCellDelegate){
        self.activity = activity
        myDelegate = delegate
        configureHeader()
        configureBody()
    }
    
    //MARK: Header
    private func configureHeader(){
        resetHeader()
        configureUser()
        configureTime()
    }
    
    private func resetHeader(){
        avatarsView.alpha = 0
        tetxGroupView.alpha = 0
    }
    

    
    private func configureUser(){
        NSOperationQueue().addOperationWithBlock { () -> Void in
            let reviewer = self.activity["user"] as! PFUser
            PFCloud.callFunctionInBackground("friendOfFriend", withParameters: ["reviewerId":reviewer.objectId!]) { (result, error) -> Void in
                if error == nil{
                    if let friend = result as? PFUser{
                        self.configureIndirectFriend(friend)
                    }else{
                        self.configureDirectFriend()
                    }
                }else{
                    NSLog("configureUser error: %@",error!.description)
                }
                
            }
        }
    }
    
    private func configureDirectFriend(){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.friendPIctureWidthConstraint.constant = 0
            self.subtitleLabel.text = ""
            
            let directFriend = self.activity["user"] as! PFUser
            self.userNameLabel.text = directFriend["name"] as? String
            self.tetxGroupView.alpha = 1
            
            if let pictureString = directFriend["pictureURL"] as? String, let pictureURL = NSURL(string:pictureString){
                self.userPictureView.hnk_setImageFromURL(pictureURL, success: { (image) -> () in
                    self.userPictureView.image = image
                    self.avatarsView.alpha = 1
                })
            }
            
        }
    }
    
    private func configureIndirectFriend(directFriend:PFUser){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.friendPIctureWidthConstraint.constant = 28
            let directFriendName = self.shortName(directFriend["name"] as! String)
            self.subtitleLabel.text = "Friend of \(directFriendName)"
            
            let indirectFriend = self.activity["user"] as! PFUser
            let pictureURL = NSURL(string:indirectFriend["pictureURL"] as! String)!
            self.userNameLabel.text = indirectFriend["name"] as? String
            self.tetxGroupView.alpha = 1
            self.userPictureView.hnk_setImageFromURL(pictureURL, success: { (image) -> () in
                self.userPictureView.image = image
                self.avatarsView.alpha = 1
            })
            
            let directFriendURL = NSURL(string:directFriend["pictureURL"] as! String)!
            self.friendPictureView.hnk_setImageFromURL(directFriendURL)
        }
    }
    
    private func configureTime(){
        NSOperationQueue().addOperationWithBlock { () -> Void in
            let nowDate = NSDate()
            let activityDate = self.activity.createdAt!
            let dateDiff = nowDate.timeIntervalSinceDate(activityDate)
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.timeLabel.text = self.timeString(dateDiff)
                self.clockImageView.image = nil
                self.clockImageView.image = UIImage(named: "clockIcon")
            })
        }
    }
    
    private func timeString(diff:NSTimeInterval)->String{
        let days = daysInDiff(diff)
        if days > 0{
            return "\(days)d"
        }else{
            let hours = hoursInDiff(diff)
            if hours > 0{
                return "\(hours)h"
            }else{
                let minutes = minInDiff(diff)
                if minutes > 0{
                    return "\(minutes)min"
                }else{
                    if diff > 20{
                        return "Less than 1 min"
                    }else{
                        return "Just now"
                    }
                }
            }
        }
    }
    
    private func daysInDiff(diff:NSTimeInterval) -> Int{
        let div = hoursInDay*minsInHour*secsInMin
        return Int(diff/div)
    }
    
    private func hoursInDiff(diff:NSTimeInterval) -> Int{
        let div = minsInHour*secsInMin
        return Int(diff/div)
    }
    
    private func minInDiff(diff:NSTimeInterval) -> Int{
        let div = secsInMin
        return Int(diff/div)
    }
    
    
    //MARK: Body
    private func configureBody(){
        resetBody()
        switch actionName(){
        case "adds":
            configureAddsAction()
        case "topToasts":
            configureTopToastsAction()
        case "hearts":
            configureHeartsAction()
        default:
            return
        }
    }
    
    private func resetBody(){
        placeTextGroupView.alpha = 0
        placePictureView.alpha = 0
    }
    
    private func actionName()->String{
        let action = activity["action"] as! PFObject
        return action["name"] as! String
    }
    
    private func configureAddsAction(){
        toggleTopToastLook(false)
        toggleHeartsLook(false)
        let group = dispatch_group_create()
        getPlace(group)
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            if let place = self.placeDest{
                self.placeNameLabel.text = place["name"] as? String
                self.placeTextGroupView.alpha = 1
                let placePictureURL = NSURL(string: (place["photos"] as! [String])[0])!
                self.placePictureView.hnk_setImageFromURL(placePictureURL, success: {(image) -> () in
                    self.placePictureView.alpha = 1
                    self.placePictureView.image = image
                })
                
                self.toastsLabel.text = "Toasts"
            }
        }
    }
    
    private func configureTopToastsAction(){
        toggleTopToastLook(true)
        toggleHeartsLook(false)
        let group = dispatch_group_create()
        var params = [String:PFObject]()
        getPlace(group)
        getUser(group)
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            if let place = self.placeDest, let user = self.userDest{
                self.placeNameLabel.text = place["name"] as? String
                self.placeTextGroupView.alpha = 1
                let placePictureURL = NSURL(string: (place["photos"] as! [String])[0])!
                self.placePictureView.hnk_setImageFromURL(placePictureURL, success: { (image) -> () in
                    self.placePictureView.alpha = 1
                    self.placePictureView.image = image
                })
            }
        }
    }
    
    private func configureHeartsAction(){
        toggleTopToastLook(false)
        toggleHeartsLook(true)
        let group = dispatch_group_create()
        var params = [String:PFObject]()
        getPlace(group)
        getUser(group)
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            if let place = self.placeDest, let user = self.userDest{
                self.placeNameLabel.text = place["name"] as? String
                self.placeTextGroupView.alpha = 1
                let placePictureURL = NSURL(string: (place["photos"] as! [String])[0])!
                self.placePictureView.hnk_setImageFromURL(placePictureURL, success: { (image) -> () in
                    self.placePictureView.alpha = 1
                    self.placePictureView.image = image
                })
                
                let firstName = (user["name"] as! String).componentsSeparatedByString(" ")[0]
                self.toastsLabel.text = "Likes \(firstName)'s toast"
            }
        }
    }
    
    private func toggleTopToastLook(isTopToast:Bool){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            let myWhite = UIColor.whiteColor()
            let myBlue = UIColor(red:0.29, green:0.564, blue:0.886, alpha:1)
            let myBlack = UIColor.blackColor()
            if isTopToast{
                self.cardView.backgroundColor = myBlack
                self.userNameLabel.textColor = myWhite
                self.subtitleLabel.textColor = myWhite
                self.timeLabel.textColor = myWhite
                self.clockImageView.tintColor = myWhite
                self.toastsLabel.alpha = 0
                self.topToasts.alpha = 1
                self.toastCountButton.setTitleColor(myWhite, forState: .Normal)
                self.addToastButton.setTitleColor(myBlue, forState: .Normal)
                self.addToastButton.alpha = 1
            }else{
                self.cardView.backgroundColor = myWhite
                self.userNameLabel.textColor = myBlack
                self.subtitleLabel.textColor = myBlack
                self.timeLabel.textColor = myBlack
                self.clockImageView.tintColor = myBlack
                self.toastsLabel.alpha = 1
                self.topToasts.alpha = 0
                self.toastCountButton.setTitleColor(myBlack, forState: .Normal)
                self.addToastButton.setTitleColor(myBlack, forState: .Normal)
                self.addToastButton.alpha = 0.5
            }
        }
    }
    
    private func toggleHeartsLook(isHearts:Bool){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            if isHearts{
                self.heartImageView.alpha = 1
            }else{
                self.heartImageView.alpha = 0
            }
        }
    }
    
    private func getPlace(group:dispatch_group_t){
        dispatch_group_enter(group)
        NSOperationQueue().addOperationWithBlock { () -> Void in
            let toast = self.activity["toastDest"] as! PFObject
            let place = toast["place"] as! PFObject
            let placeFetchingQuery = PFQuery(className: "Place")
            placeFetchingQuery.includeKey("neighborhood")
            placeFetchingQuery.getObjectInBackgroundWithId(place.objectId!, block: { (place, error) -> Void in
                if error == nil{
                    self.placeDest = place
                }else{
                    NSLog("configurePlace error: %@",error!.description)
                }
                self.configureFooter()
                dispatch_group_leave(group)
            })
        }
    }
    
    private func getUser(group:dispatch_group_t){
        dispatch_group_enter(group)
        NSOperationQueue().addOperationWithBlock { () -> Void in
            let toast = self.activity["toastDest"] as! PFObject
            let user = toast["user"] as! PFObject
            user.fetchIfNeededInBackgroundWithBlock { (user, error) -> Void in
                if error == nil{
                    self.userDest = user
                }else{
                    NSLog("getUser error: %@",error!.description)
                }
                dispatch_group_leave(group)
            }
        }
        
    }
    
    //MARK: Footer
    private func configureFooter(){
        resetFooter()
        configureCountButton()
    }
    
    private func resetFooter(){
        bottomView.alpha = 0
    }
    
    private func configureCountButton(){
        if actionName() == "hearts"{
            configureLikeCount()
        }else{
            configureToastsCount()
        }
    }
    
    private func configureLikeCount(){
        if let toastDest = activity["toastDest"] as? PFObject, let likeCount = toastDest["heartsCount"] as? Int{
            var suffixString = "Likes"
            if likeCount == 1{
                suffixString = "Like"
            }
            toastCountButton.setTitle("\(likeCount) \(suffixString)", forState: .Normal)
        }
        bottomView.alpha = 1
    }
    
    private func configureToastsCount(){
        if let place = placeDest,let toastsQuery = place.relationForKey("toasts").query(){
            toastsQuery.countObjectsInBackgroundWithBlock({ (count, error) -> Void in
                if error == nil{
                    var suffixString = "Toasts"
                    if count == 1{
                        suffixString = "Toast"
                    }
                    self.toastCountButton.setTitle("\(count) \(suffixString)", forState: .Normal)
                }else{
                    self.toastCountButton.setTitle("", forState: .Normal)
                    NSLog("configureToastsCount error: %@",error!.description)
                }
                self.bottomView.alpha = 1
            })
        }
    }
    
    //MARK: - Misc methods
    func shortName(name:String) -> String{
        var words = name.componentsSeparatedByString(" ")
        var shortLastName = (words[1] as NSString).substringToIndex(1)
        return "\(words[0]) \(shortLastName)"
    }
    
    //MARK: - Action methods
    @IBAction func headerPressed(sender: UIButton){
        myDelegate?.activityCellUserPressed(activity["user"] as! PFUser)
    }
    
    @IBAction func bodyPressed(sender: UIButton){
        if let toast = activity["toastDest"] as? PFObject{
            myDelegate?.activityCellPlacePressed(toast)
        }
    }
    
    @IBAction func reviewsPressed(sender: UIButton) {
        if let place = placeDest{
            if actionName() == "hearts"{
                myDelegate?.activityCellLikeCountPressed(activity)
            }else{
                myDelegate?.activityCellToastCountPressed(place,title:sender.titleLabel!.text!)
            }
            
            
        }
    }
    
    @IBAction func addToast(sender: UIButton) {
        if let place = placeDest{
            myDelegate?.activityCellAddToastPressed(place)
        }
    }
    
}
