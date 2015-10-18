//
//  PlaceDetailTableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/13/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke
import MapKit
import CoreLocation
import AddressBook
import Foundation
import Alamofire

protocol PlaceDetailDelegate{
    func placeDetailMenuPressed()
    func placeDetailCallPressed()
    func placeDetailWebsitePressed()
    func placeDetailDirectionsPressed()
    func placeDetailCategoryPressed()
}

class PlaceDetailTableViewController: UITableViewController,MKMapViewDelegate,HashtagDelegate,PlacePicturesDelegate {
    
    var myDelegate:PlaceDetailDelegate?
    var placeGeoPoint:PFGeoPoint?
    var myPlace:PFObject?
    var myPlacePicture:UIImage?
    var placeHashtags: [PFObject]?
    var placeReviewFriends : [PFObject]?
    var reservationURL: String?
    var menuURL: String?
    
    let foursquareClientId = "2EDPPGSKXYRS3TIW4TIDKRXEGBNMIVMCC5HF4FAEZEHISGI4"
    let foursquareClientSecret = "H2GC5EERWD3RHBLMSGVEY55TI5JPA5HXZD4MRLO4XILVJ4HB"
    
    var hashtagsDataSource:HashtagCollectionViewDataSource?{
        didSet{
            hashtagCollectionView.dataSource = hashtagsDataSource
            hashtagCollectionView.delegate = hashtagsDataSource
            hashtagCollectionView.reloadData()
        }
    }
    var myPicturesDataSource:PlacePicturesDataSource?{
        didSet{
            picturesCollectionView.dataSource = myPicturesDataSource
            picturesCollectionView.delegate = myPicturesDataSource
            picturesCollectionView.reloadData()
        }
    }
    
    @IBOutlet weak var cateogoryLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var placeMapView: MKMapView!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var callLabel: UILabel!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var hashtagCollectionView: UICollectionView!
    
    @IBOutlet weak var hashtagCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var picturesPageControl: UIPageControl!
    @IBOutlet weak var picturesCollectionView: UICollectionView!
    
    
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
        
        configurePlacePictures()
        configureMap()
        configureCategory()
        configurePrice()
        configureDistance()
        configureAddress()
        configureHours()
        configureCall()
        configureHashtags()
    }
    
    override func viewDidDisappear(animated: Bool) {
        myPicturesDataSource?.myCache.removeAll()
    }
    
    //MARK: Place properties methods
    func configurePlacePictures(){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            let pictures = self.myPlace!["photos"] as! [String]
            self.picturesPageControl.numberOfPages = pictures.count
            self.myPicturesDataSource = PlacePicturesDataSource(items:pictures,delegate:self)
        }
        
    }
    
    func configureMap(){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.placeGeoPoint = self.myPlace?["location"] as? PFGeoPoint
        let placeAnnotation = MKPointAnnotation()
        placeAnnotation.coordinate = CLLocationCoordinate2DMake(self.placeGeoPoint!.latitude, self.placeGeoPoint!.longitude)
        self.placeMapView.addAnnotation(placeAnnotation)
        
        let squareRegion = MKCoordinateRegionMakeWithDistance(placeAnnotation.coordinate, 200, 200)
        self.placeMapView.setRegion(squareRegion, animated: false)
        }
    }
    
    func configureCategory(){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
        if let category = self.myPlace?["category"] as? PFObject{
            category.fetchIfNeededInBackgroundWithBlock { (result, error) -> Void in
                if error == nil {
                    let placeName = (result!["name"] as? String)
                    self.cateogoryLabel.text = placeName?.uppercaseString
                }
            }
        }else{
            self.cateogoryLabel.text = ""
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
        let userLastLocation = PFUser.currentUser()!["lastLocation"] as? PFGeoPoint
        let placeLocation = myPlace!["location"] as? PFGeoPoint
        
        let distance = placeLocation?.distanceInMilesTo(userLastLocation)
        
        let milesPerMinuteWalkingSpeed = 0.05216
        let walkingTime = distance!/milesPerMinuteWalkingSpeed
        var walkingString = ""
        if walkingTime/60 > 24{
            walkingString = String(format: "%0.0f", walkingTime/(60*24)) + "-DAY WALK"
        }else if walkingTime/60 >= 1 {
            walkingString = String(format: "%0.0f", walkingTime/(60)) + " HRS WALK"
        }else{
            walkingString = String(format: "%0.0f", walkingTime) + " MIN WALK"
        }
        
        distanceLabel.text = walkingString
    }
    
    func configureAddress(){
        addressLabel.text = myPlace?["address"] as! String!
    }
    
    func configureHours(){
        let myPlaceID = myPlace!["foursquarePlaceId"] as! String
        
        Alamofire.request(.GET, "https://api.foursquare.com/v2/venues/"+myPlaceID+"?&client_id="+self.foursquareClientId+"&client_secret="+self.foursquareClientSecret+"&v=20150207&locale=en").responseJSON( completionHandler: { (response) -> Void in
            let JSON = response.result.value
            if response.result.error == nil{
                if let imResponse = ((JSON as! NSDictionary)["response"] as? NSDictionary){
                    let result = imResponse["venue"] as! NSDictionary
                    if let hours = result["hours"] as? NSDictionary{
                        let status = hours["status"] as! String
                        
                        self.hoursLabel.text = status
                    }
                    
                }
            }else{
                NSLog("configureHours error: %@",response.result.error!.description)
            }
            
        })
    }
    
    func configureCall(){
        if let phone = myPlace?["formattedPhone"] as? String{
            callLabel.text = "Call   "+phone
        }
    }
    
    func configureHashtags(){
        func completeConfigureHashtags(){
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                let roundedNumber = round(Double(self.placeHashtags!.count)/2)
                let newHeight = roundedNumber*22
                self.hashtagCollectionViewHeightConstraint.constant = CGFloat(min(newHeight, 66.0))
                self.hashtagsDataSource = HashtagCollectionViewDataSource(hashtags: self.placeHashtags!, myDelegate: self)
            }
        }
        
        if placeHashtags != nil{
            completeConfigureHashtags()
        }else{
            PFCloud.callFunctionInBackground("placeTopHashtags", withParameters: ["placeId":self.myPlace!.objectId!,"limit":4]) { (result, error) -> Void in
                if let error = error{
                    NSLog("configureHashtags error: %@",error.description)
                }else{
                    self.placeHashtags = result as? [PFObject]
                    completeConfigureHashtags()
                }
            }
        }
        
        
    }
    
    //MARK MapView delegate methods
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var an = mapView.dequeueReusableAnnotationViewWithIdentifier("pointAn")
        if an == nil {
            an = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pointAn")
            (an as! MKPinAnnotationView).pinColor = MKPinAnnotationColor.Red
            (an as! MKPinAnnotationView).animatesDrop = true
        }
        
        an?.annotation = annotation
        
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
        return myPlace?["menuURL"] != nil
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
            myDelegate?.placeDetailWebsitePressed()
        default:
            return
        }
    }
    
    //MARK: - HashtagDataSource delegate methods
    func hashtagSelected(hashtag: PFObject) {
        let destination = storyboard?.instantiateViewControllerWithIdentifier("toastsScene") as! ToastsViewController
        destination.myHashtagName = hashtag["name"] as? String
        self.showViewController(destination, sender: self)
    }
    
    //MARK: - Actions methods
    @IBAction func categoryPressed(sender: UIButton) {
        myDelegate?.placeDetailCategoryPressed()
    }
    
    //MARK: - Misc methods
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    //MARK: - PlacePictures delegate methods
    func placePicturesChangeCurrent(currentIndex: Int) {
        picturesPageControl.currentPage = currentIndex
    }
}
