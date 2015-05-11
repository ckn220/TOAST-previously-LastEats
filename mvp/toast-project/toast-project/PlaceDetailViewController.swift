//
//  PlaceDetailViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/13/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import MapKit
import Haneke

class PlaceDetailViewController: UIViewController,PlaceDetailDelegate,UIActionSheetDelegate {

    @IBOutlet weak var placeNameLabel:UILabel!
    var myDetail:PlaceDetailTableViewController?
    var myPlace:PFObject?
    var myPlacePicture:UIImage?
    var placeReviewFriends: [PFObject]?
    var placeHashtags: [PFObject]?
    var reservationURL:String?
    var bgName:String?
    
    @IBOutlet weak var myBlurBG: BackgroundImageView!
    @IBOutlet weak var pickupButton: UIButton!
    @IBOutlet weak var reservationButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configurePlaceName()
        configureBottomBar()
    }

    private func configurePlaceName(){
        placeNameLabel.text = myPlace!["name"] as? String
    }
    
    private func configureBottomBar(){
        configurePickupButton()
        configureReserveButton()
    }
    
    private func configurePickupButton(){
        toggleBottomBarButton(pickupButton, enabled: myPlace?["phone"] != nil)
    }
    
    private func configureReserveButton(){
        toggleBottomBarButton(reservationButton, enabled: myPlace?["reservationURL"] as! String != "")
    }
    
    private func toggleBottomBarButton(button:UIButton,enabled:Bool){
        button.enabled = enabled
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            if enabled{
                button.alpha = 1
            }else{
                button.alpha = 0.3
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewWillAppear(animated: Bool) {
        configure()
    }
    
    //MARK: - Configure methods
    func configure(){
        if bgName != nil{
            let cache = Cache<UIImage>(name:"neighborhoods")
            cache.fetch(key: bgName!, failure: { (error) -> () in
                NSLog("configure error: %@",error!.description)
                }, success: {(image) -> () in
                    self.myBlurBG.insertImage(image, withOpacity: 0.65)
            })
        }
    }
    
    //MARK: - Action methods
    @IBAction func backPressed(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "placeDetailTableSegue" {
            myDetail = segue.destinationViewController as? PlaceDetailTableViewController
            myDetail?.myPlace = myPlace
            myDetail?.myPlacePicture = myPlacePicture
            myDetail?.placeReviewFriends = placeReviewFriends
            myDetail?.placeHashtags = placeHashtags
            myDetail?.myDelegate = self
        }
    }
    
    //MARK: Bottom bar methods
    @IBAction func reservePressed(sender: UIButton) {
        self.viewLink(myPlace!["reservationURL"] as! String, title: "Reservation")
    }
    
    @IBAction func pickupPressed(sender: UIButton) {
        callPlace()
    }
    
    
    //MARK: - PlaceDetail Delegate
    func placeDetailCategoryPressed() {
        (myPlace?["category"] as! PFObject).fetchIfNeededInBackgroundWithBlock { (result:PFObject!, error) -> Void in
            if error == nil {
                let destination = self.storyboard?.instantiateViewControllerWithIdentifier("toastsScene") as! ToastsViewController
                destination.myCategory = result
                
                self.navigationController?.showViewController(destination, sender: nil)
            }
        }
    }
    
    func placeDetailCallPressed() {
        callPlace()
    }
    
    func placeDetailMenuPressed() {
        let webString = myPlace!["menuURL"] as! String
        viewLink(webString, title: "Menu")
    }
    
    func placeDetailWebsitePressed() {
        let webString = myPlace!["url"] as! String
        viewLink(webString, title: "Website")
    }
    
    //MARK: Directions methods
    func placeDetailDirectionsPressed() {
        
        if canOpenInGoogleMaps(){
            askMapsProvider()
        }else{
            openInAppleMaps()
        }
    }
    
    func canOpenInGoogleMaps() -> Bool{
        let googleMapsTest = NSURL(string: "comgooglemaps://")
        return UIApplication.sharedApplication().canOpenURL(googleMapsTest!)
    }
    
    func askMapsProvider(){
        let actionSheet = UIAlertController(title: "Where do you want to see the directions?", message: nil, preferredStyle: .ActionSheet)
        
        actionSheet.addAction(appleMapsAction())
        actionSheet.addAction(googleMapsAction())
        actionSheet.addAction(cancelAction())
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func appleMapsAction()->UIAlertAction{
        return UIAlertAction(title: "Apple Maps", style: .Default) { (action) -> Void in
            self.openInAppleMaps()
        }
    }
    
    func openInAppleMaps(){
        let placeGeo = self.myPlace!["location"] as! PFGeoPoint
        let coords = CLLocationCoordinate2DMake(placeGeo.latitude,placeGeo.longitude)
        let place = MKPlacemark(coordinate: coords, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: place)
        mapItem.name = self.myPlace!["name"] as! String
        
        let options = [MKLaunchOptionsDirectionsModeKey:
            MKLaunchOptionsDirectionsModeWalking,
            MKLaunchOptionsShowsTrafficKey: false]
        mapItem.openInMapsWithLaunchOptions(options as [NSObject : AnyObject])
    }
    
    func googleMapsAction()->UIAlertAction{
        return UIAlertAction(title: "Google Maps", style: .Default) { (action) -> Void in
            let placeGeo = self.myPlace!["location"] as! PFGeoPoint
            let directionsString = "comgooglemaps://?saddr=Current+Location&daddr=\(placeGeo.latitude),\(placeGeo.longitude)&directionsmode=driving"
            UIApplication.sharedApplication().openURL(NSURL(string: directionsString)!)
        }
    }
    
    func cancelAction()->UIAlertAction{
        return UIAlertAction(title: "Cancel", style: .Cancel,handler: nil)
    }
    
    
    //MARK: Generic methods
    func viewLink(link:String,title:String){
        let navDestination = storyboard?.instantiateViewControllerWithIdentifier("deliveryWebViewNavScene") as! UINavigationController
        let destination = navDestination.viewControllers[0] as! GenericWebViewController
        destination.myURL = link
        destination.title = title
        
        self.showDetailViewController(navDestination, sender: nil)
    }
    
    func callPlace(){
        let url = NSURL(string: "telprompt://" + (myPlace!["phone"] as! String))!
        if UIApplication.sharedApplication().canOpenURL(url){
            UIApplication.sharedApplication().openURL(url)
        }
    }
}
