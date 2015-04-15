//
//  ProfileToastsDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 3/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ProfileToastsDataSource: NSObject,UITableViewDataSource,UITableViewDelegate {
    var toasts: [PFObject]!
    var user:PFUser!
    
    init(toasts:[PFObject],user:PFUser){
        super.init()
        self.toasts = toasts
        self.user = user
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toasts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("toastCell") as! ProfileToastCell
        cell.configureCell(toasts[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCellWithIdentifier("headerCell") as! ProfileHeaderCell
        header.configureCell(user)
        
        return header
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 290
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 182
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}
