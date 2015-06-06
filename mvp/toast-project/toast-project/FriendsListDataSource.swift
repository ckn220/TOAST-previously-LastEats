//
//  FriendsListDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 5/7/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol FriendsDataSourceDelegate{
    func friendsDataSourceDelegateFriendSelected(friend:PFUser)
}

class FriendsListDataSource: NSObject,UITableViewDataSource,UITableViewDelegate {
    var friends:[PFUser]!
    var myDelegate:FriendsDataSourceDelegate?
    
    init(friends:[PFUser],myDelegate:FriendsDataSourceDelegate?){
        super.init()
        self.friends = friends
        self.myDelegate = myDelegate
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("friendCell") as! FriendCell
        cell.configure(friends[indexPath.row],isFirstRow:indexPath.row == 0)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedFriend = friends[indexPath.row]
        myDelegate?.friendsDataSourceDelegateFriendSelected(selectedFriend)
    }
}
