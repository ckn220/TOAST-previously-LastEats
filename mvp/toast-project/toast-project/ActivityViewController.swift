//
//  ActivityViewController.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/15/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ActivityViewController: UIViewController {

    //MARK: - Properties
    var myDelegate:DiscoverDelegate?
    
    //MARK: - Configure methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure(){
        configureNotifications()
    }
    
    //MARK: Notifications
    private func configureNotifications(){
        //User tapped
        NSNotificationCenter.defaultCenter().addObserverForName("ActivityUserTapped", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let userInfo = notification.userInfo, let user = userInfo["user"] as? PFUser{
                let friend = userInfo["friend"] as? PFUser
                self.handleUserTapped(user,friend:friend)
            }
        }
        //Place tapped
        NSNotificationCenter.defaultCenter().addObserverForName("ActivityPlaceTapped", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let userInfo = notification.userInfo, let toast = userInfo["toast"] as? PFObject{
                self.handlePlaceTapped(toast)
            }
        }
        //ToastCount tapped
        NSNotificationCenter.defaultCenter().addObserverForName("ActivityToastCountTapped", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let userInfo = notification.userInfo, let place = userInfo["place"] as? PFObject{
                self.handleToastCount(place)
            }
        }
        //LikeCount tapped
        NSNotificationCenter.defaultCenter().addObserverForName("ActivityLikeCountTapped", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let userInfo = notification.userInfo, let toast = userInfo["toast"] as? PFObject{
                self.handleLikeCount(toast)
            }
        }
        //Add a toast tapped
        NSNotificationCenter.defaultCenter().addObserverForName("ActivityAddAToastTapped", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let userInfo = notification.userInfo, let place = userInfo["place"] as? PFObject{
                self.handleAddAToast(place)
            }
        }
    }

    //MARK: - Handle notifications methods
    //MARK: User tapped
    private func handleUserTapped(user:PFUser,friend:PFUser?){
        let profileDetailScene = storyboard?.instantiateViewControllerWithIdentifier("profileDetailScene") as! ProfileDetailViewController
        profileDetailScene.myUser = user
        profileDetailScene.myFriend = friend
        showViewController(profileDetailScene, sender: self)
    }
    
    //MARK: Place tapped
    private func handlePlaceTapped(toast:PFObject){
        let toastDetailScene = storyboard?.instantiateViewControllerWithIdentifier("reviewDetailScene") as! ReviewDetailViewController
        toastDetailScene.myToast = toast
        toastDetailScene.myPlace = toast["place"] as? PFObject
        showViewController(toastDetailScene, sender: self)
    }
    
    //MARK: ActivityCount tapped
    private func handleToastCount(place:PFObject){
        
    }
    
    private func handleLikeCount(toast:PFObject){
        
    }
    
    //MARK: Add a Toast tapped
    private func handleAddAToast(place:PFObject){
        let contributeScene = storyboard?.instantiateViewControllerWithIdentifier("contributeScene") as! ContributeViewController
        contributeScene.placeFromActivity = place
        
        showDetailViewController(contributeScene, sender: self)
    }
    
    //MARK: - Action methods
    @IBAction func backPressed(sender: AnyObject) {
        myDelegate?.discoverMenuPressed()
    }
}
