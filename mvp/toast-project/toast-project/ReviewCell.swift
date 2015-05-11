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
    func reviewCellReviewerPressed(index:Int)
}

protocol ReviewCellHeaderSource{
    func dequeueFriendHeader() -> ReviewHeaderCell
    func dequeueFriendOfFriendHeader() -> ReviewHeaderCell
}

class ReviewCell: UITableViewCell,ReviewHeaderDelegate {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var reviewTextLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var reviewLinkTextView: CCHLinkTextView!
    
    @IBOutlet weak var heartButton: HeartButton!
    @IBOutlet weak var followButton: FollowButton!
    
    var myToast:PFObject!
    var myHeaderSource:ReviewCellHeaderSource?
    var myDelegate:ReviewCellDelegate?
    var reviewIndex:Int!
    
    func configure(item:PFObject,index:Int,lastIndex:Int){
        configure(index)
        configureUser(item: item)
        configureReview(item: item,isSingle: lastIndex == 0)
        configureSeparatorLine(isLastItem: lastIndex == index)
        configureActionButtons(item, isSingle: lastIndex == 0)
    }
    
    //MARK: - Configure methods
    private func configure(index:Int){
        reviewIndex = index
    }
    
    //MARK: - Configure User methods
    private func configureUser(#item:PFObject){
        if let user = item["user"] as? PFUser{
            friendOfFriend(user)
        }
    }
    
    private func friendOfFriend(friendFriend:PFUser){
        PFCloud.callFunctionInBackground("friendOfFriend", withParameters: ["reviewerId":friendFriend.objectId]) { (result, error) -> Void in
            if error == nil{
                if let friend = result as? PFUser{
                    self.configureFriendOfFriendHeader(friend,friendFriend: friendFriend)
                }else{
                    self.configureFriendHeader(friendFriend)
                }
            }else{
                NSLog("friendOfFriend error: %@",error.description)
            }
            
        }
    }
    
    private func configureFriendHeader(friend:PFUser){
        let header = myHeaderSource?.dequeueFriendHeader()
        header?.configure(friend: friend,myDelegate:self)
        insertHeader(header!)
    }
    
    private func configureFriendOfFriendHeader(friend:PFUser,friendFriend:PFUser){
        let header = myHeaderSource?.dequeueFriendOfFriendHeader()
        
        header?.configure(friend: friend, friendFriend: friendFriend,myDelegate:self)
        insertHeader(header!)
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
                setReview("\""+review+"\"")
            }else{
                setReview(review)
            }
            
        }
    }
    
    private func setReview(review:String){
        reviewTextLabel.text = review
        self.layoutIfNeeded()
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
            getUserActions(toast: item, completion: { (actions) -> Void in
                self.heartButton.isOn = actions[0] as! Bool
                self.followButton.isOn = actions[1] as! Bool
            })
        }
    }
    
    private func getUserActions(#toast:PFObject,completion:(actions:NSArray) -> Void){
        let cache = Cache<NSArray>(name:"userActions")
        cache.fetch(key: toast.objectId, failure: { (error) -> () in
            self.requestUserActions(toast: toast, completion: completion)
            }, success: { (actions) -> () in
            completion(actions: actions)
        })
    }
    
    private func requestUserActions(#toast:PFObject,completion:(actions:NSArray) -> Void){
        PFCloud.callFunctionInBackground("userActionsForToast", withParameters: ["toastId":toast.objectId]) { (result, error) -> Void in
            if error == nil{
                let actions = result as! NSArray
                self.saveActions(actions,toast:toast)
                completion(actions: actions)
            }else{
                NSLog("requestUserActions error: %@", error.description)
                let errorActions = [0,0]
                completion(actions: errorActions)
            }
        }
    }
    
    private func saveActions(actions:NSArray,toast:PFObject){
        let cache = Cache<NSArray>(name:"userActions")
        cache.set(value: actions, key: toast.objectId, success: nil)
    }
    
    //MARK: - Review  Header delegate methods
    func friendPicturePressed() {
        myDelegate?.reviewCellReviewerPressed(reviewIndex)
    }
    
    //MARK: - Actions buttons methods
    @IBAction func heartButtonPressed(sender: HeartButton) {
        var heartFunction = "heartToast"
        if !sender.isOn{
            heartFunction = "unheartToast"
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
}
