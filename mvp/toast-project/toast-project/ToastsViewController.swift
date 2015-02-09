//
//  ToastsViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire

class ToastsViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    var myMood:PFObject?
    var myPlaces:[PFObject]?
    
    @IBOutlet weak var toastsCollectionView: UICollectionView!
    @IBOutlet weak var moodTitleLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        myPlaces = []
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        moodTitleLabel.text = (myMood!["name"] as? String)?.uppercaseString
        toastsCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        let toastsQuery = PFQuery(className: "Toast")
        toastsQuery.whereKey("moods", equalTo: myMood)
        
        let placesQuery = PFQuery(className: "Place")
        placesQuery.whereKey("toasts", matchesQuery: toastsQuery)
        placesQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                NSLog("Places: %d", result.count)
                self.myPlaces = result as? [PFObject]
                self.toastsCollectionView.reloadData()
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    //MARK: CollectionView datasource methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return myPlaces!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("placeCell", forIndexPath: indexPath) as PlaceCell
            let imPlace = myPlaces![indexPath.row]
            cell.placeNameLabel.text = (imPlace["name"] as? String)?.uppercaseString
            let placePictureString = imPlace["picture"] as String
            Alamofire.request(.GET, placePictureString).response({ (request, response, data, error) -> Void in
                if error == nil{
                    cell.placePictureView.image = UIImage(data: data as NSData)
                }else{
                    NSLog("%@", error!.description)
                }
            })
            
            return cell
        
    }
    
    //MARK: CollectionView delegate methods
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSizeMake(260, CGRectGetHeight(collectionView.bounds))
        
    }
    
    //MARK: Action methods
    
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}
