//
//  Discover1ViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol DiscoverDelegate {
    func discoverMenuPressed()
    func discoverDidAppear()
    func discoverDidDissapear()
}

class Discover1ViewController: UIViewController, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,CLLocationManagerDelegate{
    
    var locationManager: CLLocationManager?
    var moods:[PFObject]?
    var myDelegate:DiscoverDelegate?
    var favoriteFriends:[PFObject]?
    var friends:[PFObject]?
    var currentUser:PFUser?
    
    @IBOutlet weak var myBG: BackgroundImageView!

    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var friendsBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var friendsCollectionView: UICollectionView!
    @IBOutlet weak var moodButtonView: UIVisualEffectView!
    @IBOutlet weak var locationButtonView: UIVisualEffectView!
    @IBOutlet weak var userPictureView: UIImageView!
    
    //MARK: - Superview methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moods = []
        favoriteFriends = []
        friends = []
        
        currentUser = PFUser.currentUser()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
            self.configureBG()
            self.configureUserPicture()
            self.configureButtons()
            self.getFavoriteFriends()
            self.getFriends()
            self.configureLocation()
            getMoods()
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        myDelegate?.discoverDidAppear()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        myDelegate?.discoverDidDissapear()
    }
    
    //MARK: - Configure methods
    func configureBG(){
        myBG.insertImage(UIImage(named: "mainBG")!, withOpacity: 0.6)
    }
    
    func configureUserPicture(){
        let pictureFile = currentUser!["profilePicture"] as PFFile
        pictureFile.getDataInBackgroundWithBlock { (data, error) -> Void in
            if error == nil {
                self.userPictureView.image = UIImage(data: data)
                self.userPictureView.layer.cornerRadius = 11
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    func configureButtons(){
        let locationLayer = locationButtonView.layer
        locationLayer.borderColor = UIColor.whiteColor().CGColor
        locationLayer.borderWidth = 1
        
        let moodLayer = moodButtonView.layer
        moodLayer.borderColor = UIColor.whiteColor().CGColor
        moodLayer.borderWidth = 1
    }
    
    func getMoods(){
        let moodsQuery = PFQuery(className: "Mood")
        moodsQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.moods = result as? [PFObject]
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    func getFavoriteFriends(){
        let favoritesQuery = currentUser!.relationForKey("favorites").query()
        favoritesQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.favoriteFriends = result as? [PFObject]
                self.reloadFriendsColletion()
                
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    func getFriends(){
        let friendsQuery = currentUser!.relationForKey("friends").query()
        friendsQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.friends = result as? [PFObject]
                self.reloadFriendsColletion()
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    func reloadFriendsColletion(){
        
    }
    
    func configureLocation(){
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        triggerLocationServices()
    }
    
    //MARK: CoreLocation methods
    func triggerLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            if self.locationManager!.respondsToSelector("requestWhenInUseAuthorization") {
                locationManager?.requestWhenInUseAuthorization()
            } else {
                startUpdatingLocation()
            }
        }
        
        var b:UIButton
    }
    
    func startUpdatingLocation() {
        locationManager?.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status{
        case .AuthorizedWhenInUse:
            startUpdatingLocation()
        case .NotDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            let alertController = UIAlertController(
                title: "Location Access Disabled",
                message: "In order to recieve accurate places information, please open this app's settings and set location access to 'While Using the App'.",
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let lastLocation = locations.last as CLLocation
        if lastLocation.timestamp.timeIntervalSinceNow > -30 {
            let geoPoint = PFGeoPoint(location: lastLocation)
            currentUser?["lastLocation"]=geoPoint
            currentUser?.saveEventually(nil)
            manager.stopUpdatingLocation()
        }
        
    }
    
    //MARK: Collectionview methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let totalCount = favoriteFriends!.count + friends!.count
        if totalCount > 0{
            return min(6, totalCount)
        }else{
            return 1
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if favoriteFriends!.count + friends!.count > 0 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("friendsCell", forIndexPath: indexPath) as FriendsLikeCollectionViewCell
            cell.friendPictureView.layer.cornerRadius = CGRectGetWidth(cell.friendPictureView.frame)/2
            cell.friendCountLabel.layer.cornerRadius = CGRectGetWidth(cell.friendCountLabel.frame)/2
            
            var currentFriend:PFObject
            if indexPath.row < favoriteFriends?.count {
                currentFriend = favoriteFriends![indexPath.row]
            }else{
                currentFriend = friends![indexPath.row]
            }
            let firstName = (currentFriend["name"] as String).componentsSeparatedByString(" ")[0]
            cell.friendNameLabel.text = firstName+"'s " + "Toasts"
            insertToastCount(ofFriend: currentFriend, toCell: cell)
            insertPicture(ofFriend: currentFriend, toCell: cell)
            
            return cell
        }else{
            let inviteCell = collectionView.dequeueReusableCellWithReuseIdentifier("inviteFriendsCell", forIndexPath: indexPath) as UICollectionViewCell
            inviteCell.viewWithTag(101)?.layer.cornerRadius = 32
            
            return inviteCell
        }
    }
    
    func insertToastCount(ofFriend friend:PFObject,toCell cell:FriendsLikeCollectionViewCell){
        let toastQuery = PFQuery(className: "Toast")
        toastQuery.whereKey("user", equalTo: friend)
        toastQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                cell.friendCountLabel.text = "\(result.count)"
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    func insertPicture(ofFriend friend:PFObject,toCell cell:FriendsLikeCollectionViewCell){
        let pictureFile = friend["profilePicture"] as PFFile
        pictureFile.getDataInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                cell.friendPictureView.insertImage(UIImage(data: result)!)
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    //MARK: Action methods
    @IBAction func menuPressed(sender: AnyObject) {
        myDelegate?.discoverMenuPressed()
        
    }
    
    @IBAction func locationButtonPressed(sender: UITapGestureRecognizer) {
        //animatePressed(buttonView: sender.view!.viewWithTag(301)!)
    }
    
    @IBAction func moodButtonPressed(sender: UITapGestureRecognizer) {
        animatePressed(buttonView: sender.view!.viewWithTag(301)!)
        
        let destination = storyboard?.instantiateViewControllerWithIdentifier("selectMoodScene") as SelectMoodViewController
        destination.moods = moods
        self.showViewController(destination, sender: self)
    }
    
    func animatePressed(#buttonView:UIView){
        UIView.animateKeyframesWithDuration(0.1, delay: 0, options: .CalculationModePaced, animations: { () -> Void in
            
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.1, animations: { () -> Void in
                buttonView.alpha = 0.4
            })
            
            }, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier != "newToastSegue" {
            let destination = segue.destinationViewController as ToastsViewController
            
            if segue.identifier == "friendToastsDetailSegue"{
                
                let selectedIndexPath = friendsCollectionView.indexPathsForSelectedItems()[0] as NSIndexPath
                destination.myFriend = getFriend(fromIndexPath: selectedIndexPath)
            }
        }
    }
    
    func getFriend(fromIndexPath indexPath:NSIndexPath) -> PFObject{
        let row = indexPath.row
        if row < favoriteFriends?.count {
            return favoriteFriends![row]
        }else{
            return friends![row]
        }
    }
}
