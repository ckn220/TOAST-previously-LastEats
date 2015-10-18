//
//  DiscoverViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 3/21/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

protocol DiscoverDelegate {
    func discoverMenuPressed()
    func discoverDidAppear()
    func discoverDidDissapear()
}

class DiscoverViewController: UIViewController,DiscoverDataSourceDelegate,MyLocationManagerDelegate {

    @IBOutlet var senteceSwipeGestureRecognizer: UISwipeGestureRecognizer!
    @IBOutlet var sentenceTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var myBG: BackgroundImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var sentenceLabel: UILabel!
    @IBOutlet weak var discoverCarousel: iCarousel!
    var myDelegate:DiscoverDelegate?
    
    var locationManager:MyLocationManager?
    var moodDataSource:DiscoverDataSource?
    var neighborhoodDataSource:DiscoverDataSource?
    var selectedMood: PFObject?
    var selectedNeighborhood:PFObject?
    let cache = Cache<UIImage>(name:"neighborhoods")
    
    var loaded = false
    var loadingTimer:NSTimer?
    var dotCount:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    func configure(){
        updateInitialData()
        configureInitialBG()
        //configureUserPicture()
        configureLocation()
        configureCarouselData()
    }
    
    private func updateInitialData(){
        PFCloud.callFunctionInBackground("setInitialDataIfNeeded", withParameters: nil) { (result, error) -> Void in
            if error == nil{
                NSLog("%@", result as! String)
            }
        }
    }
    
    private func configureInitialBG(){
        changeBGTo(nil)
    }
    /*
    private func configureUserPicture(){
        if let pictureURL = PFUser.currentUser()!["pictureURL"] as? String{
            let genericCache = Shared.imageCache
            genericCache.fetch(URL: NSURL(string: pictureURL)!, failure: { (error) -> () in
                NSLog("configureUserPicture error: %@",error!.description)
                }, success: {(image) -> () in
                    self.profilePictureView.myImage = image
            })
        }
    }*/
    
    func configureLocation(){
        locationManager = MyLocationManager(myDelegate: self)
    }
    
    func configureCarouselData(){
        let group = dispatch_group_create()
        configureMoods(group)
        configureNeighborhoods(group)
        configureCarouselDataCompletion(group)
    }
    
    func configureMoods(group:dispatch_group_t){
            dispatch_group_enter(group)
            let moodsQuery = PFQuery(className: "Mood")
            moodsQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
                if error == nil{
                    self.moodDataSource = DiscoverDataSource(items: result!, myDelegate: self, isMood: true)
                    dispatch_group_leave(group)
                    NSLog("Found moods")
                }else{
                    NSLog("configureMoods error: %@",error!.description)
                }
            }
    }
    
    func configureNeighborhoods(group:dispatch_group_t){
        //dispatch_group_enter(group)
            let neighborhoodsQuery = PFQuery(className: "Neighborhood")
            neighborhoodsQuery.whereKey("visible", equalTo: true)
            neighborhoodsQuery.orderByAscending("order")
            neighborhoodsQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
                if error == nil{
                    let neighs = result!
                    self.neighborhoodDataSource = DiscoverDataSource(items: neighs, myDelegate: self, isMood: false)
                    //dispatch_group_leave(group)
                }else{
                    NSLog("configureNeighborhoods error: %@", error!.description)
                }
            }
    }
    
    private func configureCarouselDataCompletion(group:dispatch_group_t){
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            self.loadingView.alpha = 0
            self.discoverCarousel.type = .Cylinder
            self.discoverCarousel.dataSource = self.moodDataSource
            self.discoverCarousel.delegate = self.moodDataSource
            self.discoverCarousel.reloadData()
        }
    }
    
    private func changeBGTo(neighborhood: PFObject?){
        var neighName:String
        if neighborhood != nil{
           neighName = neighborhood!["name"] as! String
            if neighName == "My current area"{
                neighName = "default"
            }
        }else{
           neighName = "default"
        }

        self.myBG.setImage(fileName: neighName, opacity: 0.6)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        myDelegate?.discoverDidAppear()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        myDelegate?.discoverDidDissapear()
    }
    
    
    //MARK: - MyLocationManager delegate methods
    func myLocationManagerDidGetUserLocation(location: CLLocation) {
        let geoPoint = PFGeoPoint(location: location)
        PFUser.currentUser()?["lastLocation"]=geoPoint
        PFUser.currentUser()?.saveInBackgroundWithBlock(nil)
    }
    
    func myLocationManagerFailed() {
        let alertController = UIAlertController(
            title: "Location Access Disabled",
            message: "In order to recieve accurate places information, please open this app's settings and set location access to 'While Using the App'.",
            preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: - DiscoverDataSource delegate methods
    func moodsDataSourceItemSelected(index index: Int) {
        selectedMood = moodDataSource!.myItems[index]
        changeToDataSource(neighborhoodDataSource!)
    }
    
    private func changeSentence(){
        UIView.animateWithDuration(0.1, delay: 0, options: .CurveLinear, animations: { () -> Void in
            self.sentenceLabel.alpha = 0
        }) { (completion) -> Void in
         UIView.animateWithDuration(0.1, delay: 0.1, options: .CurveLinear, animations: { () -> Void in
            self.sentenceLabel.alpha = 1
            
            if self.discoverCarousel.dataSource!.isEqual(self.moodDataSource!){
                self.changeSentenceForMood()
            }else{
                self.resetSentence()
            }
            
            },completion:nil)
        }
    }
    
    private func changeSentenceForMood(){
        let newString = NSMutableAttributedString(string: "I want something\r\n")
        let moodString = NSAttributedString(string: selectedMood!["name"] as! String, attributes: [NSUnderlineStyleAttributeName:1])
        let finalString = NSAttributedString(string: " in:")
        
        newString.appendAttributedString(moodString)
        newString.appendAttributedString(finalString)
        sentenceLabel.attributedText = newString
    }
    
    private func resetSentence(){
        sentenceLabel.text = "I want something:"
    }
    
    private func changeToDataSource(datasource:DiscoverDataSource){
        
        changeSentence()
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveLinear, animations: { () -> Void in
            self.discoverCarousel.alpha = 0
        }) { (completion) -> Void in
            self.discoverCarousel.dataSource = datasource
            self.discoverCarousel.delegate = datasource
            self.discoverCarousel.reloadData()
            self.toggleSentenceGestureRecognizers(!datasource.isMood)
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: .CurveLinear, animations: { () -> Void in
                self.discoverCarousel.alpha = 1
                if !datasource.isMood{
                    self.discoverCarousel.scrollToItemAtIndex(4, animated: false)
                }else{
                    let moodIndex = (self.moodDataSource!.myItems).indexOf(self.selectedMood!)
                    self.discoverCarousel.scrollToItemAtIndex(moodIndex!, animated: false)
                }
            }, completion: nil)
        }
    }
    
    func toggleSentenceGestureRecognizers(enabled:Bool){
        sentenceTapGestureRecognizer.enabled = enabled
        senteceSwipeGestureRecognizer.enabled = enabled
    }
    
    func neighborhoodsDataSourceItemSelected(index index: Int) {
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("toastsScene") as! ToastsViewController
        destination.myDelegate = nil
        destination.myMood = selectedMood
        let selectedNeigh = neighborhoodDataSource?.myItems[index]
        if (selectedNeigh!["name"] as! String) != "My current area"{
            destination.myNeighborhood = selectedNeigh
        }
        self.showViewController(destination, sender: self)
    }
    
    func neighborhoodsDataSourceCurrentItemChanged(item item: PFObject) {
        changeBGTo(item)
    }
    
    //MARK: - Sentence touch events
    @IBAction func sentenceTapped(sender: UITapGestureRecognizer) {
        changeToDataSource(moodDataSource!)
    }
    
    @IBAction func discoverSwiped(sender: UISwipeGestureRecognizer) {
        changeToDataSource(moodDataSource!)
    }
    //MARK: - Action methods
    @IBAction func menuPressed(sender: AnyObject) {
        myDelegate?.discoverMenuPressed()
    }
}
