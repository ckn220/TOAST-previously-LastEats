//
//  ActivityTableViewController.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/15/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class FriendCache{
    var hasFriend:Bool!
    var friend:PFUser?
    
    init(hasFriend:Bool,friend:PFUser?=nil){
        self.hasFriend = hasFriend
        self.friend = friend
    }
}

class ActivityTableViewController: UITableViewController,ActivityCellDelegate {

    //MARK: - Properties
    var activities = [PFObject]()
    var friendsCache = [PFObject:FriendCache!]()
    var placeCache = [PFObject:PFObject]()
    
    //MARK: - Configure methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure(){
        refreshActivities()
    }
    
    private func refreshActivities(completion:(()->())?=nil){
        func completeRefreshActivities(activities:[PFObject]){
            friendsCache.removeAll()
            self.activities = activities
            tableView.reloadData()
            completion?()
        }
        
        func cleanCache(){
            friendsCache.removeAll()
            placeCache.removeAll()
        }
        
        cleanCache()
        PFCloud.callFunctionInBackground("getActivityFeed", withParameters: nil) { (result, error) -> Void in
            if let error = error{
                NSLog("refreshActivities error: %@",error.description)
            }else{
                if let activities = result as? [PFObject]{
                    completeRefreshActivities(activities)
                }
            }
        }
    }

    // MARK: - TableView datasource methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let activity = activities[indexPath.row]
        let identifier = cellIdentifier(activity)
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier) as! ActivityCell
        cell.configure(activity)
        
        return cell
    }
    
    private func cellIdentifier(activity:PFObject) -> String{
        let action = activity["action"] as! PFObject
        let actionName = action["name"] as! String
        switch actionName{
        case "adds":
            return "toastsCell"
        case "hearts":
            return "likesCell"
        case "topToasts":
            return "topToastsCell"
        default:
            return ""
        }
    }
    
    //MARK: - ActivityCell delegate methods
    func cachedPlace(activity: PFObject) -> PFObject? {
        return placeCache[activity]
    }
    
    func savePlaceInCache(place: PFObject, activity: PFObject) {
        placeCache[activity] = place
    }
    //
    func cachedFriend(activity: PFObject) -> FriendCache? {
        return friendsCache[activity]
    }
    
    func saveFriendInCache(friend: PFUser?, activity: PFObject) {
        friendsCache[activity] = FriendCache(hasFriend:friend != nil,friend:friend)
    }
    
    //MARK: - Refresh Control methods
    
    @IBAction func refreshChanged(sender: UIRefreshControl) {
        refreshActivities { () -> () in
            sender.endRefreshing()
        }
    }
}

