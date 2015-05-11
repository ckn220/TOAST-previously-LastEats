//
//  FriendsListDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 5/7/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class FriendsListDataSource: NSObject,UITableViewDataSource,UITableViewDelegate {
    var friends:[PFObject]!
    
    init(friends:[PFObject]){
        super.init()
        self.friends = friends
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("friendCell") as! FriendCell
        cell.configure(friends[indexPath.row])
        
        return cell
    }
}
