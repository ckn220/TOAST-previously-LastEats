//
//  ReviewDetailTableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 3/20/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ReviewDetailTableViewController: UITableViewController {

    var myToast:PFObject?
    var myHashtags:[PFObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    func configure(){
        tableView.rowHeight = UITableViewAutomaticDimension
        configureHashtags()
    }
    
    func configureHashtags(){
        
            let query = PFQuery(className: "Hashtag")
            query.whereKey("toasts", equalTo: myToast)
            query.orderByAscending("name")
            query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
                if error == nil{
                    self.myHashtags = result as! [PFObject]
                    self.tableView.reloadData()
                }else{
                    NSLog("%@", error.description)
                }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return 2 + myHashtags.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        switch indexPath.row{
        case 0:
            cell = tableView.dequeueReusableCellWithIdentifier("reviewerCell") as! UITableViewCell
            configureReviewer(cell: cell)
        case 1:
            cell = tableView.dequeueReusableCellWithIdentifier("reviewCell") as! UITableViewCell
            configureReview(cell: cell)
        default:
            cell = tableView.dequeueReusableCellWithIdentifier("hashtagCell") as! UITableViewCell
            configureHashtag(cell: cell, index: indexPath.row - 2)
        }
        return cell
    }
    
    func configureReviewer(#cell:UITableViewCell){
        setProfilePicture(cell: cell)
        setName(cell: cell)
    }
    
    func setProfilePicture(#cell:UITableViewCell){
        let pictureView = cell.viewWithTag(501) as! BackgroundImageView
        configurePictureView(pictureView)
        let pictureFile = (myToast?["user"] as! PFUser)["profilePicture"] as! PFFile
        pictureFile.getDataInBackgroundWithBlock { (data, error) -> Void in
            if error == nil{
                pictureView.myImage = UIImage(data: data)
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    func configurePictureView(pictureView:BackgroundImageView){
        let layer = pictureView.layer
        layer.cornerRadius = CGRectGetWidth(layer.frame)/2
        layer.borderColor = UIColor(white: 1, alpha: 0.7).CGColor
        layer.borderWidth = 1.0
    }
    
    func setName(#cell:UITableViewCell){
        let nameLabel = cell.viewWithTag(101) as! UILabel
        nameLabel.text = (myToast?["user"] as! PFUser)["name"] as? String
    }
    
    func configureReview(#cell:UITableViewCell){
        let reviewLabel = cell.viewWithTag(101) as! UILabel
        reviewLabel.text = "\""+(myToast?["review"] as! String)+"\""
    }
    
    func configureHashtag(#cell:UITableViewCell,index:Int){
        let currentHashtag = myHashtags[index]
        let hashtagLabel = cell.viewWithTag(101) as! UILabel
        hashtagLabel.text = "#" + (currentHashtag["name"] as! String)
    }

}
