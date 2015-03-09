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

class ToastsViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    var myMood:PFObject?
    var myHashtag:PFObject?
    var myCategory: PFObject?
    var myPlaces:[PFObject]?
    var myFriend:PFObject?
    
    @IBOutlet weak var myBG: BackgroundImageView!
    @IBOutlet weak var toastsCollectionView: UICollectionView!
    @IBOutlet weak var moodTitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myPlaces = []
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        myBG.insertImage(UIImage(named: "discoverBG")!, withOpacity: 0.7)
        
        toastsCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        var currentTitle = ""
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
        
        moodTitleLabel.text = getCapitalString(moodTitleLabel.text!)
        placesQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                NSLog("Places: %d", result.count)
                self.myPlaces = result as? [PFObject]
                self.toastsCollectionView.reloadData()
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    func completeQuery(query:PFQuery,withHashtag hashtag: PFObject){
        query.whereKey("hashtags", equalTo: hashtag)
        moodTitleLabel.text = "#" + (myHashtag!["name"] as String)
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
        moodTitleLabel.text = (friend["name"] as String).componentsSeparatedByString(" ")[0] + " likes"
    }
    
    
    //MARK: - CollectionView datasource methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return myPlaces!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("placeCell", forIndexPath: indexPath) as PlaceCell
            let imPlace = myPlaces![indexPath.row]
            cell.placeNameLabel.text = (imPlace["name"] as? String)
            insertSmallShadow(cell.placeNameLabel)
        
            let placePictureString = imPlace["foursquarePicture"] as String
        
            Alamofire.request(.GET, placePictureString).response({ (request, response, data, error) -> Void in
                if error == nil{
                    cell.myBackgroundView.insertImage(UIImage(data: data as NSData)!,withOpacity: 0.1)
                    self.insertShadow(cell.myBackgroundView)
                }else{
                    NSLog("%@", error!.description)
                }
            })
        
            //Get Hashtags
            let toastQuery = imPlace.relationForKey("toasts").query()
            let hashtagQuery = PFQuery(className: "Hashtag")
            hashtagQuery.whereKey("toasts", matchesQuery:toastQuery)
            hashtagQuery.limit = 4
            hashtagQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
                if error == nil{
                    cell.hashtagDataSource = HashtagCollectionViewDataSource(items: result as NSArray, cellIdentifier: "hashtagCell", configureBlock: { (imCell, item) -> () in
                        if let actualCell = imCell as? CustomUICollectionViewCell {
                                actualCell.configureForItem(item!)
                        }
                    })
                    cell.hashtagsCollectionView.dataSource = cell.hashtagDataSource
                    cell.hashtagsCollectionView.delegate = cell.hashtagDataSource
                    cell.hashtagsCollectionView.reloadData()
                    cell.hashtagsCollectionViewHeight.constant = cell.hashtagsCollectionView.collectionViewLayout.collectionViewContentSize().height
                }else{
                    NSLog("%@", error.description)
                }
        }
        
            //Get Toasts.user
            let othertoastQuery = imPlace.relationForKey("toasts").query()
            othertoastQuery.includeKey("user")
            othertoastQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
                if error == nil{
                    cell.reviewFriendDataSource = ReviewFriendsCollectionViewDataSource(items: result as NSArray, cellIdentifier: "reviewFriendCell", configureBlock: { (imCell, item) -> () in
                        if let actualCell = imCell as? CustomUICollectionViewCell {
                            actualCell.configureForItem(item!)
                        }
                    })
                    cell.reviewFriendCollectionView.dataSource = cell.reviewFriendDataSource
                    cell.reviewFriendCollectionView.delegate = cell.reviewFriendDataSource
                    cell.reviewFriendDataSource?.myDelegate = cell
                    cell.reviewFriendCollectionView.reloadData()
                    
                    let firstToast = result[0] as PFObject
                    var review = (firstToast["review"] as String)
                    if review != "" {
                        review = "\""+review+"\""
                    }
                    cell.reviewFriendDidSelectReview(review: review)
                    
                }else{
                    NSLog("%@", error.description)
                }
        }
            configureCategory(place: imPlace, atCell: cell)
            configureDistance(place: imPlace, atCell: cell)
            configurePrice(place: imPlace, atCell: cell)
        
        
            return cell
        
    }
    
    //MARK: CollectionView delegate methods
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSizeMake(260*CGRectGetWidth(collectionView.bounds)/320, CGRectGetHeight(collectionView.bounds))
        
    }
    
    //MARK: - Action methods
    
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "placeDetailSegue" {
            let destination = segue.destinationViewController as PlaceDetailViewController
            
            let selectedIndexPath = toastsCollectionView.indexPathsForSelectedItems()[0] as NSIndexPath
            let selectedPlace = myPlaces?[selectedIndexPath.row]
            let selectedCell = toastsCollectionView.cellForItemAtIndexPath(selectedIndexPath) as PlaceCell
            destination.myPlacePicture = selectedCell.myBackgroundView.myImage
            destination.myPlace = selectedPlace
            destination.placeReviewFriends = selectedCell.reviewFriendDataSource?.items as? [PFObject]
            destination.placeHashtags = selectedCell.hashtagDataSource?.items as? [PFObject]
        }
    }
    
    //MARK: - Configure cell methods
    func configureCategory(#place:PFObject,atCell cell:PlaceCell){
        (place["category"] as PFObject).fetchIfNeededInBackgroundWithBlock { (result:PFObject!, error) -> Void in
            if error == nil {
                let placeName = (result["name"] as? String)
                cell.categoryNameLabel.text = placeName?.uppercaseString
            }
        }
    }
    
    func configurePrice(#place:PFObject,atCell cell:PlaceCell){
        var priceText = ""
        if let placePrice = place["price"] as? Int {
            for var k=0;k<placePrice;++k {
                priceText += "$"
            }
        }
        
        cell.priceLabel.text = priceText
    }
    
    func configureDistance(#place:PFObject,atCell cell:PlaceCell){
        let userLastLocation = PFUser.currentUser()["lastLocation"] as? PFGeoPoint
        let placeLocation = place["location"] as? PFGeoPoint
        
        let distance = placeLocation?.distanceInMilesTo(userLastLocation)
        
        let milesPerMinuteWalkingSpeed = 0.05216
        let walkingTime = distance!/milesPerMinuteWalkingSpeed
        var walkingString = ""
        if walkingTime/60 > 24{
            walkingString = NSString(format: "%0.0f", walkingTime/(60*24)) + "-DAY WALK"
        }else if walkingTime/60 >= 1 {
            walkingString = NSString(format: "%0.0f", walkingTime/(60)) + " HRS WALK"
        }else{
            walkingString = NSString(format: "%0.0f", walkingTime) + " MIN WALK"
        }
        
        cell.walkLabel.text = walkingString
    }
    
    //MARK: - Misc methods
    func getCapitalString(original:String) -> String{
        return prefix(original, 1).capitalizedString + suffix(original, countElements(original) - 1)
    }
    
    func insertShadow(view:UIView){
        
        let layer = view.layer
        layer.shadowOffset = CGSizeMake(0, -1)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 16.0
        layer.shadowOpacity = 0.8
        layer.shadowPath = UIBezierPath(rect: layer.bounds).CGPath
    }
    
    func insertSmallShadow(view:UIView){
        let layer = view.layer
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 6.0
        layer.shadowOpacity = 0.6
    }
}
