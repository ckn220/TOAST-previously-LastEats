//
//  ProfileToastCell.swift
//  toast-project
//
//  Created by Diego Cruz on 3/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire

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
                NSLog("%@",error.description)
            }
        }
    }
    
    private func configureImage(place:PFObject){
        let imageURL = (place["photos"] as! NSArray)[0] as! String
        Alamofire.request(.GET, imageURL).response({ (request, response, data, error) -> Void in
            if error == nil{
                self.placeImageView.myImage = UIImage(data: data as! NSData)!
            }else{
                NSLog("%@", error!.description)
            }
        })
    }
    
    private func configureName(place:PFObject){
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
}
