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

class PlaceDetailTableViewController: UITableViewController,MKMapViewDelegate,HashtagDelegate {
    
    var myDelegate:PlaceDetailDelegate?
    var placeGeoPoint:PFGeoPoint?
    var myPlace:PFObject?
    var myPlacePicture:UIImage?
    var placeHashtags: [PFObject]?
    var placeReviewFriends : [PFObject]?
    var reservationURL: String?
    var menuURL: String?
    
    var hashtagsDataSource:HashtagCollectionViewDataSource?{
        didSet{
            hashtagCollectionView.dataSource = hashtagsDataSource
            hashtagCollectionView.delegate = hashtagsDataSource
            hashtagCollectionView.reloadData()
        }
    }
    
    @IBOutlet weak var cateogoryLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var placePictureView:BackgroundImageView!
    @IBOutlet weak var placeMapView: MKMapView!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var callLabel: UILabel!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var hashtagCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    func configure(){
        self.tableView.estimatedRowHeight = 60
        self.tableView.rowHeight = UITableViewAutomaticDimension
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
        configureDistance()
        configureAddress()
        configureHours()
        configureCall()
        configureHashtags()
    }
    
    //MARK: Place properties methods
    func configurePlacePicture(){
        if let pic = myPlacePicture {
            self.placePictureView.myImage = pic
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
    
    func configureAddress(){
        addressLabel.text = myPlace?["address"] as String!
    }
    
    func configureHours(){
        
    }
    
    func configureCall(){
        if let phone = myPlace?["formattedPhone"] as? String{
            callLabel.text = "Call   "+phone
        }
    }
    
    func configureHashtags(){
        hashtagsDataSource = HashtagCollectionViewDataSource(hashtags: placeHashtags!, myDelegate: self)
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
    
    //MARK: TableView delegate methods
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let currentWidth = CGRectGetWidth(tableView.bounds)
        
        switch indexPath.row{
        case 0: //Place picture
            return currentWidth
        case 1: //map
            return currentWidth/2
        case 3: //menu
            if validateMenu(){
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
            }else{
                return 0.1
            }
        case 4: //call
            if validateCall(){
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
            }else{
                return 0.1
            }
        case 6: //website
            if validateWebsite(){
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
            }else{
                return 0.1
            }
        case 7,8:
            if placeHashtags?.count > 0{
                return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
            }else{
                return 0.1
            }
        default:
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    func validateMenu()-> Bool{
        return myPlace?["menuLink"] != nil
    }
    
    func validateCall()->Bool{
        return myPlace?["phone"] != nil
    }
    
    func validateWebsite()->Bool{
        return myPlace?["url"] != nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.row{
        case 3: //menu
            myDelegate?.placeDetailMenuPressed()
        case 4: //call
            myDelegate?.placeDetailCallPressed()
        case 5: //directions
            myDelegate?.placeDetailDirectionsPressed()
        case 6: //website
            myDelegate?.placeDetailDirectionsPressed()
        default:
            return
        }
    }
    
    //MARK: - HashtagDataSource delegate methods
    func hashtagSelected(hashtag: PFObject) {
        
    }
    
    //MARK: - Actions methods
    @IBAction func categoryPressed(sender: UIButton) {
        myDelegate?.placeDetailCategoryPressed()
    }
    
    //MARK: - Misc methods
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}
