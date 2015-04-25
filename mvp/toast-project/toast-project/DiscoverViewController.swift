//
//  DiscoverViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 3/21/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol DiscoverDelegate {
    func discoverMenuPressed()
    func discoverDidAppear()
    func discoverDidDissapear()
}

class DiscoverViewController: UIViewController,DiscoverDataSourceDelegate,MyLocationManagerDelegate {

    @IBOutlet weak var profilePictureView: BackgroundImageView!
    @IBOutlet weak var sentenceLabel: UILabel!
    @IBOutlet weak var discoverCarousel: iCarousel!
    var myDelegate:DiscoverDelegate?
    
    var locationManager:MyLocationManager?
    var moodDataSource:DiscoverDataSource?{
        didSet{
            discoverCarousel.type = .Cylinder
            discoverCarousel.dataSource = moodDataSource
            discoverCarousel.delegate = moodDataSource
            discoverCarousel.reloadData()
        }
    }
    var neighborhoodDataSource:DiscoverDataSource?
    var selectedMood: PFObject?
    var selectedNeighborhood:PFObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    func configure(){
        configureLocation()
        configureMoods()
        configureNeighborhoods()
    }
    
    func configureLocation(){
        locationManager = MyLocationManager(myDelegate: self)
    }
    
    func configureMoods(){
        let moodsQuery = PFQuery(className: "Mood")
        moodsQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.moodDataSource = DiscoverDataSource(items: result as! [PFObject], myDelegate: self, isMood: true)
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    func configureNeighborhoods(){
        let neighborhoodsQuery = PFQuery(className: "Neighborhood")
        neighborhoodsQuery.orderByAscending("order")
        neighborhoodsQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.neighborhoodDataSource = DiscoverDataSource(items: result as! [PFObject], myDelegate: self, isMood: false)
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureBG()
        configureProfilePicture()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        myDelegate?.discoverDidAppear()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        myDelegate?.discoverDidDissapear()
    }
    
    func configureBG(){
        let bgView = self.view as! BackgroundImageView
        bgView.insertImage(UIImage(named: "mainBG")!, withOpacity: 0.65)
    }
    
    func configureProfilePicture(){
        let pictureFile = PFUser.currentUser()["profilePicture"] as! PFFile
        pictureFile.getDataInBackgroundWithBlock { (data, error) -> Void in
            if error == nil {
                self.profilePictureView.myImage = UIImage(data: data)
                self.profilePictureView.layer.cornerRadius = CGRectGetWidth(self.profilePictureView.bounds)/2
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    //MARK: - MyLocationManager delegate methods
    func myLocationManagerDidGetUserLocation(location: CLLocation) {
        let geoPoint = PFGeoPoint(location: location)
        PFUser.currentUser()?["lastLocation"]=geoPoint
        PFUser.currentUser()?.saveEventually(nil)
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
    func moodsDataSourceItemSelected(#index: Int) {
        selectedMood = moodDataSource!.myItems[index]
        changeToDataSource(neighborhoodDataSource!)
        discoverCarousel.scrollToItemAtIndex(0, animated: true)
    }
    
    private func changeSentence(){
        UIView.animateWithDuration(0.1, delay: 0, options: .CurveLinear, animations: { () -> Void in
            self.sentenceLabel.alpha = 0
        }) { (completion) -> Void in
         UIView.animateWithDuration(0.1, delay: 0.1, options: .CurveLinear, animations: { () -> Void in
            self.sentenceLabel.alpha = 1
            
            if self.selectedMood != nil{
                self.sentenceLabel.text = "I want something\r\n"+(self.selectedMood!["name"] as! String)+" in"
            }else{
                self.sentenceLabel.text = "I want something:"
            }
            
            },completion:nil)
        }
    }
    
    private func changeToDataSource(datasource:DiscoverDataSource){
        
        changeSentence()
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveLinear, animations: { () -> Void in
            self.discoverCarousel.alpha = 0
        }) { (completion) -> Void in
            self.discoverCarousel.dataSource = datasource
            self.discoverCarousel.delegate = datasource
            self.discoverCarousel.reloadData()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: .CurveLinear, animations: { () -> Void in
                self.discoverCarousel.alpha = 1
            }, completion: nil)
        }
    }
    
    func neighborhoodsDataSourceItemSelected(#index: Int) {
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("toastsScene") as! ToastsViewController
        destination.myMood = selectedMood
        self.showViewController(destination, sender: self)
    }
    
    //MARK: - Sentence touch events
    @IBAction func sentenceTapped(sender: UITapGestureRecognizer) {
        if selectedMood != nil{
            selectedMood = nil
            changeToDataSource(moodDataSource!)
        }
    }
    
    //MARK: - Action methods
    @IBAction func menuPressed(sender: AnyObject) {
        myDelegate?.discoverMenuPressed()
    }
}
