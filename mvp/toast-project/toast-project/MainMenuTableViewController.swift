//
//  MainMenuTableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/15/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class MainMenuTableViewController: UITableViewController {

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
        let myAppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        myAppDelegate.goToLogin()
    }

}
