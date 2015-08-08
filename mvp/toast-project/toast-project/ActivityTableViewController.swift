//
//  ActivityTableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 7/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol ActivityFeedDelegate{
    func activityFeedPlaceSelected(toast:PFObject)
    func activityFeedPlaceReviewsSelected(place:PFObject,title:String)
    func activityFeedPlaceLikesSelected(activity:PFObject)
    func activityFeedUserSelected(user:PFUser)
    func activityFeedAddToastSelected(place:PFObject)
}

class ActivityTableViewController: UITableViewController,ActivityCellDelegate {
    
    var activities = [PFObject](){
        didSet{
            tableView.reloadData()
        }
    }
    var myDelegate:ActivityFeedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureActivities()
    }
    
    private func configureTableView(){
        tableView.estimatedRowHeight = 120
    }
    
    private func configureActivities(){
        PFCloud.callFunctionInBackground("getActivityFeed", withParameters: nil) { (result, error) -> Void in
            if error == nil{
                self.activities = result as! [PFObject]
            }else{
                NSLog("configureActivies error: %@",error!.description)
            }
        }
    }
    
    //MARK: - Tableview methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("activityCell") as! ActivityCell
        let activity = activities[indexPath.row]
        cell.configure(activity,delegate:self)
        
        return cell
    }
    
    //MARK: - Actions methods
    @IBAction func refreshActivated(sender: UIRefreshControl) {
        configureActivities()
        sender.endRefreshing()
    }
    
    //MARK: - Activity cell delegate methods
    func activityCellUserPressed(user:PFUser) {
        myDelegate?.activityFeedUserSelected(user)
    }
    
    func activityCellPlacePressed(toast:PFObject) {
        myDelegate?.activityFeedPlaceSelected(toast)
    }
    
    func activityCellToastCountPressed(place:PFObject,title:String) {
        myDelegate?.activityFeedPlaceReviewsSelected(place,title:title)
    }
    
    func activityCellLikeCountPressed(activity:PFObject) {
        myDelegate?.activityFeedPlaceLikesSelected(activity)
    }
    
    func activityCellAddToastPressed(place:PFObject) {
        myDelegate?.activityFeedAddToastSelected(place)
    }
}
