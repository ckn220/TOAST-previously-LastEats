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
    var topToast: PFObject?
    var isCurrentUser=false
    
    init(toasts:[PFObject],user:PFUser,topToast: PFObject?){
        super.init()
        self.toasts = toasts
        self.user = user
        self.topToast = topToast
        configure()
    }
    
    private func configure(){
        configureCurrentUser()
        sortToast()
    }
    
    private func configureCurrentUser(){
        isCurrentUser = user.objectId == PFUser.currentUser().objectId
    }
    
    private func sortToast(){
        if let top = topToast{
            let topIndex = find(toasts, top)!
            toasts.removeAtIndex(topIndex)
            toasts.insert(top, atIndex: 0)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toasts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("toastCell") as! ProfileToastCell
        cell.configureCell(toasts[indexPath.row],topToast: topToast)
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 182
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    //MARK: - Tableview delegate methods
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return isCurrentUser
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete{
            
            tableView.beginUpdates()
            toasts.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            tableView.endUpdates()
            
            let toast = toasts[indexPath.row]
            toast.deleteInBackgroundWithBlock({ (success, error) -> Void in
                if error != nil{
                    NSLog("%@",error.description)
                }
            })
        }
    }
}
