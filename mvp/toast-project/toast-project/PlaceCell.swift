//
//  PlaceCell.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class PlaceCell: UICollectionViewCell,ReviewFriendsDelegate {
    @IBOutlet weak var placePictureView: UIImageView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var hashtagsCollectionView: UICollectionView!
    
    @IBOutlet weak var hashtagsCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var myBackgroundView: BackgroundImageView!
    @IBOutlet weak var reviewTextView: UITextView!
    @IBOutlet weak var reviewFriendCollectionView: UICollectionView!
    
    @IBOutlet weak var categoryNameLabel: UILabel!
    @IBOutlet weak var walkLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    var hashtagDataSource: HashtagCollectionViewDataSource?
    var reviewFriendDataSource: ReviewFriendsCollectionViewDataSource?
    
    func reviewFriendDidSelectReview(#review: String) {
        
        if review != "" {
            reviewTextView.text = review
            reviewTextView.alpha = 1
            reviewTextView.textColor = UIColor.whiteColor()
        }else{
            reviewTextView.text = "No review"
            reviewTextView.alpha = 0.5
        }
        reviewTextView.font = UIFont(name: "Avenir-Roman", size: 16.0)
        reviewTextView.textColor = UIColor.whiteColor()
    }
}
