//
//  PlaceDetailTableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/13/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire
import MapKit
import CoreLocation
import AddressBook

protocol PlaceDetailDelegate{
    func placeDetailMenuPressed()
    func placeDetailCallPressed()
    func placeDetailWebsitePressed()
    func placeDetailDirectionsPressed()
    func placeDetailCategoryPressed()
}

class PlaceDetailTableViewController: UITableViewController, ReviewFriendsDelegate,MKMapViewDelegate,HashtagDelegate {
    
    var myDelegate:PlaceDetailDelegate?
    var placeGeoPoint:PFGeoPoint?
    var myPlace:PFObject?
    var myPlacePicture:UIImage?
    var placeHashtags: [PFObject]?
    var placeReviewFriends : [PFObject]?
    var reservationURL: String?
    var menuURL: String?
    
    var likeFriendsDataSource:ReviewFriendsCollectionViewDataSource?
    var hashtagsDataSource:HashtagCollectionViewDataSource?
    
    @IBOutlet weak var cateogoryLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var reviewTextView: UITextView!
    @IBOutlet weak var placePictureView:BackgroundImageView!
    @IBOutlet weak var LIkeFriendsCollectionView: UICollectionView!
    @IBOutlet weak var placeMapView: MKMapView!
    @IBOutlet weak var hashtagsCollectionView: UICollectionView!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    
    @IBOutlet weak var menuButton: UIView!
    @IBOutlet weak var getDirectionsButton: UIView!
    @IBOutlet weak var callButton: UIView!
    @IBOutlet weak var urlButton: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureReviewFriends()
        configureHashtags()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        configurePlacePicture()
        configureMap()
        configureCategory()
        configurePrice()
        configurePhone()
        configureAddress()
        configureDistance()
        configureWebsite()
        configureMenu()
    }
    
    //MARK: Place properties methods
    func configurePlacePicture(){
        if let pic = myPlacePicture {
            self.placePictureView.insertImage(pic)
        }
    }
    
    func configureMap(){
        placeGeoPoint = myPlace?["location"] as? PFGeoPoint
        let placeAnnotation = MKPointAnnotation()
        placeAnnotation.coordinate = CLLocationCoordinate2DMake(placeGeoPoint!.latitude, placeGeoPoint!.longitude)
        placeMapView.addAnnotation(placeAnnotation)
        
        let squareRegion = MKCoordinateRegionMakeWithDistance(placeAnnotation.coordinate, 200, 200)
        placeMapView.setRegion(squareRegion, animated: false)
    }
    
    func configureReviewFriends(){
        likeFriendsDataSource = ReviewFriendsCollectionViewDataSource(items: placeReviewFriends!, cellIdentifier: "reviewFriendCell", configureBlock: { (imCell, item) -> () in
            if let actualCell = imCell as? CustomUICollectionViewCell {
                actualCell.configureForItem(item!)
            }
        })
        LIkeFriendsCollectionView.dataSource = likeFriendsDataSource
        LIkeFriendsCollectionView.delegate = likeFriendsDataSource
        likeFriendsDataSource?.myDelegate = self
        LIkeFriendsCollectionView.reloadData()
        
        reviewFriendDidSelectReview(review: placeReviewFriends?[0]["review"] as String)
    }
    
    func configureHashtags(){
        hashtagsDataSource = HashtagCollectionViewDataSource(items: placeHashtags!, cellIdentifier: "hashtagCell", configureBlock: { (imCell, item) -> () in
            if let actualCell = imCell as? CustomUICollectionViewCell {
                actualCell.configureForItem(item!)
            }
        })
        hashtagsDataSource?.myDelegate = self
        hashtagsCollectionView.dataSource = hashtagsDataSource
        hashtagsCollectionView.delegate = hashtagsDataSource
        hashtagsCollectionView.reloadData()
    }
    
    func configureCategory(){
        (myPlace?["category"] as PFObject).fetchIfNeededInBackgroundWithBlock { (result:PFObject!, error) -> Void in
            if error == nil {
                let placeName = (result["name"] as? String)
                self.cateogoryLabel.text = placeName?.uppercaseString
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
        
        distanceLabel.text = walkingString
    }
    
    func configurePhone(){
        if let phone = myPlace?["formattedPhone"] as? String {
            phoneLabel.text = phone
        }else{
            callButton.alpha = 0
        }
        
    }
    func configureAddress(){
        
        addressLabel.text = ""
        if let addressText = myPlace?["address"] as? String {
            addressLabel.text! += addressText
        }
        if let cityText = myPlace?["city"] as? String {
            addressLabel.text! += (", " + cityText)
        }
        if let stateText = myPlace?["state"] as? String {
            addressLabel.text! += (". " + stateText)
        }
        if let zipcodeText = myPlace?["postalCode"] as? String {
            addressLabel.text! += (" " + zipcodeText)
        }
        
    }
    
    func configureWebsite(){
        if let url = myPlace?["url"] as? String{
            websiteLabel.text = url
        }else{
            urlButton.alpha = 0
        }
    }
    
    func configureMenu(){
        if let menu = myPlace?["menuLink"] as? String{
            
            if menu != ""{
                self.menuURL = menu
            }else{
                self.menuButton.alpha = 0
            }
            
        }else{
            self.menuButton.alpha = 0
        }
    }
    
    //MARK MapView delegate methods
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var an = mapView.dequeueReusableAnnotationViewWithIdentifier("pointAn")
        if an == nil {
            an = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pointAn")
            (an as MKPinAnnotationView).pinColor = MKPinAnnotationColor.Red
            (an as MKPinAnnotationView).animatesDrop = true
        }
        
        an.annotation = annotation
        
        return an
    }
    
    //MARK: ReviewFriend Datasource delegate methods
    func reviewFriendDidSelectReview(#review: String) {
        
        if review != "" {
            reviewTextView.text = review
            reviewTextView.alpha = 1
        }else{
            reviewTextView.text = "No review"
            reviewTextView.alpha = 0.5
        }
        
        reviewTextView.textColor = UIColor.whiteColor()
        reviewTextView.font = UIFont(name: "Avenir-Roman", size: 16)
    }
    
    func hashtagSelected(hashtag: PFObject) {
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("toastsScene") as ToastsViewController
        destination.myHashtag = hashtag
        
        self.parentViewController?.navigationController?.showViewController(destination, sender: nil)
    }
    
    //MARK: TableView delegate methods
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let currentWidth = CGRectGetWidth(tableView.bounds)
        
        switch indexPath.row{
        case 0:
            return currentWidth
        case 2:
            return CGRectGetHeight(reviewTextView.bounds)+28
        default:
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    @IBAction func categoryPressed(sender: UIButton) {
        myDelegate?.placeDetailCategoryPressed()
    }
    
    @IBAction func getDirectionsCalled(sender: AnyObject) {
        myDelegate?.placeDetailDirectionsPressed()
    }
    
    @IBAction func callPressed(sender: AnyObject) {
        myDelegate?.placeDetailCallPressed()
    }
    
    @IBAction func websitePressed(sender: AnyObject) {
        myDelegate?.placeDetailWebsitePressed()
    }
    
    @IBAction func menuPressed(sender: UIButton) {
        myDelegate?.placeDetailMenuPressed()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}
