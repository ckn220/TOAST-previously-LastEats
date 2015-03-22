//
//  ReviewCell.swift
//  toast-project
//
//  Created by Diego Cruz on 3/18/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ReviewCell: UITableViewCell {

    @IBOutlet weak var reviewerPictureButton: ReviewerButton!
    @IBOutlet weak var reviewerNameLabel: UILabel!
    @IBOutlet weak var reviewTextLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    func configure(#isLastItem:Bool){
        //configureReviewerPicture()
        configureSeparatorLine(isLastItem: isLastItem)
    }
    
    func setUserInfo(user:PFUser){
        (user["profilePicture"] as PFFile).getDataInBackgroundWithBlock { (data, error) -> Void in
            if error == nil{
                self.reviewerPictureButton.myImage = UIImage(data: data)
            }else{
                NSLog("%@", error.description)
            }
        }
        
        reviewerNameLabel.text = user["name"] as? String
        configureReviewerPicture()
    }
    
    func setReview(review:String){
        reviewTextLabel.text = review
    }
    
    func configureReviewerPicture(){
        let layer = reviewerPictureButton.layer
        layer.cornerRadius = 28
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 1, alpha: 0.7).CGColor
        layer.shouldRasterize = true
    }
    
    func configureSeparatorLine(#isLastItem:Bool){
        if isLastItem {
            separatorView.alpha = 0
        }else{
            separatorView.alpha = 0.4
        }
    }
}
