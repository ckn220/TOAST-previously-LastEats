//
//  ReviewCell.swift
//  toast-project
//
//  Created by Diego Cruz on 3/18/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol ReviewCellDelegate{
    func reviewCellReviewerPressed(index:Int)
}

class ReviewCell: UITableViewCell {

    @IBOutlet weak var reviewerPictureButton: ReviewerButton!
    @IBOutlet weak var reviewerNameLabel: UILabel!
    @IBOutlet weak var reviewTextLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    var myDelegate:ReviewCellDelegate?
    var reviewIndex:Int!
    
    func configure(item:PFObject,index:Int,lastIndex:Int){
        configure(index)
        configureUser(item: item)
        configureReview(item: item,isSingle: lastIndex == 0)
        configureSeparatorLine(isLastItem: lastIndex == index)
    }
    
    //MARK: - Configure methods
    private func configure(index:Int){
        reviewIndex = index
    }
    
    //MARK: - Configure User methods
    private func configureUser(#item:PFObject){
        if let user = item["user"] as? PFUser{
            setUserInfo(user)
        }
    }
    
    private func setUserInfo(user:PFUser){
        (user["profilePicture"] as! PFFile).getDataInBackgroundWithBlock { (data, error) -> Void in
            if error == nil{
                self.reviewerPictureButton.myImage = UIImage(data: data)
            }else{
                NSLog("%@", error.description)
            }
        }
        
        reviewerNameLabel.text = user["name"] as? String
        configureReviewerPicture()
    }
    
    private func configureReviewerPicture(){
        let layer = reviewerPictureButton.layer
        layer.cornerRadius = 28
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 1, alpha: 0.7).CGColor
        layer.shouldRasterize = true
    }
    
    //MARK: - Configure Review methods
    private func configureReview(#item:PFObject,isSingle:Bool){
        if let review = item["review"] as? String{
            if isSingle {
                setReview("\""+review+"\"")
            }else{
                setReview(review)
            }
            
        }
    }
    
    private func setReview(review:String){
        reviewTextLabel.text = review
        self.layoutIfNeeded()
    }
    
    //MARK: - Configure Separator line methods
    private func configureSeparatorLine(#isLastItem:Bool){
        if isLastItem {
            separatorView.alpha = 0
        }else{
            separatorView.alpha = 0.4
        }
    }
    
    //MARK: - Action methods
    @IBAction func reviewerPressed(sender: ReviewerButton) {
        myDelegate?.reviewCellReviewerPressed(reviewIndex)
    }
}
