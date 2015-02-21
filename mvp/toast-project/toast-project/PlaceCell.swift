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
    
    var hashtagDataSource: HashtagCollectionViewDataSource?
    var reviewFriendDataSource: ReviewFriendsCollectionViewDataSource?
    
    func reviewFriendDidSelectReview(#review: String) {
        
        if review != "" {
            reviewTextView.text = review
            reviewTextView.textColor = UIColor.blackColor()
        }else{
            reviewTextView.text = "No review"
            reviewTextView.textColor = UIColor.lightGrayColor()
        }
        
    }
}
