//
//  ProfileToastsDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 3/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol ProfileToastsDelegate{
    func profileToastsCellPressed(indexPressed:Int,place:PFObject?)
}

class ProfileToastsDataSource: NSObject,UITableViewDataSource,UITableViewDelegate,ProfileToastCellDelegate {
    var toasts: [PFObject]!
    var user:PFUser!
    var topToast: PFObject?
    var isCurrentUser=false
    var myDelegate:ProfileToastsDelegate?
    var placesTemp = [Int:PFObject]()
    
    init(toasts:[PFObject],user:PFUser,topToast: PFObject?,myDelegate:ProfileToastsDelegate){
        super.init()
        self.toasts = toasts
        self.user = user
        self.topToast = topToast
        self.myDelegate = myDelegate
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
        for k in 0...(toasts.count-1){
            let toast = toasts[k]
            if toast.objectId == topToast?.objectId{
                toasts.removeAtIndex(k)
                toasts.insert(toast, atIndex: 0)
                break
            }
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
        cell.configureCell(indexPath.row,toast:toasts[indexPath.row],topToast: topToast,myDelegate:self)
        
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! ProfileToastCell
        myDelegate?.profileToastsCellPressed(indexPath.row,place:cell.myPlace)
    }
    
    //MARK: - Cell delegate
    func profileToastCellGotPlace(place:PFObject?,atIndex index:Int) {
        placesTemp[index] = place
    }
    
    func getPlace(index: Int) -> PFObject? {
        return placesTemp[index]
    }
}
