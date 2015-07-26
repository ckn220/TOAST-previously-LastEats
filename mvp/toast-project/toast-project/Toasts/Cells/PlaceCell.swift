//
//  PlaceCell.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import Foundation
import UIKit
import Parse
import Haneke
import Alamofire

protocol PlaceCellDelegate{
    func placeCellDidScroll(#tableView:UITableView,place:PFObject)
    func placeCellDidPressed(#place:PFObject)
    func placeCellReviewDidPressed(#toast:PFObject,place: PFObject,parentHeader:UIView)
    func placeCellReviewerDidPress(#user:PFUser,friend:PFUser?)
    func placeCellHashtagPressed(name:String)
    
    func placeCellAskedForHashtags(placeId:String)->[PFObject]?
    func placeCellAskedForReviews(placeId:String)->[PFObject]?
    func placeCellDidGetHashtags(placeId:String,hashtags:[PFObject])
    func placeCellDidGetReviews(placeId:String,reviews:[PFObject])
}

class PlaceCell: UICollectionViewCell,ReviewDataSourceDelegate {
    
    @IBOutlet weak var toastCountLabel: UILabel!
    @IBOutlet weak var toastCountView: UIView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var hashtagsCollectionView: UICollectionView!
    @IBOutlet weak var hashtagsCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var myBackgroundView: BackgroundImageView!
    
    @IBOutlet weak var categoryNameLabel: UILabel!
    @IBOutlet weak var walkLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var reviewsTableView: UITableView!
    
    let hashtagQueue = NSOperationQueue()
    let reviewQueue = NSOperationQueue()
    
    var hashtagDataSource: HashtagCollectionViewDataSource?{
        didSet{
            self.hashtagsCollectionView.dataSource = self.hashtagDataSource
            self.hashtagsCollectionView.delegate = self.hashtagDataSource
            self.hashtagsCollectionView.reloadData()
            self.hashtagsCollectionViewHeight.constant = self.hashtagsCollectionView.collectionViewLayout.collectionViewContentSize().height
        }
    }
    var reviewsDataSource: ReviewsTableViewDataSource?{
        didSet{
            reviewsTableView.estimatedRowHeight = 144
            reviewsTableView.rowHeight = UITableViewAutomaticDimension
            reviewsTableView.dataSource = reviewsDataSource
            reviewsTableView.delegate = reviewsDataSource
            reviewsTableView.reloadData()
        }
    }
    var myPlace:PFObject?{
        didSet{
            configureName()
            configurePicture()
            configureHashtags()
            configureInformationBar()
            configureReviews()
        }
    }
    var myDelegate:PlaceCellDelegate?
    
    //MARK: - Configure methods
    func configureName(){
        toggleAlpha(alpha: 0,duration:0, views: placeNameLabel,hashtagsCollectionView)
        placeNameLabel.text = (myPlace!["name"] as? String)
        insertSmallShadow(placeNameLabel)
    }
    
    func configurePicture(){
        if let photos = myPlace!["photos"] as? [String]{
            if photos.count > 0{
                let firstPhotoURL = (myPlace!["photos"] as! [String])[0]
                myBackgroundView.setImage(URL: firstPhotoURL)
            }else{
                myBackgroundView.myImageView.image = nil
            }
        }
    }
    
    func configureHashtags(){
        hashtagQueue.addOperationWithBlock { () -> Void in
            if let localHashtags = self.myDelegate?.placeCellAskedForHashtags(self.myPlace!.objectId!){
                self.hashtagDataSource = HashtagCollectionViewDataSource(hashtags: localHashtags, myDelegate: nil)
                self.toggleAlpha(alpha: 1, views: self.placeNameLabel,self.hashtagsCollectionView)
            }else{
                PFCloud.callFunctionInBackground("placeTopHashtags", withParameters: ["placeId":self.myPlace!.objectId!,"limit":4]) { (result, error) -> Void in
                    if error == nil{
                        let hashtags = result as! [PFObject]
                        let mainQueue = NSOperationQueue.mainQueue()
                        mainQueue.addOperationWithBlock({ () -> Void in
                            self.hashtagDataSource = HashtagCollectionViewDataSource(hashtags: hashtags, myDelegate: nil)
                        })
                        self.toggleAlpha(alpha: 1, views: self.placeNameLabel,self.hashtagsCollectionView)
                        self.myDelegate?.placeCellDidGetHashtags(self.myPlace!.objectId!, hashtags: hashtags)
                    }else{
                        NSLog("%@", error!.description)
                    }
                }
            }
        }
    }
    
    func configureInformationBar(){
        configureCategory()
        configureDistance()
        configurePrice()
    }
    
    func configureReviews(){
        toggleAlpha(alpha: 0, duration: 0, views: reviewsTableView,toastCountView)
        self.reviewsTableView.rowHeight = UITableViewAutomaticDimension
        
        reviewQueue.addOperationWithBlock { () -> Void in
            if let localReviews = self.myDelegate?.placeCellAskedForReviews(self.myPlace!.objectId!){
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.reviewsDataSource = ReviewsTableViewDataSource(toasts: localReviews,delegate: self)
                })
                
                self.configureToastCount(localReviews)
                self.myDelegate?.placeCellDidGetReviews(self.myPlace!.objectId!, reviews: localReviews)
            }else{
                PFCloud.callFunctionInBackground("reviewsFromToast", withParameters: ["placeId":self.myPlace!.objectId!], block: { (result, error) -> Void in
                    if error == nil{
                        let reviews = result as! [PFObject]
                        
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.reviewsDataSource = ReviewsTableViewDataSource(toasts: reviews,delegate: self)
                            self.configureToastCount(reviews)
                        })
                        
                        self.myDelegate?.placeCellDidGetReviews(self.myPlace!.objectId!, reviews: reviews)
                    }else{
                        NSLog("configureReviews error: %@", error!.description)
                    }
                })
            }
        }
        
    }
    
    private func configureToastCount(toasts:[PFObject]){
        let toastCount = toasts.count
        if toastCount > 1{
            toastCountLabel.text = "\(toastCount) toasts"
            toggleAlpha(alpha: 1, views: reviewsTableView,toastCountView)
        }else{
            toggleAlpha(alpha: 1, views: reviewsTableView)
        }
    }
    
    private func countFriendsToast(toasts:[PFObject]) -> Int{
        let currentUser = PFUser.currentUser()
        var count = 0
        for t in toasts{
            let tUser = t["user"] as! PFUser
            if tUser.objectId != currentUser!.objectId! {
                count++
            }
        }
        
        return count
    }
    
    //MARK - Information bar methods
    func configureCategory(){
        if let category = myPlace!["category"] as? PFObject{
            category.fetchIfNeededInBackgroundWithBlock { (result, error) -> Void in
                if error == nil {
                    let placeName = (result!["name"] as? String)
                    self.categoryNameLabel.text = placeName?.uppercaseString
                }
            }
        }else{
            self.categoryNameLabel.text = ""
        }
        
    }
    
    func configurePrice(){
        var priceText = ""
        if let placePrice = myPlace!["price"] as? Int {
            for var k=0;k<placePrice;++k {
                priceText += "$"
            }
        }
        
        priceLabel.text = priceText
    }
    
    func configureDistance(){
        let userLastLocation = PFUser.currentUser()!["lastLocation"] as? PFGeoPoint
        if let placeLocation = myPlace!["location"] as? PFGeoPoint {
            let distance = placeLocation.distanceInMilesTo(userLastLocation)
            
            let milesPerMinuteWalkingSpeed = 0.05216
            let walkingTime = distance/milesPerMinuteWalkingSpeed
            var walkingString = ""
            if walkingTime/60 > 24{
                walkingString = String(format: "%0.0f", walkingTime/(60*24)) + "-DAY WALK"
            }else if walkingTime/60 >= 1 {
                walkingString = String(format: "%0.0f", walkingTime/(60)) + " HRS WALK"
            }else{
                walkingString = String(format: "%0.0f", walkingTime) + " MIN WALK"
            }
            
            walkLabel.text = walkingString
        }
    }
    
    //MARK: - Misc methods
    func toggleAlpha(#alpha:CGFloat,duration:CGFloat=0.3,completion:(()->Void)?=nil,views:UIView...){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                for view in views{
                    view.alpha = alpha
                }
                }) { (success) -> Void in
                    completion
            }
        }
    }
    
    func getCapitalString(original:String) -> String{
        return prefix(original, 1).capitalizedString + suffix(original, count(original) - 1)
    }
    
    func insertShadow(view:UIView){
        
        let layer = view.layer
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 8.0
        layer.shadowOpacity = 0.9
        layer.shadowPath = UIBezierPath(rect: layer.bounds).CGPath
        layer.shouldRasterize = true
    }
    
    func insertSmallShadow(view:UIView){
        let layer = view.layer
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 4.0
        layer.shadowOpacity = 0.9
        layer.shouldRasterize = true
    }
    
    //MARK: - ReviewsDataSource delegate methods
    func reviewDataSourceDidScroll(#contentOffset: CGPoint) {
        self.layer.zPosition = 10
        let bgLayer = myBackgroundView.layer
        let change = contentOffset.y/150
        let newScale = max(0,1 - change)
        let newAlpha = max(0,1 - change)
        bgLayer.transform = CATransform3DMakeScale(newScale, newScale, 1)
        bgLayer.opacity = Float(newAlpha)
        
        myDelegate?.placeCellDidScroll(tableView: reviewsTableView,place: myPlace!)
    }
    
    func reviewDataSourceDidEndScrolling(#contentOffset: CGPoint) {
        let initialReverseOffset = reviewsDataSource?.reviewOffest(tableView: reviewsTableView)
        
        if contentOffset.y <= initialReverseOffset! {
            if contentOffset.y >= initialReverseOffset!/3{
                reviewsTableView.setContentOffset(CGPointMake(0, initialReverseOffset!), animated: true)
            }else{
                reviewsTableView.setContentOffset(CGPointMake(0, 0), animated: true)
            }
        }
    }
    
    func reviewDataSourcePlaceDidPressed() {
        myDelegate?.placeCellDidPressed(place: myPlace!)
    }
    
    func reviewDataSourceReviewDidPressed(#toast: PFObject,parentHeader: UIView) {
        myDelegate?.placeCellReviewDidPressed(toast: toast,place: myPlace!,parentHeader:parentHeader)
    }
    
    func reviewDataSourceReviewerDidPress(#user: PFUser,friend: PFUser?) {
        myDelegate?.placeCellReviewerDidPress(user: user,friend:friend)
    }
    
    func reviewDataSourceHashtagPressed(name: String) {
        myDelegate?.placeCellHashtagPressed(name)
    }
}
