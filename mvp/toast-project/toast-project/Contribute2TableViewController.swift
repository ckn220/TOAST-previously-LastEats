//
//  Contribute2TableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 1/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class Contribute2TableViewController: UITableViewController,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UINavigationBarDelegate {
    
    var myToast : PFObject?
    var hashtags : [PFObject]?
    var selectedHashtags : [PFObject]?
    
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
        (cell.viewWithTag(101) as UILabel).text = "#" + (currentHashtag?["name"] as? String)!
        
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
    
    @IBAction func savePressed(sender: AnyObject) {
        
        //Save new hashtags
        if hashtagsTextfield.text.isEmpty == false {
            let newHashtags = hashtagsTextfield.text.componentsSeparatedByString(" ")
            for newht:String in newHashtags{
                let correctedNew = newht.substringFromIndex(advance(newht.startIndex, 1))
                let newHashObject = PFObject(className: "Hashtag")
                newHashObject["name"] = correctedNew
                newHashObject.saveEventually(nil)
                hashtags?.append(newHashObject)
            }
        }
        
        
        //Asociate popular hashtags
        let hashtagsRelation = myToast?.relationForKey("hashtags")
        for h:PFObject in selectedHashtags!{
            hashtagsRelation?.addObject(h)
        }
        
        myToast?.saveEventually({ (success, error) -> Void in
            if error==nil{
                let imPlace = self.myToast?["place"] as PFObject
                imPlace.fetchIfNeededInBackgroundWithBlock({ (imObject, error) -> Void in
                    if error == nil{
                        let place = imObject as PFObject
                        place.relationForKey("toasts").addObject(self.myToast!)
                        place.saveEventually(nil)
                    }
                })
                
                //Adding inverse relationship - Hashtags
                for h:PFObject in self.selectedHashtags!{
                    h.relationForKey("toasts").addObject(self.myToast!)
                    h.saveEventually(nil)
                }
                
            }else{
                NSLog("%@ toasts error", error.description)
            }
        })
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
