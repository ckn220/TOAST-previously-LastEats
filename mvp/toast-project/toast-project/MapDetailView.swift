//
//  MapDetailView.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/17/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class MapDetailView: MyControl {
    
    //MARK: - Properties
    //MARK: IBOutlets
    @IBOutlet weak var userProfileImageView:UserProfileImageView!
    @IBOutlet weak var userNameLabel:UILabel!
    @IBOutlet weak var topToastView:UIView!
    @IBOutlet weak var reviewLabel:UILabel!
    
    //MARK: Variables
    var toast:PFObject?{
        didSet{
            toggleVisible(toast != nil)
            configure()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        toggleVisible(false,animated:false)
    }
    
    //MARK: - Visible methods
    private func toggleVisible(visible:Bool,animated:Bool=true){
        var duration = 0.14
        if !animated{
            duration = 0
        }
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
            if visible{
                self.layer.transform = CATransform3DMakeTranslation(0, 0, 0)
            }else{
                self.layer.transform = CATransform3DMakeTranslation(0, self.layer.bounds.height, 0)
            }
        }, completion: nil)
        
    }
    
    //MARK: - Configure methods
    private func configure(){
        if toast != nil{
            configureImage()
            configureName()
            configureTopToast()
            configureReview()
        }
    }
    
    private func configureImage(){
        userProfileImageView.myImageView.image = nil
        if let user = toast!["user"] as? PFUser{
            userProfileImageView.setImage(user: user)
        }
    }
    
    private func configureName(){
        if let user = toast!["user"] as? PFUser{
            userNameLabel.text = user["name"] as? String
        }else{
            userNameLabel.text = ""
        }
    }
    
    private func configureTopToast(){
        func insertTopToast(){
            if let parentView = userNameLabel.superview{
                topToastView.translatesAutoresizingMaskIntoConstraints = false
                parentView.addSubview(topToastView)
                let hConstraint = NSLayoutConstraint(item: userNameLabel, attribute: .Leading, relatedBy: .Equal, toItem: topToastView, attribute: .Leading, multiplier: 1, constant: 0)
                let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[name]-2-[topToast]|", options: [], metrics: nil, views: ["name":userNameLabel,"topToast":topToastView])
                parentView.addConstraint(hConstraint)
                parentView.addConstraints(vConstraints)
                parentView.layoutIfNeeded()
            }
        }
        
        func removeTopToast(){
            topToastView.removeFromSuperview()
        }
        //
        if let isTopToast = toast!["isTopToast"] as? Bool where isTopToast{
            if topToastView.superview == nil{
                insertTopToast()
            }
        }else{
            removeTopToast()
        }
    }
    
    private func configureReview(){
        if let review = toast!["review"] as? String{
            reviewLabel.text = "\"\(review)\""
        }else{
            reviewLabel.text = ""
        }
    }
    
    //MARK: - Highlight methods
    override func applyHighlight() {
        alpha = 0.8
    }
}