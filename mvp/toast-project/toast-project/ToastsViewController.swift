//
//  ToastsViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

class ToastsViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,PlaceCellDelegate {
    
    var myMood:PFObject?
    var myHashtagName:String?
    var myCategory: PFObject?
    var myPlaces:[PFObject]?
    var myFriend:PFObject?
    var myCurrentPlace: PFObject?
    var myNeighborhood:PFObject?
    var currentReviewsTableView:UITableView?
    var currentIndexPath:NSIndexPath?
    var localHashtags = [String:[PFObject]]()
    var localReviews = [String:[PFObject]]()
    var myDelegate:DiscoverDelegate?
    @IBOutlet weak var myBG: BackgroundImageView!
    
    var lastBG = ""{
        didSet{
            lastBG = lastBG + "-blur"
        }
    }
    let bgQueue = NSOperationQueue()
    
    @IBOutlet weak var myBlurBG: UIVisualEffectView!
    @IBOutlet weak var myBG1: BackgroundImageView!
    @IBOutlet weak var myBG2: BackgroundImageView!
    @IBOutlet weak var toastsCollectionView: UICollectionView!
    @IBOutlet weak var moodTitleLabel: UILabel!
    @IBOutlet weak var placeTitleLabel: UILabel!
    @IBOutlet weak var placeCloseButton: UIButton!
    @IBOutlet weak var pickupButton: UIButton!
    @IBOutlet weak var reservationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        getPlaces()
    }
    
    func configure(){
        myPlaces = []
        toastsCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
        configureTitle()
    }
    
    private func configureTitle(){
        var titleText = ""
        if myMood != nil{
            titleText = myMood!["name"] as! String
        }else if myHashtagName != nil{
            titleText = "#\(myHashtagName!)"
        }else if myFriend != nil{
            if myFriend?.objectId == PFUser.currentUser().objectId{
                titleText = "My Toasts"
            }else{
                let friendName = myFriend!["name"] as! String
                var nameComponents = friendName.componentsSeparatedByString(" ")
                titleText = "\(nameComponents[0])'s Toasts"
            }
        }
        
        setMyTitle(titleText)
    }
    
    private func setMyTitle(text:String){
        moodTitleLabel.text = getCapitalString(text)
        moodTitleLabel.font = UIFont(name: "Avenir-Heavy", size: 19)
    }
    
    func getPlaces(){
            PFCloud.callFunctionInBackground("discoverPlaces", withParameters: placesParameters()) { (result, error) -> Void in
                if error == nil{
                    self.myPlaces = result as? [PFObject]
                    self.toastsCollectionView.reloadData()
                    if self.myPlaces?.count > 0{
                        self.updatesForCurrentPlace()
                    }
                }else{
                    NSLog("getPlaces error: %@",error.description)
                }
            }
    }
    
    private func placesParameters()->[String:AnyObject]{
        var parameters = [String:AnyObject]()
        if myMood != nil{
            parameters["moodId"]=myMood!.objectId
            if myNeighborhood != nil{
                parameters["neighborhoodId"]=myNeighborhood!.objectId
            }
        }else if myFriend != nil{
                parameters["ownerId"] = myFriend!.objectId
        }else if myHashtagName != nil{
                parameters["hashtagName"] = myHashtagName
        }
        
        return parameters
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        let cache = Cache<String>(name:"hasHearts")
        cache.removeAll()
    }
    
    //MARK: - CollectionView datasource methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return myPlaces!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("placeCell", forIndexPath: indexPath) as! PlaceCell
        cell.myDelegate = self
        cell.myPlace = myPlaces![indexPath.row]
        
        return cell
    }
    
    //MARK: CollectionView delegate methods
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSizeMake(272*CGRectGetWidth(collectionView.bounds)/320, CGRectGetHeight(collectionView.bounds))
        
    }
    
    private func currentPlace(#scrollView: UIScrollView)-> PFObject?{
        var centerPoint = scrollView.layer.position
        centerPoint.x += scrollView.contentOffset.x
        
        let visiblePlaceIndexPath = toastsCollectionView.indexPathForItemAtPoint(centerPoint)
        if visiblePlaceIndexPath != nil{
            currentIndexPath = visiblePlaceIndexPath
            return myPlaces![currentIndexPath!.row]
        }else{
            return nil
        }
    }
    
    private func updatesForCurrentPlace(){
        var firstPlace:PFObject
        var currentRow:Int?
        if myCurrentPlace != nil{
            firstPlace = myCurrentPlace!
            let row = myFind(myPlaces!,item:myCurrentPlace!)
            if row != nil{
                currentRow = row
            }else{
                currentRow = 0
                firstPlace = myPlaces![currentRow!]
            }
        }else{
            currentRow = 0
            firstPlace = myPlaces![currentRow!]
        }
        self.currentIndexPath = NSIndexPath(forRow: currentRow!, inSection: 0)
        
        toastsCollectionView.scrollToItemAtIndexPath(currentIndexPath!, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
        configureBottomBar(place: firstPlace)
        configureBG(place: firstPlace)
    }
    
    private func myFind(array:[PFObject],item:PFObject) -> Int?{
        var index:Int?=nil
        for k in 0...array.count{
            if array[k].objectId == item.objectId{
                index = k
                break
            }
        }
        return index
    }
    
    private func configureBG(#place:PFObject){
        bgQueue.addOperationWithBlock { () -> Void in
            if let neighborhood = place["neighborhood"] as? PFObject{
                let BGname = neighborhood["name"] as! String
                self.changeBGTo(BGname)
            }else{
                self.changeBGTo("default")
            }
        }
        
    }
    
    //MARK: Updating Neighborhood Background
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let opQueue = NSOperationQueue.mainQueue()
        opQueue.addOperationWithBlock { () -> Void in
            let currentP = self.currentPlace(scrollView: scrollView)
            if let currentNeighborhood = currentP?["neighborhood"] as? PFObject{
                let currentBG = currentNeighborhood["name"] as! String
                if currentBG != self.lastBG{
                    self.changeBGTo(currentBG)
                }
            }else if(self.lastBG != "default"){
                self.changeBGTo("default")
            }
        }
    }
    
    private func changeBGTo(newBG:String){
        lastBG = newBG
        myBG.setImage(lastBG, opacity: 0.6)
    }
    
    //MARK: Toggle BottomBar buttons
    private func configureBottomBar(#place:PFObject){
        configurePickupButton(place: place)
        configureReserveButton(place: place)
    }
    
    private func configurePickupButton(#place:PFObject){
        toggleBottomBarButton(pickupButton, enabled: place["phone"] != nil)
    }
    
    private func configureReserveButton(#place:PFObject){
        toggleBottomBarButton(reservationButton, enabled: place["reservationURL"] as! String != "")
    }
    
    private func toggleBottomBarButton(button:UIButton,enabled:Bool){
        button.enabled = enabled
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            if enabled{
                button.alpha = 1
            }else{
                button.alpha = 0.3
            }
        })
    }
    
    //MARK: - Action methods
    @IBAction func backPressed(sender: UIButton) {
        if myDelegate == nil{
            self.navigationController?.popViewControllerAnimated(true)
        }else{
            myDelegate?.discoverMenuPressed()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "placeDetailSegue" {
            let destination = segue.destinationViewController as! PlaceDetailViewController
            
            let selectedIndexPath = toastsCollectionView.indexPathsForSelectedItems()[0] as! NSIndexPath
            let selectedPlace = myPlaces?[selectedIndexPath.row]
            let selectedCell = toastsCollectionView.cellForItemAtIndexPath(selectedIndexPath) as! PlaceCell
            destination.myPlace = selectedPlace
            destination.placeHashtags = selectedCell.hashtagDataSource?.hashtags
            destination.bgName = lastBG
            toastsCollectionView.deselectItemAtIndexPath(selectedIndexPath, animated: false)
        }
    }
    
    @IBAction func closeReviewsPressed(sender: AnyObject) {
        if let table = currentReviewsTableView{
            table.setContentOffset(CGPointMake(0, 0), animated: true)
        }
    }
    
    @IBAction func pickupPressed(sender: UIButton) {
        let currentPlace = myPlaces![currentIndexPath!.row]
        let url = NSURL(string: "tel://" + (currentPlace["phone"] as! String))!
        var a:UIAlertController
        
        if UIApplication.sharedApplication().canOpenURL(url){
            a = alertCall(currentPlace, url: url)
        }else{
            a = alertError()
        }
        self.showDetailViewController(a, sender: self)
    }
    
    private func alertCall(place:PFObject,url:NSURL) -> UIAlertController{
        let alertTitle = "Call "+(place["name"] as! String)
        let alertDescription = place["phone"] as! String
        
        let a = UIAlertController(title: alertTitle, message: alertDescription, preferredStyle: .Alert)
        let callAction = UIAlertAction(title: "Call", style: .Default) { (action) -> Void in
            UIApplication.sharedApplication().openURL(url)
            return
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        a.addAction(callAction)
        a.addAction(cancelAction)
        return a
    }
    
    private func alertError()->UIAlertController{
        let a = UIAlertController(title: "Unable to make calls", message: "Your device is not suitable for making calls.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        a.addAction(okButton)
        
        return a
    }
    
    @IBAction func reservePressed(sender: UIButton) {
        let currentPlace = myPlaces![currentIndexPath!.row]
        viewLink(currentPlace["reservationURL"] as! String, title: "Reservation")
    }
    
    //MARK: - PlaceCell delegate methods
    func placeCellDidScroll(#tableView: UITableView,place: PFObject) {
        currentReviewsTableView = tableView
        let alphaChange = tableView.contentOffset.y/50
        let placeAlphaChange = tableView.contentOffset.y/150
        let newAlpha = min(1,0 + alphaChange)
        let newPlaceAlpha = min(1,0 + placeAlphaChange)
        myBlurBG.alpha = newAlpha
        
        placeTitleLabel.text = getCapitalString(place["name"] as! String!)
        placeTitleLabel.alpha = newPlaceAlpha
        placeCloseButton.alpha = newPlaceAlpha
        
        moodTitleLabel.alpha = max(0,1 - newAlpha)
        //changeBrothersAlpha(place: place, alpha: moodTitleLabel.alpha)
        
        if newAlpha >= 1{
            toastsCollectionView.scrollEnabled = false
        }else{
            toastsCollectionView.scrollEnabled = true
        }
    }
    
    func placeCellDidPressed(#place:PFObject) {
        let selectedIndex = find(myPlaces!,place)!
        toastsCollectionView.selectItemAtIndexPath(NSIndexPath(forRow: selectedIndex, inSection: 0), animated: false, scrollPosition: .None)
        self.performSegueWithIdentifier("placeDetailSegue", sender: self)
    }
    
    func placeCellReviewDidPressed(#toast: PFObject,place: PFObject, parentHeader: UIView) {
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("reviewDetailScene") as! ReviewDetailViewController
        destination.myToast = toast
        destination.titleString = place["name"] as! String!
        destination.myOldParentHeader = parentHeader
        self.showViewController(destination, sender: self)
    }
    
    func placeCellReviewerDidPress(#user: PFUser,friend:PFUser?) {
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("profileDetailScene") as! ProfileDetailViewController
        destination.myUser = user
        destination.myFriend = friend
        self.showViewController(destination, sender: self)
    }
    
    func placeCellHashtagPressed(name: String) {
        let destination = storyboard?.instantiateViewControllerWithIdentifier("toastsScene") as! ToastsViewController
        destination.myHashtagName = name
        self.showViewController(destination, sender: self)
    }
    
    func placeCellAskedForHashtags(placeId: String) -> [PFObject]? {
        return localHashtags[placeId]
    }
    
    func placeCellAskedForReviews(placeId: String) -> [PFObject]? {
        return localReviews[placeId]
    }
    
    func placeCellDidGetHashtags(placeId: String, hashtags: [PFObject]) {
        localHashtags[placeId] = hashtags
    }
    
    func placeCellDidGetReviews(placeId: String, reviews: [PFObject]) {
        localReviews[placeId] = reviews
    }
    
    //MARK: - Misc methods
    func getCapitalString(original:String) -> String{
        return prefix(original, 1).capitalizedString + suffix(original, count(original) - 1)
    }
    
    func viewLink(link:String,title:String){
        let navDestination = storyboard?.instantiateViewControllerWithIdentifier("deliveryWebViewNavScene") as! UINavigationController
        let destination = navDestination.viewControllers[0] as! GenericWebViewController
        destination.myURL = link
        destination.tempTitle = title
        
        self.showDetailViewController(navDestination, sender: nil)
    }
}
