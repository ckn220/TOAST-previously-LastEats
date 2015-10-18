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

    //MARK: - IBOutlets properties
    //MARK: TopBar
    @IBOutlet weak var titleLabel: UILabel!
    //MARK: Header
    //User
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var userPictureView: BackgroundImageView!
    @IBOutlet weak var friendPictureView: BackgroundImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userSubtitleLabel: UILabel!
    @IBOutlet weak var toastMasterView: UIView!
    //Actions
    @IBOutlet weak var actionsView: UIView!
    @IBOutlet weak var starButton: StarButton!
    @IBOutlet weak var mapButton: ReviewDetailButton!
    //Stats
    @IBOutlet weak var toastCountLabel: UILabel!
    @IBOutlet weak var friendsCountLabel: UILabel!
    @IBOutlet weak var followersCountLabel: UILabel!
    //MARK: Body
    @IBOutlet weak var myTableView: UITableView!
    
    //MARK: - Variables
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
    
    //MARK: - Configure methods
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if fromContribute{
            configure()
            fromContribute = false
        }
    }
    
    private func configure(){
        configureTopBar()
        configureHeader()
        configureBody()
    }
    
    //MARK: TopBar
    private func configureTopBar(){
        configureSceneTitle()
    }
    
    private func configureSceneTitle(){
        if myUser.objectId == PFUser.currentUser()!.objectId{
            titleLabel.text = "My Profile"
        }else{
            var nameComponents = (myUser["name"] as! String).componentsSeparatedByString(" ")
            titleLabel.text = "\(nameComponents[0])'s Profile"
        }
    }
    
    //MARK: Header
    private func configureHeader(){
        configureUser()
        configureActions()
        configureStats()
    }
    
    //User
    private func configureUser(){
        configureUserPictures()
        configureUserName()
        configureUserSubtitle()
        configureToastMaster()
    }
    
    private func configureUserPictures(){
        func configureMainPicture(){
            userPictureView.setImage(user:myUser)
        }
        
        func configureSecondaryPicture(){
            if let friend = myFriend{
                friendPictureView.setImage(user:friend)
            }else{
                friendPictureView.removeFromSuperview()
            }
        }
        
        configureMainPicture()
        configureSecondaryPicture()
    }
    
    private func configureUserName(){
        userNameLabel.text = myUser["name"] as? String
    }
    
    private func configureUserSubtitle(){
        func date(forUser user:PFUser) -> String{
            let calendar = NSCalendar.currentCalendar()
            let date = user.createdAt
            let components = calendar.components([.Month,.Year], fromDate: date!)
            let months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
            
            return "\(months[components.month]) \(components.year)"
        }
        
        func correctedName(name:String) -> String{
            let originalCount = name.characters.count
            let limit = 14
            if originalCount > limit{
                var words = name.componentsSeparatedByString(" ")
                let newLastName = (words[1] as NSString).substringToIndex(1)
                return "\(words[0]) \(newLastName)."
            }else{
                return name
            }
        }
        
        var subtitleString:String
        if myUser.objectId == PFUser.currentUser()!.objectId{ // Current User
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
    
    private func configureToastMaster(){
        func insertToastMasterLabel(){
            toastMasterView.translatesAutoresizingMaskIntoConstraints = false
            userView.addSubview(toastMasterView)
            let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[subtitle]-4.0-[toastMaster]|", options: [], metrics: nil, views: ["subtitle":userSubtitleLabel,"toastMaster":toastMasterView])
            let centerXConstraint = NSLayoutConstraint(item: userSubtitleLabel, attribute: .CenterX, relatedBy: .Equal, toItem: toastMasterView, attribute: .CenterX, multiplier: 1, constant: 0)
            userView.addConstraints(vConstraints)
            userView.addConstraint(centerXConstraint)
        }
        
        PFCloud.callFunctionInBackground("isToastMaster", withParameters: ["userId":myUser.objectId!]) { (result, error) -> Void in
            if let error = error{
                NSLog("configureToastMaster error: %@", error)
            }else{
                if let resultString = result as? String,
                let resultInt = Int(resultString) where resultInt > 0{
                    insertToastMasterLabel()
                }
            }
        }
    }
    
    //Actions
    private func configureActions(){
        configureStarButton()
        configureMapButton()
    }
    
    private func configureStarButton(){
        func insertStarButton(){
            starButton.translatesAutoresizingMaskIntoConstraints = false
            actionsView.addSubview(starButton)
            let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[star]-12.0-[map]", options: [], metrics: nil, views: ["star":starButton,"map":mapButton])
            let centerYConstraint = NSLayoutConstraint(item: starButton, attribute: .CenterY, relatedBy: .Equal, toItem: mapButton, attribute: .CenterY, multiplier: 1, constant: 0)
            actionsView.addConstraints(hConstraints)
            actionsView.addConstraint(centerYConstraint)
        }
        
        func getFollow(completion: (isFollow:Bool) -> Void){
            let followQuery = PFUser.currentUser()!.relationForKey("follows").query()!
            followQuery.whereKey("objectId", equalTo: myUser.objectId!)
            followQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
                if error == nil {
                    completion(isFollow: Int(count) == 1)
                }else{
                    NSLog("getFollow error: %@",error!.description)
                }
            }
        }
        
        let currentUser = PFUser.currentUser()!
        if !currentUser.isEqual(myUser){
            insertStarButton()
            getFollow({ (isFollow) -> Void in
                self.starButton.isOn = isFollow
            })
        }
    }
    
    private func configureMapButton(){
        
    }
    
    //Stats
    private func configureStats(){
        configureToastsStats()
        configureFriendsStats()
        configureLikesStats()
    }
    
    private func configureToastsStats(){
        myUser.relationForKey("toasts").query()?.countObjectsInBackgroundWithBlock({ (toastCount, error) -> Void in
            if let error = error{
                NSLog("configureToastsStats error: %@",error.description)
            }else{
                self.toastCountLabel.text = String(format: "%02d",toastCount)
            }
        })
    }
    
    private func configureFriendsStats(){
        myUser.relationForKey("friends").query()?.countObjectsInBackgroundWithBlock({ (friendCount, error) -> Void in
            if let error = error{
                NSLog("configureFriendsStats error: %@",error.description)
            }else{
                self.friendsCountLabel.text = String(format:"%02d",friendCount)
            }
        })
    }
    
    private func configureLikesStats(){
        PFCloud.callFunctionInBackground("likesCountForUser", withParameters: ["userId":myUser.objectId!]) { (likesCount, error) -> Void in
            if let error = error{
                NSLog("configureLikesStats error: %@",error.description)
            }else{
                if let likesCount = likesCount as? Int{
                    self.followersCountLabel.text = String(format:"%02d",likesCount)
                }
            }
        }
    }
    
    //MARK: Body
    private func configureBody(){
        configureToasts()
    }
    
    private func configureToasts(){
        func complete(result:[PFObject]){
            self.toasts = result
            sortToast()
            profileDataSource = ProfileToastsDataSource(toasts: self.toasts!,user:self.myUser,myDelegate:self)
        }
        
        let query = PFQuery(className: "Toast")
        query.whereKey("active", equalTo: true)
        query.whereKey("user", equalTo: myUser)
        query.orderByDescending("createdAt")
        query.includeKey("user")
        query.includeKey("place")
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                complete(result!)
            }else{
                NSLog("loadToasts error: %@",error!.description)
            }
        }
    }
    
    private func sortToast(){
        for var k=0;k<toasts.count;k++ {
            let toast = toasts[k]
            if let isTopToast = toast["isTopToast"] as? Bool where isTopToast{
                toasts.removeAtIndex(k)
                toasts.insert(toast, atIndex: 0)
                break
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
        
        PFCloud.callFunctionInBackground(followFunction, withParameters: ["userId":myUser.objectId!]) { (result, error) -> Void in
            if let error = error{
                NSLog("starButtonPressed error: %@",error.description)
            }else{
                //sender.toggleButton()
            }
        }
    }
    
    @IBAction func friendsStatsPRessed(sender: MyControl) {
        let friendsScene = storyboard?.instantiateViewControllerWithIdentifier("friendsListScene") as! FriendsListViewController
        friendsScene.myUser = myUser
        showViewController(friendsScene, sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "friendsListSegue"{
            let destination = segue.destinationViewController as! FriendsListViewController
            destination.myUser = myUser
            destination.fromMain = false
        }else if segue.identifier == "contributeSegue"{
            fromContribute = true
        }else if segue.identifier == "mapSegue"{
            let destination = segue.destinationViewController as! MapViewController
            destination.myDelegate = nil
            destination.userFromProfileDetail  = myUser
        }
    }
    
    //MARK: - ProfileToastsDelegate methods
    func profileToastsCellPressed(indexPressed: Int,place:PFObject?) {
        let destination = storyboard?.instantiateViewControllerWithIdentifier("reviewDetailScene") as! ReviewDetailViewController
        let selectedToast = toasts![indexPressed]
        destination.myToast = selectedToast
        if place != nil{
            destination.titleString = place!["name"] as? String
        }
        
        self.showViewController(destination, sender: self)
    }
    
    func profileToastsItemDeleted(updatedToasts:[PFObject]) {
        self.toasts = updatedToasts
        toastCountLabel.text = String(format:"%02d",toasts.count)
    }
    
}
