//
//  ProfileToastCell.swift
//  toast-project
//
//  Created by Diego Cruz on 3/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

class ProfileToastCell: UITableViewCell {

    @IBOutlet weak var placeImageView: BackgroundImageView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var placeReviewLabel: UILabel!
    @IBOutlet weak var topToastSignal: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(toast:PFObject,topToast:PFObject?){
        placeFromToast(toast, completion: { (place) -> Void in
            self.configureImage(place)
            self.configureName(place)
        })
        configureReview(toast)
        configureTopToastSignal(toast, topToast: topToast)
    }
    
    private func placeFromToast(toast:PFObject,completion:(place:PFObject)->Void){
        let query = PFQuery(className: "Place")
        query.whereKey("toasts", equalTo: toast)
        query.getFirstObjectInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                completion(place:result as PFObject)
            }else{
                NSLog("placeFromToast error: %@",error.description)
            }
        }
    }
    
    private func configureImage(place:PFObject){
        let imageURL = (place["photos"] as! NSArray)[0] as! String
        let cache = Shared.imageCache
        cache.fetch(URL: NSURL(string: imageURL)!, failure: { (error) -> () in
            NSLog("configureImage error: %@",error!.description)
            }, success: {(image) -> () in
                self.placeImageView.myImage = image
        })
    }
    
    private func configureName(place:PFObject){
        //insertShadow(placeNameLabel)
        placeNameLabel.text = place["name"] as! String!
    }
    
    private func configureReview(toast:PFObject){
        placeReviewLabel.text = toast["review"] as! String!
    }
    
    private func configureTopToastSignal(toast:PFObject,topToast:PFObject?){
        
        if let top = topToast {
            if toast.objectId == top.objectId{
                topToastSignal.alpha = 1
            }else{
                topToastSignal.alpha = 0
            }
        }else{
            topToastSignal.alpha = 0
        }
    }
    
    func insertShadow(view:UIView){
        
        let layer = view.layer
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 8.0
        layer.shadowOpacity = 0.9
        layer.shadowPath = UIBezierPath(rect: layer.bounds).CGPath
        layer.shouldRasterize = true
    }
    
    func insertSmallShadow(view:UIView){
        let layer = view.layer
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 4.0
        layer.shadowOpacity = 0.9
        layer.shouldRasterize = true
    }
}
