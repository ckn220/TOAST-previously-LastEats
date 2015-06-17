//
//  ProfileDetailViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 3/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

class ProfileDetailViewController: UIViewController,ProfileToastsDelegate {

    @IBOutlet weak var myTableView: UITableView!
    
    @IBOutlet weak var friendPictureWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var friendPictureView: BackgroundImageView!
    @IBOutlet weak var userPictureView: BackgroundImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var toastCountLabel: UILabel!
    @IBOutlet weak var friendsCountLabel: UILabel!
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var starButton: StarButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var userSubtitleLabel: UILabel!
    
    var fromContribute = true
    var myDelegate:DiscoverDelegate?
    var toasts: [PFObject]!
    var topToast: PFObject?
    var myUser:PFUser!
    var myFriend:PFUser?
    var profileDataSource:ProfileToastsDataSource!{
        didSet{
            myTableView.dataSource = profileDataSource
            myTableView.delegate = profileDataSource
            myTableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if fromContribute{
            configure()
            fromContribute = false
        }
    }
    
    private func configure(){
        configureTitles()
        configureUserHeader()
        configureUserToasts()
        setStarButton()
    }
    
    private func configureTitles(){
        configureMyTitle()
        configureUserSubtitle()
    }
    
    private func configureMyTitle(){
        if myUser.objectId == PFUser.currentUser().objectId{
            titleLabel.text = "My Profile"
        }else{
            var nameComponents = (myUser["name"] as! String).componentsSeparatedByString(" ")
            titleLabel.text = "\(nameComponents[0])'s Profile"
        }
    }
    
    private func configureUserSubtitle(){
        var subtitleString:String
        if myUser.objectId == PFUser.currentUser().objectId{ // Current User
            subtitleString = "Toasting since \(date(forUser: myUser))"
        }else if myUser.objectId == "Ljr4MlYQP0"{ // Colin
            subtitleString = "Founder of Top Toast Labs"
        }else{
            if myFriend != nil{ //Friend of friend
                let friendName = myFriend!["name"] as! String
                subtitleString = "Friends with \(correctedName(friendName)) on Facebook"
            }else{ //Friend
                let name = myUser["name"] as! String
                let nameComponents = name.componentsSeparatedByString(" ")
                subtitleString = "You are friends with \(nameComponents[0]) on Facebook"
            }
        }
        
        userSubtitleLabel.text = subtitleString
    }
    
    private func date(forUser user:PFUser) -> String{
        let calendar = NSCalendar.currentCalendar()
        let date = user.createdAt
        let components = calendar.components(.CalendarUnitMonth | .CalendarUnitYear, fromDate: date)
        let months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
        
        return "\(months[components.month]) \(components.year)"
    }
    
    private func correctedName(name:String) -> String{
        let originalCount = count(name)
        let limit = 14
        if originalCount > limit{
            var words = name.componentsSeparatedByString(" ")
            let newLastName = (words[1] as NSString).substringToIndex(1)
            return "\(words[0]) \(newLastName)."
        }else{
            return name
        }
    }
    
    private func configureUserToasts(){
        let group = dispatch_group_create()
        loadToasts(group: group)
        loadTopToast(group: group)
        configureUserToastsCompletion(group: group)
    }
    
    private func loadTopToast(#group: dispatch_group_t){
        dispatch_group_enter(group)
        PFCloud.callFunctionInBackground("topToastFromUser", withParameters: ["userId":myUser.objectId]) { (topToast, error) -> Void in
            if error == nil{
                self.topToast = topToast as? PFObject
            }else{
                NSLog("loadTopToast error: %@",error.description)
            }
            dispatch_group_leave(group)
        }
    }
    
    private func loadToasts(#group: dispatch_group_t){
        dispatch_group_enter(group)
        let query = PFQuery(className: "Toast")
        query.whereKey("active", equalTo: true)
        query.whereKey("user", equalTo: myUser)
        query.orderByDescending("createdAt")
        query.includeKey("user")
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.toasts = result as! [PFObject]
            }else{
                NSLog("loadToasts error: %@",error.description)
                self.toasts = []
            }
            
            dispatch_group_leave(group)
        }
    }
    
    private func sortToast(){
        for k in 0...(toasts.count-1){
            let toast = toasts![k]
            if toast.objectId == topToast?.objectId{
                toasts.removeAtIndex(k)
                toasts.insert(toast, atIndex: 0)
                break
            }
        }
    }
    
    private func configureUserToastsCompletion(#group: dispatch_group_t){
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            self.sortToast()
            self.updateToastCount()
            self.profileDataSource = ProfileToastsDataSource(toasts: self.toasts!,user:self.myUser,topToast:self.topToast,myDelegate:self)
        }
    }
    
    private func configureUserHeader(){
        configureProfileImage()
        configureFriendImage()
        configureProfileName(myUser)
        configureCountLabels(myUser)
    }
    
    private func configureProfileImage(){
        getPicture(fromUser: myUser, toBgView: userPictureView)
    }
    
    private func configureFriendImage(){
        if myFriend != nil{
            getPicture(fromUser: myFriend!, toBgView: friendPictureView)
        }else{
            friendPictureWidthConstraint.constant = 0
        }
    }
    
    private func getPicture(fromUser user:PFUser,toBgView bgView:BackgroundImageView){
        initPictureView(bgView)
        let imageURL = user["pictureURL"] as! String
        bgView.setImage(URL: imageURL)
    }
    
    private func initPictureView(pictureView:BackgroundImageView){
        let pictureLayer = pictureView.layer
        pictureLayer.cornerRadius = CGRectGetWidth(pictureLayer.bounds)/2
        pictureLayer.borderWidth = 1
        pictureLayer.borderColor = UIColor.whiteColor().CGColor
    }
    
    private func configureProfileName(user:PFUser){
        userNameLabel.text = user["name"] as! String!
    }
    
    private func configureCountLabels(user:PFUser){
        configureToastCount(user)
        configureFriendCount(user)
        configureFollowerCount(user)
    }
    
    private func initCountLabel(label:UILabel){
        let layer = label.layer
        layer.cornerRadius = CGRectGetWidth(label.bounds)/2
        layer.borderWidth = 1
        layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    private func configureToastCount(user:PFUser){
        initCountLabel(toastCountLabel)
    }
    
    private func updateToastCount(){
        toastCountLabel.text = String(format:"%02d",toasts.count)
    }
    
    private func configureFriendCount(user:PFUser){
        initCountLabel(friendsCountLabel)
        let friendsQuery = user.relationForKey("friends").query()
        friendsQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                self.friendsCountLabel.text = String(format: "%02d", count)
            }else{
                NSLog("configureFriendCount error: %@",error.description)
            }
        }
    }
    
    private func configureFollowerCount(user:PFUser){
        initCountLabel(followersCountLabel)
        let followerQuery = PFQuery(className: "User")
        followerQuery.whereKey("follows", equalTo: user)
        followerQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                self.followersCountLabel.text = String(format: "%02d", count)
            }else{
                NSLog("configureFollowerCount error: %@",error.description)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setStarButton(){
        if myUser.objectId == PFUser.currentUser().objectId{ //currentUser
            starButton.alpha = 0
        }else{ //friend
            getFollow({ (isFollow) -> Void in
                self.starButton.isOn = isFollow
            })
        }
    }
    
    private func getFollow(completion: (isFollow:Bool) -> Void){
        let followQuery = PFUser.currentUser().relationForKey("follows").query()
        followQuery.whereKey("objectId", equalTo: myUser.objectId)
        followQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil {
                completion(isFollow: Int(count) == 1)
            }else{
                NSLog("getFollow error: %@",error.description)
            }
        }
    }

    //MARK: - Action methods
    @IBAction func backPressed(sender: UIButton) {
        if myDelegate == nil{
            self.navigationController?.popViewControllerAnimated(true)
        }else{
            myDelegate?.discoverMenuPressed()
        }
    }
    
    @IBAction func starButtonPressed(sender: StarButton) {
        var followFunction:String
        if sender.isOn{
            followFunction = "followUser"
        }else{
            followFunction = "unfollowUser"
        }
        
        PFCloud.callFunctionInBackground(followFunction, withParameters: ["userId":myUser.objectId]) { (result, error) -> Void in
            if error != nil{
                NSLog("starButtonPressed error: %@",error.description)
                //sender.toggleButton()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "friendsListSegue"{
            let destination = segue.destinationViewController as! FriendsListViewController
            destination.myUser = myUser
            destination.fromMain = false
        }else if segue.identifier == "contributeSegue"{
            fromContribute = true
        }
    }
    
    private func configurePicture(pictureLayer:CALayer){
        pictureLayer.cornerRadius = CGRectGetWidth(pictureLayer.bounds)/2.0
        pictureLayer.borderWidth = 1
        pictureLayer.borderColor = UIColor(white: 1, alpha: 0.7).CGColor
        pictureLayer.shouldRasterize = true
    }
    
    //MARK: - ProfileToastsDelegate methods
    func profileToastsCellPressed(indexPressed: Int,place:PFObject?) {
        let destination = storyboard?.instantiateViewControllerWithIdentifier("reviewDetailScene") as! ReviewDetailViewController
        let selectedToast = toasts![indexPressed]
        destination.myToast = selectedToast
        if place != nil{
            destination.titleString = place!["name"] as! String
        }
        destination.isTopToast = topToast?.objectId == selectedToast.objectId
        
        self.showViewController(destination, sender: self)
    }
    
    func profileToastsItemDeleted(updatedToasts:[PFObject]) {
        self.toasts = updatedToasts
        updateToastCount()
    }
    
}
