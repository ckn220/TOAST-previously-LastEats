//
//  DiscoverTableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 1/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class DiscoverTableViewController: UITableViewController {
    
    var toasts : [PFObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toasts = []
        tableView.estimatedRowHeight = 126
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshToasts()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshToasts(){
        let query = PFQuery(className: "Toast")
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            
            if error == nil{
                self.toasts = result as? [PFObject]
                self.tableView.reloadData()
            }else{
                NSLog("%@", error.description)
            }
            
        }
    }

    @IBAction func refreshDidPressed(sender: AnyObject) {
        refreshToasts()
    }
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return toasts!.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("toastCell", forIndexPath: indexPath) as ToastTableViewCell

        // Configure the cell...
        let currentToast = toasts?[indexPath.row]
        
        var place = currentToast!["place"] as PFObject
        place.fetchIfNeededInBackgroundWithBlock { (result: PFObject!, error) -> Void in
            if error == nil{
                cell.placeLabel.text = result["name"] as? String
            }else{
                NSLog("%@", error.description)
            }
        }
        
        var user = currentToast!["user"] as PFObject
        user.fetchIfNeededInBackgroundWithBlock { (result: PFObject!, error) -> Void in
            if error == nil{
                cell.userLabel.text = "from " + (result["name"] as? String)!
            }else{
                NSLog("%@", error.description)
            }
        }
        
        let qualitiesRelation = currentToast?.relationForKey("moods")
        qualitiesRelation?.query().findObjectsInBackgroundWithBlock({ (result : [AnyObject]!, error) -> Void in
            if error == nil{
                var qualitiesString = ""
                
                for q:PFObject in result as [PFObject] {
                    qualitiesString += q["name"] as String
                    
                    if result.last?.isEqual(q) == false{
                        qualitiesString += ", "
                    }
                    
                }
                
                cell.qualitiesLabel.text = qualitiesString
            }else{
                NSLog("%@", error.description)
            }
        })
        
        let hashtagsRelation = currentToast?.relationForKey("hashtags")
        hashtagsRelation?.query().findObjectsInBackgroundWithBlock({ (result : [AnyObject]!, error) -> Void in
            if error == nil{
                var hashtagsString = ""
                
                for q:PFObject in result as [PFObject] {
                    hashtagsString += "#"+(q["name"] as String)+" "
                }
                
                cell.hashtagsLabel.text = hashtagsString
            }else{
                NSLog("%@", error.description)
            }
        })
        
        return cell
    }

}
