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
    var myHashtag:PFObject?
    var myCategory: PFObject?
    var myPlaces:[PFObject]?
    var myFriend:PFObject?
    var myNeighborhood:PFObject?
    var currentReviewsTableView:UITableView?
    var currentIndexPath:NSIndexPath?
    var localHashtags = [String:[PFObject]]()
    var localReviews = [String:[PFObject]]()
    var myDelegate:DiscoverDelegate?
    
    var lastBG = ""
    
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
        }else if myHashtag != nil{
            titleText = myHashtag!["name"] as! String
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
                    self.currentIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                    let firstPlace = self.myPlaces![0]
                    self.updatesForCurrentPlace(firstPlace)
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
        }else{
            if myFriend != nil{
                parameters["ownerId"] = myFriend!.objectId
            }
        }
        
        return parameters
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        return CGSizeMake(260*CGRectGetWidth(collectionView.bounds)/320, CGRectGetHeight(collectionView.bounds))
        
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
    
    private func updatesForCurrentPlace(place:PFObject){
        configureBottomBar(place: place)
        configureBG(place: place)
    }
    
    private func configureBG(#place:PFObject){
        if let neighborhood = place["neighborhood"] as? PFObject{
            let BGname = neighborhood["name"] as! String
            changeBGTo(BGname)
        }else{
            changeBGTo("default")
        }
    }
    
    //MARK: Updating Neighborhood Background
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let currentP = currentPlace(scrollView: scrollView)
        if let currentNeighborhood = currentP?["neighborhood"] as? PFObject{
            let currentBG = currentNeighborhood["name"] as! String
            if currentBG != lastBG{
                changeBGTo(currentBG)
            }
        }else if(lastBG != "default"){
            changeBGTo("default")
        }
    }
    
    private func changeBGTo(newBG:String){
        lastBG = newBG
        updateBG()
    }
    
    private func updateBG(){
        let cache = Cache<UIImage>(name: "neighborhoods")
        cache.fetch(key: lastBG, failure: { (error) -> () in
            self.updateBGToDefault()
            }, success: { (image) -> () in
                self.setBG(image)
        })
    }
    
    private func updateBGToDefault(){
        lastBG = "default"
        let cache = Cache<UIImage>(name: "neighborhoods")
        cache.fetch(key: "default", failure: { (error) -> () in
            NSLog(error!.description)
            }, success: { (image) -> () in
                self.setBG(image)
        })
    }
    
    private func setBG(image:UIImage){
        let myBG = self.view as! BackgroundImageView
        UIView.transitionWithView(myBG, duration: 0.4, options: .TransitionCrossDissolve, animations: { () -> Void in
                    myBG.insertImage(image, withOpacity: 0.65)
        },completion:nil)
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
            destination.myPlacePicture = selectedCell.myBackgroundView.myImage
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
    
    func placeCellReviewDidPressed(#toast: PFObject,place: PFObject) {
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("reviewDetailScene") as! ReviewDetailViewController
        destination.myToast = toast
        destination.titleString = place["name"] as! String!
        self.showViewController(destination, sender: self)
    }
    
    func placeCellReviewerDidPress(#user: PFUser) {
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("profileDetailScene") as! ProfileDetailViewController
        destination.myUser = user
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
        destination.title = title
        
        self.showDetailViewController(navDestination, sender: nil)
    }
}
