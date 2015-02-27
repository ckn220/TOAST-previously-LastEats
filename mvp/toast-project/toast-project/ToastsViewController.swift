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
    
        toastsCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        var currentTitle = ""
        let placesQuery = PFQuery(className: "Place")
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
        
        moodTitleLabel.text = moodTitleLabel.text?.uppercaseString
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
    
    
    //MARK: CollectionView datasource methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return myPlaces!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("placeCell", forIndexPath: indexPath) as PlaceCell
            let imPlace = myPlaces![indexPath.row]
            cell.placeNameLabel.text = (imPlace["name"] as? String)?.uppercaseString
            let placePictureString = imPlace["foursquarePicture"] as String
            Alamofire.request(.GET, placePictureString).response({ (request, response, data, error) -> Void in
                if error == nil{
                    cell.myBackgroundView.insertImage(UIImage(data: data as NSData)!)
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
                        let toastUser = firstToast["user"] as PFObject
                        review = review + "   - " + (toastUser["name"] as String)
                    }
                    cell.reviewFriendDidSelectReview(review: review)
                    
                }else{
                    NSLog("%@", error.description)
                }
        }
            
            return cell
        
    }
    
    //MARK: CollectionView delegate methods
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSizeMake(260, CGRectGetHeight(collectionView.bounds))
        
    }
    
    //MARK: Action methods
    
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
}
