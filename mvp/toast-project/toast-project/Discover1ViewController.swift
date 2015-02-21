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

class Discover1ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,CLLocationManagerDelegate{
    
    var locationManager: CLLocationManager?
    var moods:[PFObject]?
    var myDelegate:DiscoverDelegate?
    var favoriteFriends:[PFObject]?
    var friends:[PFObject]?
    var currentUser:PFUser?

    @IBOutlet weak var moodsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moods = []
        favoriteFriends = []
        friends = []
        moodsTableView.estimatedRowHeight = 50
        moodsTableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        PFUser.currentUser().fetchIfNeededInBackgroundWithBlock({ (result, error) -> Void in
            self.currentUser = result as? PFUser
            self.getFavoriteFriends()
            self.getFriends()
            self.configureLocation()
        })
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
    
    func getMoods(){
        let moodsQuery = PFQuery(className: "Mood")
        moodsQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.moods = result as? [PFObject]
                self.moodsTableView.reloadData()
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
        if let cell = self.moodsTableView.cellForRowAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? MoodsHeaderTableViewCell{
            cell.friendsLikeCollectionView.reloadData()
        }
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

    //MARK: Tableview methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return moods!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        if indexPath.row == 0{
            cell = tableView.dequeueReusableCellWithIdentifier("moodsHeaderCell") as MoodsHeaderTableViewCell
            (cell as MoodsHeaderTableViewCell).friendsLikeCollectionView.reloadData()
        }else{
            cell = tableView.dequeueReusableCellWithIdentifier("moodCell") as UITableViewCell
            let currentMood = moods![indexPath.row]
            cell.textLabel?.text = (currentMood["name"] as? String)?.uppercaseString
        }
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("hungryCell") as UITableViewCell

        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    //MARK: Scrollview delegate methods
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let headerCell:MoodsHeaderTableViewCell? = moodsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? MoodsHeaderTableViewCell
        
        if headerCell != nil{
            let friendsLikeCollection = headerCell!.friendsLikeCollectionView
            let scrollY = scrollView.contentOffset.y
            
            let newAlpha:CGFloat = 1 - scrollY/60
            friendsLikeCollection.alpha = newAlpha
            if newAlpha <= 0{
                let hungryHeader = moodsTableView.headerViewForSection(0)
                hungryHeader?.backgroundColor = UIColor.whiteColor()
                hungryHeader?.contentView.backgroundColor = UIColor.whiteColor()
            }
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
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("friendsLikeCell", forIndexPath: indexPath) as FriendsLikeCollectionViewCell
            cell.friendPictureView.layer.cornerRadius = CGRectGetWidth(cell.friendPictureView.frame)/2
            cell.friendCountLabel.layer.cornerRadius = CGRectGetWidth(cell.friendCountLabel.frame)/2
            
            var currentFriend:PFObject
            if indexPath.row < favoriteFriends?.count {
                currentFriend = favoriteFriends![indexPath.row]
            }else{
                currentFriend = friends![indexPath.row]
            }
            let firstName = (currentFriend["name"] as String).componentsSeparatedByString(" ")[0]
            cell.friendNameLabel.text = firstName.uppercaseString + " LIKES"
            insertToastCount(ofFriend: currentFriend, toCell: cell)
            insertPicture(ofFriend: currentFriend, toCell: cell)
            
            return cell
        }else{
            let inviteCell = collectionView.dequeueReusableCellWithReuseIdentifier("inviteFriendsCell", forIndexPath: indexPath) as UICollectionViewCell
            inviteCell.viewWithTag(101)?.layer.cornerRadius = 35
            
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier != "newToastSegue" {
            let destination = segue.destinationViewController as ToastsViewController
            if segue.identifier == "moodDetailSegue"{
                let selectedIndexPath = moodsTableView.indexPathForSelectedRow()
                let selectedMood = moods![selectedIndexPath!.row]
                destination.myMood = selectedMood
                
            }else if segue.identifier == "friendToastsDetailSegue"{
                let friendsCollection = (moodsTableView.cellForRowAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as MoodsHeaderTableViewCell).friendsLikeCollectionView
                let selectedIndexPath = friendsCollection.indexPathsForSelectedItems()[0] as NSIndexPath
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
