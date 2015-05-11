//
//  ProfileDetailViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 3/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

class ProfileDetailViewController: UIViewController {

    @IBOutlet weak var myTableView: UITableView!
    
    @IBOutlet weak var userPictureView: BackgroundImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var toastCountLabel: UILabel!
    @IBOutlet weak var friendsCountLabel: UILabel!
    @IBOutlet weak var followersCountLabel: UILabel!
    
    var toasts: [PFObject]?
    var topToast: PFObject?
    var myUser:PFUser!
    var profileDataSource:ProfileToastsDataSource!{
        didSet{
            myTableView.dataSource = profileDataSource
            myTableView.delegate = profileDataSource
            myTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure(){
        myTableView.contentInset = UIEdgeInsetsMake(-40, 0, -30, 0);
        configureUserHeader()
        configureUserToasts()
    }
    
    private func configureUserToasts(){
        let group = dispatch_group_create()
        loadToasts(group: group)
        loadTopToast(group: group)
        configureUserToastsCompletion(group: group)
    }
    
    private func loadTopToast(#group: dispatch_group_t){
        if let topToast = self.myUser["topToast"] as? PFObject{
            dispatch_group_enter(group)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                topToast.fetchIfNeededInBackgroundWithBlock { (result, error) -> Void in
                    if error == nil{
                        self.topToast = result as PFObject
                    }else{
                        NSLog("loadTopToast error: %@",error.description)
                    }
                    dispatch_group_leave(group)
                }
            })
        }
    }
    
    private func loadToasts(#group: dispatch_group_t){
        dispatch_group_enter(group)
        let query = PFQuery(className: "Toast")
        query.whereKey("user", equalTo: myUser)
        query.orderByDescending("createdAt")
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.toasts = result as? [PFObject]
            }else{
                NSLog("loadToasts error: %@",error.description)
            }
            dispatch_group_leave(group)
        }
    }
    
    private func configureUserToastsCompletion(#group: dispatch_group_t){
        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { () -> Void in
            self.profileDataSource = ProfileToastsDataSource(toasts: self.toasts!,user:self.myUser,topToast:self.topToast)
        }
    }
    
    private func configureUserHeader(){
        configureProfileImage(myUser)
        configureProfileName(myUser)
        configureCountLabels(myUser)
    }
    
    private func configureProfileImage(user:PFUser){
        let imageURL = user["pictureURL"] as! String
        let cache = Shared.imageCache
        cache.fetch(URL: NSURL(string: imageURL)!, failure: { (error) -> () in
            NSLog("configureProfileImage error: %@",error!.description)
            }, success: { (image) -> () in
                self.userPictureView.myImage = image
        })
    }
    
    private func configureProfileName(user:PFUser){
        userNameLabel.text = user["name"] as! String!
    }
    
    private func configureCountLabels(user:PFUser){
        configureToastCount(user)
        configureFriendCount(user)
        configureFollowerCount(user)
    }
    
    private func initCountLabel(label:UILabel){
        let layer = label.layer
        layer.cornerRadius = CGRectGetWidth(label.bounds)/2
        layer.borderWidth = 1
        layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    private func configureToastCount(user:PFUser){
        initCountLabel(toastCountLabel)
        let toastQuery = PFQuery(className: "Toast")
        toastQuery.whereKey("user", equalTo: user)
        toastQuery.orderByDescending("createdAt")
        toastQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                self.toastCountLabel.text = String(format: "%02d", count)
            }else{
                NSLog("configureToastCount error: %@",error.description)
            }
        }
    }
    
    private func configureFriendCount(user:PFUser){
        initCountLabel(friendsCountLabel)
        let friendsQuery = user.relationForKey("friends").query()
        friendsQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                self.friendsCountLabel.text = String(format: "%02d", count)
            }else{
                NSLog("configureFriendCount error: %@",error.description)
            }
        }
    }
    
    private func configureFollowerCount(user:PFUser){
        initCountLabel(followersCountLabel)
        let followerQuery = PFQuery(className: "User")
        followerQuery.whereKey("follows", equalTo: user)
        followerQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                self.followersCountLabel.text = String(format: "%02d", count)
            }else{
                NSLog("configureFollowerCount error: %@",error.description)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Action methods
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "friendsListSegue"{
            let destination = segue.destinationViewController as! FriendsListViewController
            destination.myUser = myUser
            destination.fromMain = false
        }
    }
    
}
