//
//  ReviewCell.swift
//  toast-project
//
//  Created by Diego Cruz on 3/18/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

protocol ReviewCellDelegate{
    func reviewCellReviewerPressed(index:Int,ffriend:PFUser?)
    func reviewCellHashtagPressed(name:String)
}

protocol ReviewCellHeaderSource{
    func dequeueFriendHeader() -> ReviewHeaderCell
    func dequeueFriendOfFriendHeader() -> ReviewHeaderCell
}

class ReviewCell: UITableViewCell,ReviewHeaderDelegate,CCHLinkTextViewDelegate {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var reviewTextLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var reviewLinkTextView: CCHLinkTextView!
    
    @IBOutlet weak var heartButton: HeartButton!
    @IBOutlet weak var heartCount: LikeCountView!
    
    var myToast:PFObject!
    var myHeaderSource:ReviewCellHeaderSource?
    var myDelegate:ReviewCellDelegate?
    var reviewIndex:Int!
    
    func configure(item:PFObject,index:Int,lastIndex:Int){
        configure(index)
        configureUser(item: item)
        configureReview(item: item,isSingle: lastIndex == 0)
        configureSeparatorLine(isLastItem: lastIndex == index)
    }
    
    //MARK: - Configure methods
    private func configure(index:Int){
        reviewIndex = index
    }
    
    //MARK: - Configure User methods
    private func configureUser(#item:PFObject){
        if let user = item["user"] as? PFUser{
            friendOfFriend(user,toast:item)
        }
    }
    
    private func friendOfFriend(friendFriend:PFUser,toast:PFObject){
        PFCloud.callFunctionInBackground("friendOfFriend", withParameters: ["reviewerId":friendFriend.objectId]) { (result, error) -> Void in
            if error == nil{
                if let friend = result as? PFUser{
                    self.configureFriendOfFriendHeader(friend,friendFriend: friendFriend,toast:toast)
                }else{
                    self.configureFriendHeader(friendFriend,toast:toast)
                }
            }else{
                NSLog("friendOfFriend error: %@",error.description)
            }
            
        }
    }
    
    private func configureFriendHeader(friend:PFUser,toast:PFObject){
        let header = myHeaderSource?.dequeueFriendHeader()
        header?.configure(friend: friend,myDelegate:self,isTopToast:isTopToast(friend, toast: toast))
        insertHeader(header!)
    }
    
    private func configureFriendOfFriendHeader(friend:PFUser,friendFriend:PFUser,toast:PFObject){
        let header = myHeaderSource?.dequeueFriendOfFriendHeader()
        
        header?.configure(friend: friend, friendFriend: friendFriend,myDelegate:self,isTopToast: isTopToast(friendFriend, toast: toast))
        insertHeader(header!)
    }
    
    private func isTopToast(user:PFUser,toast:PFObject) -> Bool{
        if let topToast = user["topToast"] as? PFObject{
            return topToast.objectId == toast.objectId
        }else{
            return false
        }
    }
    
    private func insertHeader(header:ReviewHeaderCell){
        removePreviousHeader()
        header.frame = headerView.bounds
        headerView.addSubview(header)
    }
    
    private func removePreviousHeader(){
        for subview in headerView.subviews{
            subview.removeFromSuperview()
        }
    }
    
    //MARK: - Configure Review methods
    private func configureReview(#item:PFObject,isSingle:Bool){
        myToast = item
        if let review = item["review"] as? String{
            if isSingle {
                setLinkableReview(review)
                setHeartCount(forItem: item)
                configureActionButtons(item, isSingle: isSingle)
            }else{
                setReview(review)
            }
            
        }
    }
    
    private func setReview(review:String){
        reviewTextLabel.text = review
    }
    
    private func setHeartCount(forItem item:PFObject){
        let userQuery = PFQuery(className: "_User")
        userQuery.whereKey("hearts", equalTo: item)
        userQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                self.heartCount.count = Int(count)
            }else{
                NSLog("setHeartCount error:%@",error.description)
            }
        }
    }
    
    private func setLinkableReview(review:String){
        configureLinkView()
        var words = review.componentsSeparatedByString(" ")
        var finalReview = NSMutableAttributedString(string: "")
        finalReview.appendAttributedString(attributedWord("\""))
        for word in words{
            finalReview.appendAttributedString(attributedWord(word))
            finalReview.appendAttributedString(attributedWord(" "))
        }
        finalReview.appendAttributedString(attributedWord("\""))
        reviewLinkTextView.attributedText = finalReview
        reviewLinkTextView.layoutIfNeeded()
    }
    
    private func configureLinkView(){
        reviewLinkTextView.linkDelegate = self
        reviewLinkTextView.scrollEnabled = false
        reviewLinkTextView.linkTextAttributes = [NSForegroundColorAttributeName:UIColor(hue:0.555, saturation:0.45, brightness:1, alpha:1)]
        reviewLinkTextView.linkTextTouchAttributes = [NSForegroundColorAttributeName:UIColor(hue:0.555, saturation:0.45, brightness:0.7, alpha:1),NSBackgroundColorAttributeName:UIColor.clearColor()]
    }
    
    private func attributedWord(word:String)->NSAttributedString{
        if let hashIndex = find(word,"#"){
            return attributedHashtag(word)
        }else{
            return attributedNormal(word)
        }
    }
    
    private func attributedNormal(word:String)->NSAttributedString{
        return NSAttributedString(string: word, attributes: myAttributes())
    }
    
    private func attributedHashtag(hashtag:String)->NSAttributedString{
        var attr = myAttributes()
        attr[CCHLinkAttributeName] = hashtag.componentsSeparatedByString("#")[1]
        return NSAttributedString(string: hashtag, attributes: attr)
    }
    
    private func myAttributes() -> [NSObject:AnyObject]{
        var attributes = [NSObject:AnyObject]()
        attributes[NSFontAttributeName] = UIFont(name: "Avenir-Medium", size: 16)
        attributes[NSForegroundColorAttributeName] = UIColor.whiteColor()
        return attributes
    }
    
    //MARK: - Configure Separator line methods
    private func configureSeparatorLine(#isLastItem:Bool){
        if isLastItem {
            separatorView.alpha = 0
        }else{
            separatorView.alpha = 0.4
        }
    }
    
    //MARK: - Configure ActionButton methods
    private func configureActionButtons(item:PFObject,isSingle:Bool){
        if isSingle{
            getHasHeart(toast: item, completion: { (hasHeart) -> Void in
                self.heartButton.isOn = hasHeart
            })
        }
    }
    
    private func getHasHeart(#toast:PFObject,completion:(hasHeart:Bool) -> Void){
        let cache = Cache<String>(name:"hasHearts")
        cache.fetch(key: toast.objectId, failure: { (error) -> () in
            self.requestHasHeart(toast: toast, completion: completion)
            }, success: { (result) -> () in
            completion(hasHeart: (result as String).toInt()! == 1)
        })
    }
    
    private func requestHasHeart(#toast:PFObject,completion:(hasHeart:Bool) -> Void){
        let heartsQuery = PFUser.currentUser().relationForKey("hearts").query()
        heartsQuery.whereKey("objectId", equalTo: myToast.objectId)
        heartsQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                self.saveHasHeart("\(count)", toast: toast)
                completion(hasHeart: count == 1)
            }else{
                NSLog("requestHasHeart error: %@",error.description)
            }
        }
    }
    
    private func saveHasHeart(hasHeart:String,toast:PFObject){
        let cache = Cache<String>(name:"hasHearts")
        cache.set(value: hasHeart, key: toast.objectId, success: nil)
    }
    
    //MARK: - Review  Header delegate methods
    func friendPicturePressed(ffriend:PFUser?) {
        myDelegate?.reviewCellReviewerPressed(reviewIndex,ffriend:ffriend)
    }
    
    @IBAction func reviewerPressed(sender: UIButton) {
        let reviewHeader = headerView.subviews[0] as! ReviewHeaderCell
        var ffriend:PFUser?
        if let friendOfFriendHeader = reviewHeader as? FriendOfFriendHeaderCell{
            ffriend = friendOfFriendHeader.friend
        }
        myDelegate?.reviewCellReviewerPressed(reviewIndex,ffriend:ffriend)
    }
 
    //MARK: - Actions buttons methods
    @IBAction func heartButtonPressed(sender: HeartButton) {
        var heartFunction:String
        if sender.isOn{
            heartFunction = "heartToast"
            heartCount.count++
        }else{
            heartFunction = "unheartToast"
            heartCount.count--
        }
        
        PFCloud.callFunctionInBackground(heartFunction, withParameters: ["toastId":myToast!.objectId]) { (result, error) -> Void in
            if error != nil{
                NSLog("heartButtonPressed error: %@",error.description)
            }
        }
    }
    
    @IBAction func followButtonPressed(sender: FollowButton) {
        var followFunction = "followUser"
        if !sender.isOn{
            followFunction = "unfollowUser"
        }
        
        let user = (myToast!["user"] as! PFUser).objectId
        PFCloud.callFunctionInBackground(followFunction, withParameters: ["userId":user]) { (result, error) -> Void in
            if error != nil{
                NSLog("followButtonPressed error: %@",error.description)
            }
        }
    }
    
    //MARK: - CCHLinkTextView delegate methods
    func linkTextView(linkTextView: CCHLinkTextView!, didTapLinkWithValue value: AnyObject!) {
        myDelegate?.reviewCellHashtagPressed(value as! String)
    }
}
