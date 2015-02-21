//
//  PlaceDetailViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/13/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class PlaceDetailViewController: UIViewController {

    @IBOutlet weak var categoryNameLabel: UILabel!
    @IBOutlet weak var placeNameLabel:UILabel!
    var myDetail:PlaceDetailTableViewController?
    var myPlace:PFObject?
    var myPlacePicture:UIImage?
    var placeReviewFriends: [PFObject]?
    var placeHashtags: [PFObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configurePlaceName()
        configureCategoryName()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    //MARK: Place properties methods
    func configurePlaceName(){
        placeNameLabel.text = myPlace!["name"] as? String
    }
    
    func configureCategoryName(){
        (myPlace?["category"] as PFObject).fetchIfNeededInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.categoryNameLabel.text = result["name"] as? String
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    //MARK: Action methods
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
        }
    }
    

}
