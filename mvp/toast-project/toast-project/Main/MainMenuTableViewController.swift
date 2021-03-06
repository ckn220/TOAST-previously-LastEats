//
//  MainMenuTableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/15/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

protocol MainMenuTableDelegate{
    func mainMenuTableDiscoverPressed()
    func mainMenuTableMapPressed()
    func mainMenuTableAcvititvyPressed()
    func mainMenuTableMyToastsPressed()
    func mainMenuTableFriendsPressed()
    func mainMenuTableInviteAFriendPressed()
    func mainMenuTableContributePressed()
    func mainMenuTableContactUsPressed()
}

class MainMenuTableViewController: UITableViewController {

    var myDelegate:MainMenuTableDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        switch indexPath.section{
        case 0:
            if indexPath.row == 0{
                discoverPressed()
            }else if indexPath.row == 1{
                mapPressed()
            }else{
                activityPressed()
            }
        case 1:
            if indexPath.row == 0{
                contributePressed()
            }else if indexPath.row == 1{
                myToastsPressed()
            }else if indexPath.row == 2{
                friendsPressed()
            }else{
                inviteAFriendPressed()
            }
        case 2:
            if indexPath.row == 0{
                contactUsPressed()
            }else{
                logoutPressed()
            }
        default:
            return
        }
    }
    
    private func discoverPressed(){
        myDelegate?.mainMenuTableDiscoverPressed()
    }
    
    private func mapPressed(){
        myDelegate?.mainMenuTableMapPressed()
    }
    
    private func activityPressed(){
        myDelegate?.mainMenuTableAcvititvyPressed()
    }
    
    private func contributePressed(){
        myDelegate?.mainMenuTableContributePressed()
    }
    
    private func myToastsPressed(){
        myDelegate?.mainMenuTableMyToastsPressed()
    }
    
    private func friendsPressed(){
        myDelegate?.mainMenuTableFriendsPressed()
    }
    
    private func inviteAFriendPressed(){
        myDelegate?.mainMenuTableInviteAFriendPressed()
    }
    
    private func contactUsPressed(){
        myDelegate?.mainMenuTableContactUsPressed()
    }
    
    private func logoutPressed(){
        let myAppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        myAppDelegate.goToLogin()
    }

}
