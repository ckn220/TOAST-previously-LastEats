//
//  FriendsListViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 5/7/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class FriendsListViewController: UIViewController,FriendsDataSourceDelegate {

    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var myTitleLabel: UILabel!
    
    var fromMain = false
    var myDelegate:DiscoverDelegate?
    
    var myActivity:PFObject?
    var myUser:PFObject?
    var friendsDataSource:FriendsListDataSource?{
        didSet{
            friendsTableView.dataSource = friendsDataSource
            friendsTableView.delegate = friendsDataSource
            friendsTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure(){
        configureTitle()
        configureItems()
    }
    
    //MARK: - Configure Title methods
    private func configureTitle(){
        if let user = myUser{
            configureFriendsTitle(user)
        }else{
            configureLikesTitle()
        }
    }
    
    private func configureFriendsTitle(user:PFObject){
        if user.objectId == PFUser.currentUser()!.objectId{
            myTitleLabel.text = "My Friends"
        }else{
            let fullName = user["name"] as! String
            var names = fullName.componentsSeparatedByString(" ")
            myTitleLabel.text = "\(names[0])'s Friends"
        }
    }
    
    private func configureLikesTitle(){
        if let activity = myActivity, let toast = activity["toastDest"] as? PFObject, let likesCount = toast["heartsCount"] as? Int{
            var suffixString = "Likes"
            if likesCount == 1{
                suffixString = "Like"
            }
            myTitleLabel.text = "\(likesCount) \(suffixString)"
        }
        
    }
    
    //MARK: - Configure Items methods
    private func configureItems(){
        if let user = myUser{
            configureFriends(user)
        }else{
            configureLikeUsers()
        }
    }
    
    private func configureFriends(user:PFObject){
        
        let friendsQuery = user.relationForKey("friends").query()!
        friendsQuery.orderByAscending("name")
        friendsQuery.includeKey("topToast")
        friendsQuery.findObjectsInBackgroundWithBlock { (friends, error) -> Void in
            if error == nil{
                self.friendsDataSource = FriendsListDataSource(friends:friends as! [PFUser],myDelegate:self)
            }else{
                NSLog("configureFriends error: %@",error!.description)
            }
        }
    }

    private func configureLikeUsers(){
        if let activity = myActivity, let toast = activity["toastDest"] as? PFObject{
            let usersQuery = PFUser.query()!
            usersQuery.whereKey("hearts", equalTo: toast)
            usersQuery.findObjectsInBackgroundWithBlock({ (users, error) -> Void in
                if error == nil{
                    self.friendsDataSource = FriendsListDataSource(friends:users as! [PFUser],myDelegate:self)
                }else{
                    NSLog("configureLikeUsers error: %@",error!.description)
                }
            })
        }
    }
    
    //MARK: - Actions methods
    @IBAction func backPressed(sender: UIButton) {
        if !fromMain {
            navigationController?.popViewControllerAnimated(true)
        }else{
            myDelegate?.discoverMenuPressed()
        }
        
    }
    
    //MARK: - FriendsDataSource delegate methods
    func friendsDataSourceDelegateFriendSelected(friend: PFUser) {
        let destination = storyboard?.instantiateViewControllerWithIdentifier("profileDetailScene") as! ProfileDetailViewController
        destination.myDelegate = nil
        destination.myUser = friend
        showViewController(destination, sender: self)
    }
}
