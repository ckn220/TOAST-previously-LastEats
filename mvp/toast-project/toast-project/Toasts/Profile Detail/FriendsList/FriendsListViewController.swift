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
    
    var myUser:PFObject!
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
        configureFriends()
    }
    
    private func configureTitle(){
        if myUser.objectId == PFUser.currentUser()!.objectId{
            myTitleLabel.text = "My Friends"
        }else{
            let fullName = myUser["name"] as! String
            var names = fullName.componentsSeparatedByString(" ")
            myTitleLabel.text = "\(names[0])'s Friends"
        }
    }
    
    private func configureFriends(){
        let friendsQuery = myUser.relationForKey("friends").query()!
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
