//
//  PlaceDetailMapView.swift
//  toast-project
//
//  Created by Diego Cruz on 7/16/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ToastDetailMapView: UIView {

    @IBOutlet weak var placeName:UILabel!
    @IBOutlet weak var reviewLabel:UILabel!
    @IBOutlet weak var topToastView:UIView!
    var gradient = CAGradientLayer()
    var myUser:PFUser!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutGradientLayer()
    }
    
    private func layoutGradientLayer(){
        gradient.removeFromSuperlayer()
        CATransaction.setAnimationDuration(0)
        gradient.frame = self.bounds
        gradient.colors = [UIColor.clearColor().CGColor,UIColor(white: 0, alpha: 0.8).CGColor]
        gradient.locations = [0.2,0.8]
        layer.insertSublayer(gradient, atIndex: 0)
    }
    
    func configure(toast:PFObject){
        configurePlace(toast)
        configureReview(toast)
        configureTopToast(toast)
    }
    
    private func configurePlace(toast:PFObject){
        let place = toast["place"] as! PFObject
        placeName.text = place["name"] as? String
    }
    
    private func configureReview(toast:PFObject){
        reviewLabel.text = toast["review"] as? String
    }
    
    private func configureTopToast(toast:PFObject){
        if isTopToast(toast){
            topToastView.alpha = 1
        }else{
            topToastView.alpha = 0
        }
    }
    
    private func isTopToast(toast:PFObject) -> Bool{
        if let topToast = myUser["topToast"] as? PFObject{
            return topToast.objectId! == toast.objectId!
        }else{
            return false
        }
    }
}
