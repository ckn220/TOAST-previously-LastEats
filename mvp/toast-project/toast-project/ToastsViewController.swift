//
//  ToastsViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire

class ToastsViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,PlaceCellDelegate {
    
    var myMood:PFObject?
    var myHashtag:PFObject?
    var myCategory: PFObject?
    var myPlaces:[PFObject]?
    var myFriend:PFObject?
    var currentReviewsTableView:UITableView?
    var currentIndexPath:NSIndexPath?
    
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
        configurePlaces()
    }
    
    func configure(){
        myPlaces = []
        toastsCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    func configurePlaces(){
        let placesQuery = PFQuery(className: "Place")
        placesQuery.includeKey("category")
        if myCategory != nil {
            completeQuery(placesQuery, withCategory: myCategory!)
        }else{
            let toastsQuery = PFQuery(className: "Toast")
            if myMood != nil {
                completeQuery(toastsQuery, withMood: myMood!)
            }else if myHashtag != nil{
                completeQuery(toastsQuery, withHashtag: myHashtag!)
            }else{
                completeQuery(toastsQuery, withFriend: myFriend!)
            }
            placesQuery.whereKey("toasts", matchesQuery: toastsQuery)
        }
        
        placesQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                NSLog("Places: %d", result.count)
                self.myPlaces = result as? [PFObject]
                self.toastsCollectionView.reloadData()
                if self.myPlaces?.count > 0{
                    self.currentIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                    let firstPlace = self.myPlaces![0]
                    self.updatesForCurrentPlace(firstPlace)
                }
            }else{
                NSLog("%@",error.description)
            }
        }
        
        moodTitleLabel.text = getCapitalString(moodTitleLabel.text!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func completeQuery(query:PFQuery,withHashtag hashtag: PFObject){
        query.whereKey("hashtags", equalTo: hashtag)
        moodTitleLabel.text = "#" + (myHashtag!["name"] as! String)
    }
    
    func completeQuery(query:PFQuery,withMood mood: PFObject){
        query.whereKey("moods", equalTo: mood)
        moodTitleLabel.text = myMood!["name"] as? String
    }
    
    func completeQuery(query:PFQuery,withCategory category: PFObject){
        query.whereKey("category", equalTo: category)
        moodTitleLabel.text = myCategory!["name"] as? String
    }
    
    func completeQuery(query:PFQuery,withFriend friend: PFObject){
        query.whereKey("user", equalTo:friend)
        moodTitleLabel.text = (friend["name"] as! String).componentsSeparatedByString(" ")[0] + " likes"
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
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        if let place = currentPlace(scrollView:scrollView){
            updatesForCurrentPlace(place)
        }
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
        updateBG(place)
    }
    
    //MARK: Updating Neighborhood Background
    private func updateBG(place:PFObject){
        PFCloud.callFunctionInBackground("neighborhoodBGForPlace", withParameters: ["placeId":place.objectId]) { (result, error) -> Void in
            if error == nil{
                Alamofire.request(.GET, result as! String).response({(_,_,data,error) -> Void in
                    if error == nil{
                        self.setBG(UIImage(data: data as! NSData)!)
                    }else{
                        NSLog("update BG: %@", error!.description)
                        self.setBG(UIImage(named: "discoverBG")!);
                    }
                })
            }else{
                NSLog("update BG: %@", error.description)
                self.setBG(UIImage(named: "discoverBG")!);
            }
        }
    }
    
    private func setBG(image:UIImage){
        transitionToBG(Int(myBG1.alpha), image: image)
    }
    
    private func transitionToBG(bgIndex:Int,image:UIImage){
        var myBG,otherBG:BackgroundImageView
        if bgIndex == 0{
            myBG = myBG1
            otherBG = myBG2
        }else{
            myBG = myBG2
            otherBG = myBG1
        }
        myBG.insertImage(image, withOpacity: 0.6)
        UIView.animateWithDuration(0.4, delay: 0, options: .CurveLinear, animations: { () -> Void in
            myBG.alpha = 1
            otherBG.alpha = 0
            }, completion: nil)
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
        self.navigationController?.popViewControllerAnimated(true)
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
