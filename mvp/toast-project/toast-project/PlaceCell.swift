//
//  PlaceCell.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire

protocol PlaceCellDelegate{
    func placeCellDidScroll(#tableView:UITableView,place:PFObject)
    func placeCellDidPressed(#place:PFObject)
    func placeCellReviewDidPressed(#toast:PFObject,place: PFObject)
}

class PlaceCell: UICollectionViewCell,ReviewDataSourceDelegate {
    
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var hashtagsCollectionView: UICollectionView!
    @IBOutlet weak var hashtagsCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var myBackgroundView: BackgroundImageView!
    
    @IBOutlet weak var categoryNameLabel: UILabel!
    @IBOutlet weak var walkLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var reviewsTableView: UITableView!
    
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
        placeNameLabel.text = (myPlace!["name"] as? String)
        insertSmallShadow(placeNameLabel)
    }
    
    func configurePicture(){
        let placePictureString = myPlace!["foursquarePicture"] as String
        Alamofire.request(.GET, placePictureString).response({ (request, response, data, error) -> Void in
            if error == nil{
                self.myBackgroundView.insertImage(UIImage(data: data as NSData)!,withOpacity: 0)
                //self.insertShadow(self.myBackgroundView)
            }else{
                NSLog("%@", error!.description)
            }
        })
    }
    
    func configureHashtags(){
        let toastQuery = myPlace!.relationForKey("toasts").query()
        let hashtagQuery = PFQuery(className: "Hashtag")
        hashtagQuery.whereKey("toasts", matchesQuery:toastQuery)
        hashtagQuery.limit = 4
        hashtagQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.hashtagDataSource = HashtagCollectionViewDataSource(hashtags: result as [PFObject], myDelegate: nil)
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    func configureInformationBar(){
        configureCategory()
        configureDistance()
        configurePrice()
    }
    
    func configureReviews(){
        let othertoastQuery = myPlace!.relationForKey("toasts").query()
        othertoastQuery.includeKey("user")
        othertoastQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.reviewsTableView.rowHeight = UITableViewAutomaticDimension
                self.reviewsDataSource = ReviewsTableViewDataSource(toasts: result as [PFObject],delegate: self)
                
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    //MARK - Information bar methods
    func configureCategory(){
        (myPlace!["category"] as PFObject).fetchIfNeededInBackgroundWithBlock { (result:PFObject!, error) -> Void in
            if error == nil {
                let placeName = (result["name"] as? String)
                self.categoryNameLabel.text = placeName?.uppercaseString
            }
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
        let userLastLocation = PFUser.currentUser()["lastLocation"] as? PFGeoPoint
        let placeLocation = myPlace!["location"] as? PFGeoPoint
        
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
        
        walkLabel.text = walkingString
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
        layer.shouldRasterize = true
    }
    
    func insertSmallShadow(view:UIView){
        let layer = view.layer
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 6.0
        layer.shadowOpacity = 0.6
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
    
    func reviewDataSourceReviewDidPressed(#toast: PFObject) {
        myDelegate?.placeCellReviewDidPressed(toast: toast,place: myPlace!)
    }
}
