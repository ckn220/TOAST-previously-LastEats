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

protocol ProfileToastCellDelegate{
    func profileToastCellGotPlace(place:PFObject?,atIndex index:Int)
    func getPlace(index:Int) -> PFObject?
}

class ProfileToastCell: UITableViewCell {

    @IBOutlet weak var placeImageView: BackgroundImageView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var placeReviewLabel: UILabel!
    @IBOutlet weak var topToastView: UIView!
    
    var myIndex:Int!
    var myPlace:PFObject?
    let imageQueue = NSOperationQueue()
    var myDelegate:ProfileToastCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(index:Int,toast:PFObject,myDelegate:ProfileToastCellDelegate){
        self.myDelegate = myDelegate
        self.myIndex = index
        toggleAlpha(0, duration: 0)
        setPlace(toast["place"] as? PFObject)
        configureReview(toast)
        configureTopToastSignal(toast)
    }
    
    private func setPlace(place:PFObject?){
        myDelegate?.profileToastCellGotPlace(place,atIndex:myIndex)
        if place != nil{
            myPlace = place
            self.configureImage()
            self.configureName()
        }else{
            self.placeImageView.myImageView.image = nil
            self.placeNameLabel.text = ""
            self.toggleAlpha(1)
        }
    }
    
    private func configureImage(){
        if let photosArray = myPlace!["photos"] as? NSArray{
            if photosArray.count > 0{
                let imageURL = photosArray[0] as! String
                placeImageView.setImage(URL: imageURL) { () -> Void in
                    self.toggleAlpha(1)
                }
            }else{
                self.toggleAlpha(1)
            }
        }else{
            self.toggleAlpha(1)
        }
        
    }
    
    private func configureName(){
        //insertShadow(placeNameLabel)
        placeNameLabel.text = myPlace!["name"] as! String!
    }
    
    private func toggleAlpha(alpha:CGFloat,duration:NSTimeInterval=0){
        UIView.animateWithDuration(duration, animations: { () -> Void in
            self.placeImageView?.alpha = alpha
        })
    }
    
    private func configureReview(toast:PFObject){
        placeReviewLabel.text = toast["review"] as! String!
    }
    
    private func configureTopToastSignal(toast:PFObject){
        
        if let isTopToast = toast["isTopToast"] as? Bool where isTopToast{
            topToastView.alpha = 1
        }else{
            topToastView.alpha = 0
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
