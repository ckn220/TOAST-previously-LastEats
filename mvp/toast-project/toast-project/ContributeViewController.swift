//
//  ContributeViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire
import Foundation

class ContributeViewController: UIViewController, iCarouselDataSource, iCarouselDelegate,ToastCarouselViewDelegate,SearchPlaceDelegate {

    @IBOutlet weak var myNavBar: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var myCarousel:iCarousel!
    @IBOutlet weak var searchNameContainerView: UIView!
    @IBOutlet weak var goToReviewButton: UIButton!
    @IBOutlet weak var changeNameButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    
    
    var isStatusBarHidden = true
    var tempToast = [String:AnyObject]()
    var tempReview:String?
    
    var itemsCount = 2
    let myViews = NSBundle.mainBundle().loadNibNamed("CarouselViews", owner: nil, options: nil)
    var newToast:PFObject?
    let foursquareClientId = "2EDPPGSKXYRS3TIW4TIDKRXEGBNMIVMCC5HF4FAEZEHISGI4"
    let foursquareClientSecret = "H2GC5EERWD3RHBLMSGVEY55TI5JPA5HXZD4MRLO4XILVJ4HB"
    var searchNameController: SearchPlaceViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        myCarousel.type = .Cylinder
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func toggleNavBar(#isVisible:Bool){
        UIView.animateWithDuration(0.15, animations: { () -> Void in
            if isVisible{
                self.titleLabel.alpha = 1
                self.changeNameButton.alpha = 1
                self.submitButton.alpha = 0
            }else{
                self.titleLabel.alpha = 0
                self.changeNameButton.alpha = 0
            }
        })
    }
    
    private func toggleSubmitButton(#isVisible:Bool){
        
        if isVisible && self.submitButton.alpha == 0{
            UIView.animateKeyframesWithDuration(0.3, delay: 0, options: .CalculationModeLinear, animations: { () -> Void in
                
                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5, animations: { () -> Void in
                    self.submitButton.alpha = 1
                    self.changeNameButton.alpha = 0
                    self.submitButton.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1)
                })
                UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: { () -> Void in
                    self.submitButton.layer.transform = CATransform3DMakeScale(1, 1, 1)
                })
                
            }, completion: nil)
        }else if !isVisible && self.submitButton.alpha == 1{
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                self.submitButton.alpha = 0
                self.changeNameButton.alpha = 1
            })
        }        
    }
    
    //MARK: - iCarousel datasource methods
    func numberOfItemsInCarousel(carousel: iCarousel!) -> Int {
        return itemsCount
    }
    
    func carousel(carousel: iCarousel!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
        let imView = myViews[index] as! ToastCarouselView
        imView.myDelegate = self
        imView.setViewValues(index: index)
        imView.frame = CGRectMake(0, 0, 320, itemHeight(forIndex:index))
        
        switch index {
        case 1:
            configureMoodsView(imView as! ToastMoodsView)
        default:
            break
        }
        imView.layoutIfNeeded()
        
        return imView
    }
    
    private func itemHeight(forIndex index:Int) -> CGFloat{
        if index == 2{
            return CGRectGetHeight(myCarousel.bounds)
        }else{
            return 290
        }
    }
    
    func carousel(carousel: iCarousel!, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        switch option{
        case .Arc:
            if itemsCount > 2{
                return 3.14159265359*0.7
            }else{
                return 3.14159265359*0.7*2/3
            }
        case .Spacing:
            return 1.15
        case .Wrap:
            return 0
        case .ShowBackfaces:
            return 0
        case .FadeMin:
            return -0.2
        case .FadeMax:
            return 0.2
        case .FadeRange:
            return 1.2
        default:
            return value
        }
    }
    
    func configureMoodsView(view:ToastMoodsView){
        PFQuery(className: "Mood").findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil {
                view.insertMoods(result as! [PFObject])
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    //MARK: - ToastCarouselView delegate methods
    func toastCarouselView(indexSelected index: Int, value: AnyObject?) {
        switch index{
        case 0:
            toastNameSelected()
        case 1:
            toastMoodsSelected(value as! [PFObject]!)
        default:
            return
        }
    }
    
    func toastCarouselViewGetTempToast() -> [String : AnyObject] {
        return tempToast
    }
    
    func toastCarouselViewMoodsSelected(moods:[PFObject]) {
        tempToast["moods"] = moods
        
        toggleGoToReview(moods.count > 0)
        toggleReviewItem(moods.count > 0)
    }
    
    private func toggleGoToReview(isVisible:Bool){
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            if isVisible{
                self.goToReviewButton.alpha = 1
            }else{
                self.goToReviewButton.alpha = 0
            }
        })
    }
    
    private func toggleReviewItem(isVisible:Bool){
        if isVisible && itemsCount == 2{
            itemsCount = 3
            myCarousel.insertItemAtIndex(2, animated: true)
        }else if !isVisible && itemsCount == 3{
            if myCarousel.itemViewAtIndex(2) != nil{
                let reviewView = myCarousel.itemViewAtIndex(2) as! ToastReviewView
                reviewView.toggleFocus(false)
            }
            itemsCount = 2
            myCarousel.removeItemAtIndex(2, animated: true)
        }
    }
    
    func toastNameSelected(){
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("searchPlaceScene") as! SearchPlaceViewController
        destination.myDelegate = self
        self.showDetailViewController(destination, sender: nil)
    }
    
    func toastMoodsSelected(selectedMoods:[AnyObject]){
        tempToast["moods"] = selectedMoods
        scrollToIndex(2,delay:0.1)
    }
    
    func carouselCurrentItemIndexDidChange(carousel: iCarousel!) {
        currentItemChanged(carousel.currentItemIndex)
    }
    
    private func currentItemChanged(index:Int){
        
        if myCarousel.numberOfItems == 3{
            let reviewView = myCarousel.itemViewAtIndex(2) as! ToastReviewView
            reviewView.toggleFocus(index == 2)
            if index == 2{
                reviewView.moods = tempToast["moods"] as! [PFObject]
            }
        }
        
        if index == 0{
            toggleNavBar(isVisible: false)
            restartMoods()
            toggleReviewItem(false)
            toggleGoToReview(false)
            searchNameContainerView.alpha = 1
            searchNameController.showSearchBar()
        }else{
            toggleNavBar(isVisible: true)
        }
    }
    
    private func restartMoods(){
        if myCarousel.itemViewAtIndex(1) != nil{
            let moodsView = myCarousel.itemViewAtIndex(1) as! ToastMoodsView
            moodsView.restartMoods()
        }
    }
    
    func toastCarouselViewReviewEditing(text: String) {
        if count(text.utf16) > 0{
            toggleSubmitButton(isVisible: true)
        }else{
            toggleSubmitButton(isVisible: false)
        }
    }
    
    //MARK: SearchPlace delegate methods
    func searchPlaceIdSelected(placeTemp: (placeId: String, name: String)) {
        tempToast["placeId"] = placeTemp.placeId
        tempToast["placeName"] = placeTemp.name
        titleLabel.text = placeTemp.name
        
       let nameView = myCarousel.itemViewAtIndex(0) as! ToastNameView
        nameView.nameLabel.text = placeTemp.name
        
        UIView.animateKeyframesWithDuration(0.3, delay: 0, options: .CalculationModeLinear, animations: { () -> Void in
            
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5, animations: { () -> Void in
                nameView.nameLabel.alpha = 1
                nameView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1)
            })
            
            UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: { () -> Void in
                nameView.nameLabel.alpha = 1
                nameView.layer.transform = CATransform3DMakeScale(1, 1, 1)
                
            })
        }, completion: nil)
        
        isStatusBarHidden = false
        hideSearchNameView(delay: 0)
        scrollToIndex(1,delay:0.6)
    }
    
    func searchPlaceCancelled() {
        //hideSearchNameView(delay: 0)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func hideSearchNameView(#delay:NSTimeInterval){
        UIView.animateWithDuration(0.15, delay: delay, options: .CurveLinear, animations: { () -> Void in
            self.searchNameContainerView.alpha = 0
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }
    
    //MARK: ReviewPlace delegate methods
    func reviewPlaceDoneEditing(#review: String?,hashtags:[PFObject]) {
        let reviewView = myCarousel.itemViewAtIndex(2) as! ToastReviewView
        if let reviewValue = review {
            tempToast["review"] = review
            reviewView.reviewTextView.text = review
            reviewView.reviewTextView.alpha = 1
        }else{
            reviewView.reviewTextView.text = "Edit text"
            reviewView.reviewTextView.alpha = 0.5
        }
        reviewView.reviewTextView.textColor = UIColor.whiteColor()
        reviewView.reviewTextView.font = UIFont(name: "Avenir-Roman", size: 17)
        
        if hashtags.count > 0{
            tempToast["hashtags"] = hashtags
        }
    }
    
    //MARK: - Misc methods
    func scrollToIndex(index: Int,delay: NSTimeInterval){
        callSelectorAsync(Selector("goTo:"), object: index, delay: delay)
    }
    
    func goTo(timer:NSTimer){
        myCarousel.scrollToItemAtIndex(timer.userInfo as! Int, duration: 0.4)
    }
    
    func callSelectorAsync(selector: Selector, object: AnyObject?, delay: NSTimeInterval) -> NSTimer {
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: selector, userInfo: object, repeats: false)
        return timer
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true//isStatusBarHidden
    }
    
    @IBAction func closePressed(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - Submit methods
    @IBAction func submitPressed(sender: AnyObject) {
        let reviewTextView = (myCarousel.itemViewAtIndex(2) as! ToastReviewView).reviewTextView
        tempReview = reviewTextView.text
        createToast()
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            let post = self.storyboard?.instantiateViewControllerWithIdentifier("postContributeScene") as! PostContributeViewController!
            post.transitioningDelegate = post
            post.tempToast = self.tempToast
            self.showDetailViewController(post, sender: self)
        }
        reviewTextView.resignFirstResponder()
        CATransaction.commit()
        
        
        //self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func createToast(){
        newToast = PFObject(className: "Toast")
        insertData()
        
        newToast?.saveInBackgroundWithBlock({ (success, error) -> Void in
            if error == nil{
                self.newToast?.fetchIfNeededInBackgroundWithBlock({ (result, error) -> Void in
                    if error == nil{
                        self.newToast = result
                        self.insertPlace()
                    }else{
                        NSLog("%@",error.description);
                    }
                })
            }else{
                NSLog("%@",error.description)
            }
            
        })
    }
    
    private func insertData(){
        insertReview()
        insertMoods()
        insertUser()
    }
    
    func insertUser(){
        newToast?["user"]=PFUser.currentUser()
    }
    
    func insertMoods(){
        let moodsRelation = self.newToast!.relationForKey("moods")
        if let myMoods = tempToast["moods"] as? [PFObject] {
            for q:PFObject in myMoods{
                moodsRelation.addObject(q)
            }
        }
    }
    
    func insertHashtags(){
        
        HashtagsManager.hashtagsFromReview(tempReview!,toastID: newToast!.objectId)
    }
    
    func insertReview(){
        let reviewView = myCarousel.itemViewAtIndex(2) as! ToastReviewView
        newToast?["review"] = reviewView.reviewTextView.text
    }
    
    func insertPlace(){
        if let myPlaceId = tempToast["placeId"] as? String {
            let queryPlace = PFQuery(className: "Place")
            queryPlace.whereKey("foursquarePlaceId", equalTo: myPlaceId)
            queryPlace.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
                
                if object == nil{
                    self.createNewPlace()
                }else{
                    self.insertPlace(object)
                }
                
            }
        }
    }
    
    //MARK: Place properties methods
    func insertLocation(json:NSDictionary,inPlace place: PFObject){
        
        if let location = json["location"] as? NSDictionary{
            validateAndInsert("address", from: location, inPlace: place)
            validateAndInsert("city", from: location, inPlace: place)
            validateAndInsert("state", from: location, inPlace: place)
            validateAndInsert("postalCode", from: location, inPlace: place)
            
            place["location"] = PFGeoPoint(latitude: location["lat"] as! Double, longitude: location["lng"] as! Double)
        }
    }
    
    func insertPhone(json:NSDictionary,inPlace place: PFObject){
        if let contact = json["contact"] as? NSDictionary{
            validateAndInsert("formattedPhone", from: contact, inPlace: place)
            validateAndInsert("phone", from: contact, inPlace: place)
        }
        
    }
    
    func insertPrice(json:NSDictionary,inPlace place: PFObject){
        if let price = json["price"] as? NSDictionary{
            place["price"] = price["tier"]
        }
    }
    
    func insertCategory(json:NSDictionary,inPlace place: PFObject){
        if let categories = json["categories"] as? NSArray{
            for cat in categories{
                let imCategory = cat as! NSDictionary
                if imCategory["primary"] as! Bool {
                    searchForCategory(imCategory, forPlace: place)
                    break
                }
            }
        }
    }
    
    func searchForCategory(category: NSDictionary, forPlace place:PFObject){
        let categoryQuery = PFQuery(className: "Category")
        categoryQuery.whereKey("foursquareId", equalTo: category["id"])
        categoryQuery.getFirstObjectInBackgroundWithBlock { (result, error) -> Void in
            if error == nil {
                place["category"] = result
            }else{
                NSLog("%@",error.description)
                self.insertNewCategory(category, inPlace: place)
            }
        }
    }
    
    func insertNewCategory(category: NSDictionary, inPlace place: PFObject){
        let newCategory = PFObject(className: "Category")
        newCategory["foursquareId"] = category["id"]
        newCategory["name"] = category["name"]
        newCategory.saveInBackgroundWithBlock { (success, error) -> Void in
            if error == nil{
                place["category"] = newCategory
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    func insertFoursquarePicture(json:NSDictionary,inPlace place:PFObject){
        
        var photosURL = [String]()
        var bestID:String = ""
        let bestURL = bestPhotoURL(json,bestID: &bestID)
        if bestURL != nil{
            photosURL.append(bestURL!)
        }
        
        let photos = json["photos"] as! NSDictionary
        photosURL.extend(photosURLs(photos, bestID: bestID))
        place["photos"] = photosURL
    }
    
    private func bestPhotoURL(json:NSDictionary,inout bestID:String)->String?{
        if let best = json["bestPhoto"] as? NSDictionary{
            bestID = best["id"] as! String
            return (best["prefix"] as! String) + "500x500" + (best["suffix"] as! String)
        }else{
            return nil
        }
    }
    
    private func photosURLs(photos:NSDictionary,bestID:String)-> [String]{
        var urls = [String]()
        if photos["count"] as! Int > 0{
            let groups = photos["groups"] as! NSArray
            var validGroup: NSDictionary?
            for imGroup in groups{
                if (imGroup as! NSDictionary)["count"] as! Int > 0{
                    validGroup = imGroup as? NSDictionary
                    let items = validGroup?["items"] as! NSArray
                    for item in items{
                        if (item["id"] as! String) != bestID {
                            urls.append((item["prefix"] as! String) + "500x500" + (item["suffix"] as! String))
                            
                            if urls.count == 4{
                                break
                            }
                        }
                    }
                    break
                }
            }
        }
        
        return urls
    }
    
    func insertMenuLink(json:NSDictionary,inPlace place:PFObject){
        if let menu = json["menu"] as? NSDictionary {
            place["menuURL"] = menu["mobileUrl"] as! String
        }
    }
    
    func insertWebsite(json:NSDictionary,inPlace place:PFObject){
        if let url = json["url"] as? String{
            place["url"] = url
        }
    }
    
    func insertSchedule(json:NSDictionary,inPlace place:PFObject){
        if let schedulesDic = json["hours"] as? NSDictionary{
            let timeframes = schedulesDic["timeframes"] as! NSArray
            var placeSchedules = schedules(timeframes: timeframes)
            PFObject.saveAllInBackground(placeSchedules, block: { (success, error) -> Void in
                if error == nil{
                    var openKey = place.relationForKey("open")
                    for schedule in placeSchedules{
                        openKey.addObject(schedule)
                    }
                }else{
                    NSLog("%@", error.description)
                }
            })
        }
    }
    
    func schedules(#timeframes:NSArray) -> [PFObject]{
        var schedules = [PFObject]()
        for timeframe in timeframes{
            schedules.extend(schedulesForTimeframe(timeframe as! NSDictionary))
        }
        return schedules
    }
    
    func schedulesForTimeframe(timeframe:NSDictionary) -> [PFObject]{
        var hours = [PFObject]()
        let myDays = days(timeframe["days"] as! String)
        let myHours = openHours(timeframe["open"] as! NSArray)
        for imDay in myDays{
            for imHour in myHours{
                hours.append(createSchedule(day: imDay, hour: imHour))
            }
        }
        return hours
    }
    
    func createSchedule(#day:Int,hour:Int) -> PFObject{
        let newOpen = PFObject(className: "OpenSchedule")
        newOpen["day"] = day
        newOpen["hour"] = hour
        return newOpen
    }
    
    func days(daysTimeFrame:String)->[Int]{
        let strings:[String] = daysTimeFrame.componentsSeparatedByString(", ")
        var days = [Int]()
        for s in strings{
            if isDayRange(s){
                let range:[String] = s.componentsSeparatedByString("–")
                let firstDay = day(range[0])
                let lastDay = day(range[1])
                days.extend(allDays(from:firstDay,to:lastDay))
            }else{
                days.append(day(s))
            }
        }
        return days

    }
    
    func isDayRange(string:String)->Bool{
        var dayStrings:[String] = string.componentsSeparatedByString("–")
        if dayStrings.count > 1{
            return true
        }else{
            return false
        }
    }
    
    func isDayList(string:String)->Bool{
        var dayStrings:[String] = string.componentsSeparatedByString(", ")
        if dayStrings.count > 1{
            return true
        }else{
            return false
        }
    }
    
    func day(dayString:String)->Int{
        let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        let correctedDay = replaceStrings([" "], withString: "", from: dayString)
        return find(days,correctedDay)!
    }
    
    func allDays(#from:Int,to:Int)-> [Int]{
        var days = [Int]()
        for d in from...to{
            days.append(d)
        }
        return days
    }
    
    func openHours(openArray:NSArray) -> [Int]{
        var hours = [Int]()
        for openItem in openArray{
            let hoursString = (openItem as! NSDictionary)["renderedTime"] as! String
            hours.extend(realHours(hoursString))
        }
        return hours
    }
    
    func realHours(hoursTimeframe:String)->[Int]{
        var hours = [Int]()
        var hourStrings:[String] = hoursTimeframe.componentsSeparatedByString("–")
        let firstH = realHour(hourStrings[0])
        let lastH = realHour(hourStrings[1])
        hours.extend(allHours(from:firstH,to:lastH))
        
        return hours
    }
    
    func allHours(#from:Int,to:Int) -> [Int]{
        var correctedTo = to
        if from > to{
            correctedTo = to + 24
        }
        var hours = [Int]()
        for h in from..<correctedTo{
            hours.append(h)
        }
        return hours
    }
    
    func realHour(hourString:String)->Int{
        if hourString != ""{
            if hourString == "Midnight"{
                return 24
            }
            
            if hourString == "Noon"{
                return 12
            }
            
            if hourString == "24 hours"{
                return 0
            }
            
            let isPM = hourString.rangeOfString("PM") != nil
            let h = hourString.componentsSeparatedByString(":")[0].toInt()!
            
            if isPM{
                return h + 12
            }else{
                return h
            }
        }else{
            return 25
        }
    }
    
    private func insertReservationPlace(json:NSDictionary,inPlace place:PFObject,completion:(Bool)->Void){
        
        let name = place["name"] as? String
        let address = place["address"] as? String
        let zipcode = place["postalCode"] as? String
        
        if name != nil && address != nil && zipcode != nil{
            BookingService.getReservationURL(fromName:name!, address: address!, zipcode:zipcode!) { (url) -> () in
                place["reservationURL"] = url as String
                completion(true)
            }
        }else{
            completion(false)
        }
    }
    
    func createNewPlace(){
        
        let myPlace = PFObject(className: "Place")
        myPlace["name"] = tempToast["placeName"]
        
        if let myPlaceID = tempToast["placeId"] as? String{
            myPlace["foursquarePlaceId"] = myPlaceID
            
            Alamofire.request(.GET, "https://api.foursquare.com/v2/venues/"+myPlaceID+"?&client_id="+self.foursquareClientId+"&client_secret="+self.foursquareClientSecret+"&v=20150207&locale=en").responseJSON(options:nil, completionHandler: { (request, response, JSON, error) -> Void in
                
                if error == nil{
                    
                    if let imResponse = ((JSON as! NSDictionary)["response"] as? NSDictionary){
                        let result = imResponse["venue"] as! NSDictionary
                        
                        self.insertLocation(result, inPlace: myPlace)
                        self.insertPhone(result, inPlace: myPlace)
                        self.insertPrice(result, inPlace: myPlace)
                        self.insertCategory(result, inPlace: myPlace)
                        self.insertFoursquarePicture(result, inPlace: myPlace)
                        self.insertMenuLink(result, inPlace: myPlace)
                        self.insertWebsite(result, inPlace: myPlace)
                        self.insertSchedule(result, inPlace: myPlace)
                        self.insertReservationPlace(result, inPlace: myPlace){(success) -> Void in
                            self.insertPlace(myPlace)
                        }
                    }else{
                        self.showErrorAlert()
                    }
                }else{
                    NSLog("%@", error!.description)
                }
                
            })
        }else{
            NSLog("Place not found in Foursquare.")
        }
    }
    
    func insertPlace(place: PFObject){
        let toastsRelation = place.relationForKey("toasts")
        toastsRelation.addObject(self.newToast)
        place.saveInBackgroundWithBlock { (success, error) -> Void in
            if error == nil{
                self.insertHashtags()
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    func validateAndInsert(field:String,from dic:NSDictionary,inPlace place:PFObject){
        if let value = dic[field] as? String{
            place[field]=value
        }
    }
    
    func insertToastInHashtags(){
        //Adding inverse relationship - Hashtags
        
        if let myHashtags = self.tempToast["hashtags"] as? [PFObject]{
            for h:PFObject in myHashtags{
                let oldCount = h["toastsCount"] as! Int
                h["toastsCount"] = oldCount + 1
                h.relationForKey("toasts").addObject(self.newToast)
                h.saveEventually(nil)
            }
        }
    }
    
    //MARK: - Misc methods
    private func replaceStrings(strings:[String],withString: String,from source: String) -> String
    {
        var result:String = source
        for s in strings{
            result = result.stringByReplacingOccurrencesOfString(s, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
        }
        return result
    }
    
    private func showErrorAlert(){
        let a = UIAlertController(title: "Connection Error", message: "There has been a server error. Please try again in a moment.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        a.addAction(okButton)
        self.showDetailViewController(a, sender: nil)
    }
    
    @IBAction func goToReviewPressed(sender: UIButton) {
        toggleGoToReview(false)
        scrollToIndex(2, delay: 0.1)
    }
    
    @IBAction func changeNamePressed(sender: UIButton) {
        scrollToIndex(0, delay: 0.0)
        currentItemChanged(0)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "searchNameSegue"{
            searchNameController = segue.destinationViewController as! SearchPlaceViewController
            searchNameController.myDelegate = self
        }
    }

    func keyboardWillShow(sender: NSNotification) {
        if let userInfo = sender.userInfo {
            if let keyboardHeight = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue().size.height {
                if myCarousel.itemViewAtIndex(2) != nil {
                    let reviewView = myCarousel.itemViewAtIndex(2) as! ToastReviewView
                    reviewView.keyboargHeight = keyboardHeight
                }
                
            }
        }
    }

}
