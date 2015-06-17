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
    
    let headerQueue = NSOperationQueue()
    
    func configure(item:PFObject,index:Int,lastIndex:Int){
        configure(index)
        configureUser(item: item)
        configureReview(item: item,isSingle: lastIndex == 0)
        configureSeparatorLine(isLastItem: lastIndex == index)
    }
    
    //MARK: - Configure methods
    private func configure(index:Int){
        reviewIndex = index
        headerView.alpha = 0
        if reviewLinkTextView != nil{
            reviewLinkTextView.alpha = 0
        }else{
            reviewTextLabel.alpha = 0
        }
        
        if separatorView != nil {
            separatorView.alpha = 0
        }
    }
    
    //MARK: - Configure User methods
    private func configureUser(#item:PFObject){
        if let user = item["user"] as? PFUser{
            friendOfFriend(user,toast:item)
        }
    }
    
    private func friendOfFriend(friendFriend:PFUser,toast:PFObject){
        headerQueue.addOperationWithBlock { () -> Void in
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
    }
    
    private func configureFriendHeader(friend:PFUser,toast:PFObject){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            let header = self.myHeaderSource?.dequeueFriendHeader()
            header?.configure(friend: friend,myDelegate:self,superView:self.headerView,isTopToast:self.isTopToast(friend, toast: toast))
            self.insertHeader(header!)
        }
    }
    
    private func configureFriendOfFriendHeader(friend:PFUser,friendFriend:PFUser,toast:PFObject){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            let header = self.myHeaderSource?.dequeueFriendOfFriendHeader()
            header?.configure(friend: friend, friendFriend: friendFriend,myDelegate:self,superView:self.headerView, isTopToast: self.isTopToast(friendFriend, toast: toast))
            self.insertHeader(header!)
        }
    }
    
    private func isTopToast(user:PFUser,toast:PFObject) -> Bool{
        if let topToast = user["topToast"] as? PFObject{
            return topToast.objectId == toast.objectId
        }else{
            return false
        }
    }
    
    private func insertHeader(header:ReviewHeaderCell){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.removePreviousHeader()
            header.frame = self.headerView.bounds
            self.headerView.addSubview(header)
            self.toggleAlpha(alpha: 1, views: self.headerView)
            if self.reviewLinkTextView != nil{
                self.toggleAlpha(alpha: 1, views: self.reviewLinkTextView)
            }else{
                self.toggleAlpha(alpha: 1, views: self.reviewTextLabel)
            }
        }
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
        for k in 0...words.count-1{
            let word = words[k]
            finalReview.appendAttributedString(attributedWord(word))
            if k != 0 && k<words.count-1 {
                finalReview.appendAttributedString(attributedWord(" "))
            }
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
        if !isLastItem {
            toggleAlpha(alpha: 0.4, views: separatorView)
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
    
    func reviewHeaderDoneLoading() {
        
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
        let rawHashtag = value as! String
        let cleanedHashtag = HashtagsManager.cleanHashtag(rawHashtag)
        myDelegate?.reviewCellHashtagPressed(cleanedHashtag)
    }
    
    
    //MARK: - Misc methods
    func toggleAlpha(#alpha:CGFloat,duration:CGFloat=0.3,completion:(()->Void)?=nil,views:UIView...){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                for view in views{
                    view.alpha = alpha
                }
                }) { (success) -> Void in
                    completion
            }
        }
    }
}
