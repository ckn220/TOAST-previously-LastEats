//
//  ReviewDetailTableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 3/20/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire

class ReviewDetailTableViewController: UITableViewController {

    var myToast:PFObject?
    var myHashtags:[PFObject] = []
    
    @IBOutlet weak var heartButton: HeartButton!
    @IBOutlet weak var followButton: FollowButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    func configure(){
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        configureHashtags()
        configureButtons()
    }
    
    private func configureHashtags(){
        
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
    
    private func configureButtons(){
        if isOwnToast(){
            heartButton.enabled = false
            heartButton.alpha = 0.5
            configureHeartCount()
            
            followButton.alpha = 0
        }else{
            configureHeart()
            configureFollow()
        }
    }
    
    private func isOwnToast() -> Bool{
        return (myToast!["user"] as! PFUser).objectId == PFUser.currentUser()!.objectId
    }
    
    private func configureHeartCount(){
        let userQuery = PFQuery(className: "User")
        userQuery.whereKey("hearts", equalTo: myToast!)
        userQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                self.heartButton.setTitle("\(count)", forState: .Normal)
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    private func configureHeart(){
        let heartQuery = PFUser.currentUser().relationForKey("hearts").query()
        heartQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                let hearts = result as! [PFObject]
                let heartsCount = hearts.count
                    if heartsCount > 0{
                        let index = find(hearts,self.myToast!)
                        if index >= 0{
                            self.heartButton.toggleButton()
                        }
                    }
            }
        }
    }
    
    private func configureFollow(){
        let toastUser = myToast!["user"] as! PFUser
        let followQuery = PFUser.currentUser().relationForKey("follows").query()
        followQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                let follows = result as! [PFObject]
                if follows.count > 0{
                    let index = find(follows,toastUser)
                    if index >= 0{
                        self.followButton.toggleButton()
                    }
                }
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
        return 2
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
        
        Alamofire.request(.GET,(myToast?["user"] as! PFUser)["pictureURL"] as! String).response({(request,response,data,error) -> Void in
            if error == nil{
                pictureView.myImage = UIImage(data: data as! NSData)
            }else{
                NSLog("%@", error!.description)
            }
        })
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
        let reviewLinkView = cell.viewWithTag(1001) as! CCHLinkTextView
        let reviewString = myToast!["review"] as! String
        setLinkableReview(reviewString, view: reviewLinkView)
    }
    
    private func setLinkableReview(review:String,view:CCHLinkTextView){
        configureLinkView(view)
        var words = review.componentsSeparatedByString(" ")
        var finalReview = NSMutableAttributedString(string: "")
        for word in words{
            finalReview.appendAttributedString(attributedWord(word))
            finalReview.appendAttributedString(attributedWord(" "))
        }
        view.attributedText = finalReview
        view.layoutIfNeeded()
    }
    
    private func configureLinkView(view:CCHLinkTextView){
        view.linkTextAttributes = [NSForegroundColorAttributeName:UIColor(hue:0.555, saturation:0.45, brightness:1, alpha:1)]
        view.linkTextTouchAttributes = [NSForegroundColorAttributeName:UIColor(hue:0.555, saturation:0.45, brightness:0.7, alpha:1),NSBackgroundColorAttributeName:UIColor.clearColor()]
    }
    
    private func attributedWord(word:String)->NSAttributedString{
        if let hashIndex = find(word,"#"){
            return attributedHashtag(word)
        }else{
            return attributedNormal(word)
        }
    }
    
    private func attributedNormal(word:String)->NSAttributedString{
        return NSAttributedString(string: word, attributes: myAttributes())
    }
    
    private func attributedHashtag(hashtag:String)->NSAttributedString{
        var attr = myAttributes()
        attr[CCHLinkAttributeName] = 0
        return NSAttributedString(string: hashtag, attributes: attr)
    }
    
    private func myAttributes() -> [NSObject:AnyObject]{
        var attributes = [NSObject:AnyObject]()
        attributes[NSFontAttributeName] = UIFont(name: "Avenir-Medium", size: 16)
        attributes[NSForegroundColorAttributeName] = UIColor.whiteColor()
        return attributes
    }
    
    func configureHashtag(#cell:UITableViewCell,index:Int){
        let currentHashtag = myHashtags[index]
        let hashtagLabel = cell.viewWithTag(101) as! UILabel
        hashtagLabel.text = "#" + (currentHashtag["name"] as! String)
    }
    
    //MARK: - Action methods
    
    @IBAction func heartButtonPressed(sender: HeartButton) {
        var heartFunction = "heartToast"
        if !sender.isOn{
            heartFunction = "unheartToast"
        }
        
        PFCloud.callFunctionInBackground(heartFunction, withParameters: ["toastId":myToast!.objectId]) { (result, error) -> Void in
            if error != nil{
                NSLog("%@",error.description)
            }
        }
    }
    
    @IBAction func followButtonPressed(sender: FollowButton) {
        var followFunction = "followUser"
        if !sender.isOn{
            followFunction = "unfollowUser"
        }
        
        let user = (myToast!["user"] as! PFUser).objectId
        PFCloud.callFunctionInBackground(followFunction, withParameters: ["userId":user]) { (result, error) -> Void in
            if error != nil{
                NSLog("%@",error.description)
            }
        }
    }
    
    
}
