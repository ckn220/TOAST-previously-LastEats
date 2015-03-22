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

class ContributeViewController: UIViewController, iCarouselDataSource, iCarouselDelegate,ToastCarouselViewDelegate,SearchPlaceDelegate,ReviewPlaceDelegate {

    @IBOutlet weak var myCarousel:iCarousel!
    var oldOffset:CGSize?
    var tempToast = [String:AnyObject]()
    
    let myViews = NSBundle.mainBundle().loadNibNamed("CarouselViews", owner: nil, options: nil)
    var newToast:PFObject?
    let foursquareClientId = "2EDPPGSKXYRS3TIW4TIDKRXEGBNMIVMCC5HF4FAEZEHISGI4"
    let foursquareClientSecret = "H2GC5EERWD3RHBLMSGVEY55TI5JPA5HXZD4MRLO4XILVJ4HB"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        myCarousel.type = .Cylinder
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - iCarousel datasource methods
    func numberOfItemsInCarousel(carousel: iCarousel!) -> Int {
        return myViews.count
    }
    
    func carousel(carousel: iCarousel!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
        let imView = myViews[index] as ToastCarouselView
        imView.myDelegate = self
        imView.setViewValues(index: index)
        imView.frame = CGRectMake(0, 0, 320, 290)
        
        switch index {
        case 1:
            configureMoodsView(imView as ToastMoodsView)
        case 5:
            configureHashtagsView(imView as ToastHashtagsView)
        default:
            break
        }
        imView.layoutIfNeeded()
        
        return imView
    }
    
    func carousel(carousel: iCarousel!, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        switch option{
        case .Arc:
            return 3.14159265359*0.7
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
    
    /*
    func carouselWillBeginDragging(carousel: iCarousel!) {
        
    }
    
    func carouselDidScroll(carousel: iCarousel!) {
        
    }
    
    func carouselDidEndDecelerating(carousel: iCarousel!) {

    }*/
    
    func configureMoodsView(view:ToastMoodsView){
        //view.frame = CGRectMake(0, 0, 320, 320)
        PFQuery(className: "Mood").findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil {
                view.insertMoods(result as [PFObject])
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    func configureHashtagsView(view:ToastHashtagsView){
        view.frame = CGRectMake(0, 0, 320, 320)
        PFQuery(className: "Hashtag").findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil {
                view.insertHashtags(result as [PFObject])
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    //MARK: - ToastCarouselView delegate methods
    func toastCarouselViewDelegate(indexSelected index: Int, value: AnyObject?) {
        switch index{
        case 0:
            toastNameSelected()
        case 1:
            toastMoodsSelected(value as [PFObject]!)
        case 2:
            toastRushSelected(value as Bool)
        case 3:
            toastVegetarianSelected(value as Bool)
        case 4:
            toastReviewSelected(value as? Int)
        case 5:
            toastHashtagsSelected(value as [PFObject]!)
        case 6:
            toastSubmitSelected()
        default:
            return
        }
    }
    
    func toastCarouselViewDelegateGetTempToast() -> [String : AnyObject] {
        return tempToast
    }
    
    func toastNameSelected(){
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("searchPlaceScene") as SearchPlaceViewController
        destination.myDelegate = self
        self.showDetailViewController(destination, sender: nil)
    }
    
    func toastMoodsSelected(selectedMoods:[AnyObject]){
        tempToast["moods"] = selectedMoods
        scrollToIndex(2,delay:0.1)
    }
    
    func toastRushSelected(isRuch:Bool){
        tempToast["isRush"]=isRuch
        scrollToIndex(3,delay:0.2)
    }
    
    func toastVegetarianSelected(isVegetarian:Bool){
        tempToast["isVegetarian"]=isVegetarian
        scrollToIndex(4,delay:0.2)
    }
    
    func toastReviewSelected(value:Int?){
        
        if value == nil{
            let destination = self.storyboard?.instantiateViewControllerWithIdentifier("reviewPlaceScene") as ReviewPlaceViewController
            let hashtagsView = myCarousel.itemViewAtIndex(5) as ToastHashtagsView
            destination.myDelegate = self
            destination.hashtags = hashtagsView.hashtags
            self.showDetailViewController(destination, sender: nil)
        }else{
            scrollToIndex(5, delay: 0.1)
        }
    }
    
    func toastHashtagsSelected(selectedMoods:[AnyObject]){
        tempToast["hashtags"] = selectedMoods
        scrollToIndex(6,delay:0.1)
    }
    
    //MARK: SearchPlace delegate methods
    func searchPlaceIdSelected(placeTemp: (placeId: String, name: String)) {
        tempToast["placeId"] = placeTemp.placeId
        tempToast["placeName"] = placeTemp.name
       let nameView = myCarousel.itemViewAtIndex(0) as ToastNameView
        nameView.nameLabel.text = placeTemp.name
        nameView.nameLabel.alpha = 1
        
        scrollToIndex(1,delay:0.6)
    }
    
    //MARK: ReviewPlace delegate methods
    func reviewPlaceDoneEditing(#review: String?) {
        let reviewView = myCarousel.itemViewAtIndex(4) as ToastReviewView
        if let reviewValue = review {
            tempToast["review"] = review
            reviewView.reviewTextView.text = review
            reviewView.reviewTextView.alpha = 1
            scrollToIndex(6, delay: 0.6)
        }else{
            reviewView.reviewTextView.text = "Edit text"
            reviewView.reviewTextView.alpha = 0.5
        }
    }
    
    //MARK: - Misc methods
    func scrollToIndex(index: Int,delay: NSTimeInterval){
        callSelectorAsync(Selector("goTo:"), object: index, delay: delay)
    }
    
    func goTo(timer:NSTimer){
        myCarousel.scrollToItemAtIndex(timer.userInfo as Int, duration: 0.4)
    }
    
    func callSelectorAsync(selector: Selector, object: AnyObject?, delay: NSTimeInterval) -> NSTimer {
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: selector, userInfo: object, repeats: false)
        return timer
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    @IBAction func closePressed(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - Submit methods
    func toastSubmitSelected(){
        createToast()
        insertReview()
        insertMoods()
        insertHashtags()
        insertIsRush()
        insertIsVegetarian()
        
        newToast?.saveEventually({ (success, error) -> Void in
            if error==nil{
                self.insertPlace()
                self.insertToastInHashtags()
            }else{
                NSLog("%@ toasts error", error.description)
            }
        })
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func createToast(){
        newToast = PFObject(className: "Toast")
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
        //TODO Extract new hashtags from review
        
        let hashtagsRelation = self.newToast!.relationForKey("hashtags")
        if let myHashtags = tempToast["hashtags"] as? [PFObject] {
            for q:PFObject in myHashtags{
                hashtagsRelation.addObject(q)
            }
        }
    }
    
    func insertIsRush(){
        if let isRush = tempToast["isRush"] as? Bool{
            newToast?["isRush"]=isRush
        }
    }
    
    func insertIsVegetarian(){
        if let isVegetarian = tempToast["isVegetarian"] as? Bool{
            newToast?["isVegetarian"]=isVegetarian
        }
    }
    
    func insertReview(){
        if let myReview = tempToast["review"] as? String{
            newToast?["review"]=myReview
        }
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
            
            place["location"] = PFGeoPoint(latitude: location["lat"] as Double, longitude: location["lng"] as Double)
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
                let imCategory = cat as NSDictionary
                if imCategory["primary"] as Bool {
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
        newCategory.saveEventually { (success, error) -> Void in
            if error == nil{
                place["category"] = newCategory
            }else{
                NSLog("%@", error.description)
            }
        }
    }
    
    func insertInstagramPicture(inPlace place: PFObject){
        let foursquareId = place["foursquarePlaceId"] as String
        InstagramEngine.sharedEngine().getMediaAtFoursquareId(foursquareId, withSuccess: { (result:[AnyObject]!, _) -> Void in
            
            if result.count > 0{
                for (picture : InstagramMedia) in (result as [InstagramMedia]) {
                    if picture.isVideo == false {
                        place["picture"] = picture.standardResolutionImageURL.absoluteString
                        break
                    }
                }
                self.insertPlace(place)
            }
            
            }, failure: { (error) -> Void in
                NSLog("%@",error.description)
                self.insertPlace(place)
        })
    }
    
    func insertFoursquarePicture(json:NSDictionary,inPlace place:PFObject){
        let photos = json["photos"] as NSDictionary
        if photos["count"] as Int > 0{
            let groups = photos["groups"] as NSArray
            var validGroup: NSDictionary?
            for imGroup in groups{
                if (imGroup as NSDictionary)["count"] as Int > 0{
                    validGroup = imGroup as? NSDictionary
                    break
                }
            }
            
            let items = validGroup?["items"] as NSArray
            let firstItem = items[0] as NSDictionary
            let url = (firstItem["prefix"] as String) + "500x500" + (firstItem["suffix"] as String)
            place["foursquarePicture"] = url
            
        }
    }
    
    func insertMenuLink(json:NSDictionary,inPlace place:PFObject){
        if let menu = json["menu"] as? NSDictionary {
            place["menuLink"] = menu["mobileUrl"] as String
        }
    }
    
    func insertWebsite(json:NSDictionary,inPlace place:PFObject){
        if let url = json["url"] as? String{
            place["url"] = url
        }
    }
    
    func insertSchedule(json:NSDictionary,inPlace place:PFObject){
        if let schedulesDic = json["hours"] as? NSDictionary{
            let timeframes = schedulesDic["timeframes"] as NSArray
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
            schedules.extend(schedulesForTimeframe(timeframe as NSDictionary))
        }
        return schedules
    }
    
    func schedulesForTimeframe(timeframe:NSDictionary) -> [PFObject]{
        var hours = [PFObject]()
        let myDays = days(timeframe["days"] as String)
        let myHours = openHours(timeframe["open"] as NSArray)
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
        var dayStrings:[String] = daysTimeFrame.componentsSeparatedByString("–")
        if dayStrings.count > 1{
            let firstDay = day(dayStrings[0])
            let lastDay = day(dayStrings[1])
            return allDays(from:firstDay, to: lastDay)
            
        }else{
            return [day(daysTimeFrame)]
        }
    }
    
    func day(dayString:String)->Int{
        let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        return find(days,dayString)!
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
            let hoursString = (openItem as NSDictionary)["renderedTime"] as String
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
        var hours = [Int]()
        for h in from..<to{
            hours.append(h)
        }
        return hours
    }
    
    func realHour(hourString:String)->Int{
        let isPM = hourString.rangeOfString("PM") != nil
        let h = hourString.componentsSeparatedByString(":")[0].toInt()!
        
        if isPM{
            return h + 12
        }else{
            return h
        }
    }
    
    func createNewPlace(){
        
        let myPlace = PFObject(className: "Place")
        myPlace["name"] = tempToast["placeName"]
        
        if let myPlaceID = tempToast["placeId"] as? String{
            myPlace["foursquarePlaceId"] = myPlaceID
            
            Alamofire.request(.GET, "https://api.foursquare.com/v2/venues/"+myPlaceID+"?&client_id="+self.foursquareClientId+"&client_secret="+self.foursquareClientSecret+"&v=20150207&locale=en").responseJSON({ (request, response, JSON, error) -> Void in
                
                if error == nil{
                    let result = ((JSON as NSDictionary)["response"] as NSDictionary)["venue"] as NSDictionary
                    
                    self.insertLocation(result, inPlace: myPlace)
                    self.insertPhone(result, inPlace: myPlace)
                    self.insertPrice(result, inPlace: myPlace)
                    self.insertCategory(result, inPlace: myPlace)
                    self.insertInstagramPicture(inPlace: myPlace)
                    self.insertFoursquarePicture(result, inPlace: myPlace)
                    self.insertMenuLink(result, inPlace: myPlace)
                    self.insertWebsite(result, inPlace: myPlace)
                    self.insertSchedule(result, inPlace: myPlace)
                    
                }else{
                    NSLog("%@", error!.description)
                    self.insertPlace(myPlace)
                }
                
            })
        }else{
            self.insertPlace(myPlace)
        }
    }
    
    func insertPlace(place: PFObject){
        
        place.saveEventually { (success, error) -> Void in
            
            if error == nil{
                
                let placeQuery = PFQuery(className: "Place")
                placeQuery.whereKey("foursquarePlaceId", equalTo: place["foursquarePlaceId"])
                placeQuery.getFirstObjectInBackgroundWithBlock({ (result, error) -> Void in
                    if error == nil {
                        let newPlace = result as PFObject
                        self.newToast?["place"] = newPlace
                        self.newToast?.saveEventually({ (success, error) -> Void in
                            let toastsRelation = newPlace.relationForKey("toasts")
                            toastsRelation.addObject(self.newToast)
                            newPlace.saveEventually(nil)
                        })
                    }
                })
                
                
            }else{
                NSLog("+===+++===++NO GUARDO PLACE===+++++++")
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
                h.relationForKey("toasts").addObject(self.newToast)
                h.saveEventually(nil)
            }
        }
    }
}
