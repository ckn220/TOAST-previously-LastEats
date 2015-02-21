//
//  Contribute2TableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 1/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire

class Contribute2TableViewController: UITableViewController,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UINavigationBarDelegate {
    
    var myToast : PFObject?
    var myPlaceID: String?
    var myPlaceName: String?
    var hashtags : [PFObject]?
    var selectedHashtags : [PFObject]?
    
    let foursquareClientId = "2EDPPGSKXYRS3TIW4TIDKRXEGBNMIVMCC5HF4FAEZEHISGI4"
    let foursquareClientSecret = "H2GC5EERWD3RHBLMSGVEY55TI5JPA5HXZD4MRLO4XILVJ4HB"

    
    @IBOutlet weak var hashtagsTextfield: UITextField!
    @IBOutlet weak var hashtagsCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hashtags = []
        selectedHashtags = []
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let query = PFQuery(className: "Hashtag")
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            
            if error == nil{
                self.hashtags = result as? [PFObject]
                self.hashtagsCollectionView.reloadData()
            }else{
                NSLog("%@", error.description)
            }
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: CollectionView datasource methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashtags!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("hashtagCell", forIndexPath: indexPath) as UICollectionViewCell
        
        let currentHashtag = hashtags?[indexPath.row]
        let hashtagLabel = cell.viewWithTag(101) as UILabel
        
        hashtagLabel.text = "#" + (currentHashtag?["name"] as? String)!
        if contains(selectedHashtags!,currentHashtag!){
            hashtagLabel.textColor = UIColor.blueColor()
        }else{
            hashtagLabel.textColor = UIColor.blackColor()
        }
        
        return cell
    }
    
    //MARK: CollectionView delegate methods
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.frame.width/2, 44)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let selectedCell = hashtagsCollectionView.cellForItemAtIndexPath(indexPath)
        let myLabel = selectedCell?.viewWithTag(101)! as UILabel
        
        myLabel.textColor = UIColor.blueColor()
        selectedHashtags?.append(hashtags![indexPath.row])
    }
    
    //MARK: Action methods
    @IBAction func savePressed(sender: AnyObject) {
        
        insertHashtags()
        
        myToast?.saveEventually({ (success, error) -> Void in
            if error==nil{
                self.insertPlace()
                self.insertToastInHashtags()
            }else{
                NSLog("%@ toasts error", error.description)
            }
        })
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
 
    //MARK: Toast properties methods
    func insertHashtags(){
        if hashtagsTextfield.text.isEmpty == false {
            let newHashtags = hashtagsTextfield.text.componentsSeparatedByString(" ")
            for newht:String in newHashtags{
                let correctedNew = newht.substringFromIndex(advance(newht.startIndex, 1))
                let newHashObject = PFObject(className: "Hashtag")
                newHashObject["name"] = correctedNew
                newHashObject.saveEventually(nil)
                selectedHashtags?.append(newHashObject)
            }
        }
        
        
        //Asociate popular hashtags
        let hashtagsRelation = myToast?.relationForKey("hashtags")
        for h:PFObject in selectedHashtags!{
            hashtagsRelation?.addObject(h)
        }
    }
    
    func insertPlace(){
        let queryPlace = PFQuery(className: "Place")
        queryPlace.whereKey("foursquarePlaceId", equalTo: self.myPlaceID!)
        queryPlace.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            
            if object == nil{
                self.createNewPlace()
            }else{
                self.insertPlace(object)
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
    
    func createNewPlace(){
        let myPlace = PFObject(className: "Place")
        myPlace["name"] = self.myPlaceName
        myPlace["foursquarePlaceId"] = self.myPlaceID
        
        if self.myPlaceID?.isEmpty == false{
            Alamofire.request(.GET, "https://api.foursquare.com/v2/venues/"+self.myPlaceID!+"?&client_id="+self.foursquareClientId+"&client_secret="+self.foursquareClientSecret+"&v=20150207").responseJSON({ (request, response, JSON, error) -> Void in
                
                if error == nil{
                    let result = ((JSON as NSDictionary)["response"] as NSDictionary)["venue"] as NSDictionary
                    
                    self.insertLocation(result, inPlace: myPlace)
                    self.insertPhone(result, inPlace: myPlace)
                    self.insertPrice(result, inPlace: myPlace)
                    self.insertCategory(result, inPlace: myPlace)
                    self.insertInstagramPicture(inPlace: myPlace)
                    self.insertFoursquarePicture(result, inPlace: myPlace)
                    self.insertMenuLink(result, inPlace: myPlace)
                
                }else{
                    NSLog("%@", error!.description)
                    self.insertPlace(myPlace)
                }
                
            })
        }else{
            myPlace["name"] = self.myPlaceName
            self.insertPlace(myPlace)
        }
    }
    
    func insertPlace(place: PFObject){
        
        place.saveEventually { (success, error) -> Void in
            
            if error == nil{
                
                let placeQuery = PFQuery(className: "Place")
                placeQuery.whereKey("foursquarePlaceId", equalTo: self.myPlaceID)
                placeQuery.getFirstObjectInBackgroundWithBlock({ (result, error) -> Void in
                    if error == nil {
                        let newPlace = result as PFObject
                        self.myToast?["place"] = newPlace
                        self.myToast?.saveEventually({ (success, error) -> Void in
                            let toastsRelation = newPlace.relationForKey("toasts")
                            toastsRelation.addObject(self.myToast)
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
    
    func insertToastInHashtags(){
        //Adding inverse relationship - Hashtags
        for h:PFObject in self.selectedHashtags!{
            h.relationForKey("toasts").addObject(self.myToast!)
            h.saveEventually(nil)
        }
    }
    
    func validateAndInsert(field:String,from dic:NSDictionary,inPlace place:PFObject){
        if let value = dic[field] as? String{
            place[field]=value
        }
    }
}
