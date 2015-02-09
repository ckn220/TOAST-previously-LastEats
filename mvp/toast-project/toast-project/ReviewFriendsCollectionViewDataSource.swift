//
//  ReviewFriendsCollectionViewDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 2/9/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol ReviewFriendsDelegate{
    func reviewFriendDidSelectReview(#review: String);
}

class ReviewFriendsCollectionViewDataSource: CollectionViewDataSource,UICollectionViewDelegateFlowLayout {
   
    var currentSelectedToast = 0
    var previousSelectedToast = 0
    var myDelegate: ReviewFriendsDelegate?
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(items.count,3)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.itemIdentifier!, forIndexPath: indexPath) as UICollectionViewCell
        let item: AnyObject = self.itemAtIndexPath(indexPath)
        
        if (self.configureCellBlock != nil) {
            self.configureCellBlock!(cell: cell, item: item)
        }
        
        if indexPath.row != currentSelectedToast{
            cell.layer.transform = CATransform3DMakeScale(0.65, 0.65, 1)
            cell.layer.opacity = 0.5
        }else{
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
            cell.layer.opacity = 1
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        previousSelectedToast = currentSelectedToast
        currentSelectedToast = indexPath.row
        
        if currentSelectedToast != previousSelectedToast {
            UIView.animateWithDuration(0.4, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .CurveEaseInOut, animations: { () -> Void in
                let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: self.previousSelectedToast, inSection: 0)) as UICollectionViewCell!
                cell.layer.transform = CATransform3DMakeScale(0.65, 0.65, 1)
                cell.layer.opacity = 0.5
                
                }, completion: nil)
            
        }
        
        UIView.animateWithDuration(0.4, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .CurveEaseInOut, animations: { () -> Void in
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as UICollectionViewCell!
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
            cell.layer.opacity = 1
            
        }, completion: nil)
        
        let toastSelected = self.items[indexPath.row] as PFObject
        var review = (toastSelected["review"] as String)
        
        if review != "" {
            let toastUser = toastSelected["user"] as PFObject
            review = review + "   - " + (toastUser["name"] as String)
        }
            self.myDelegate?.reviewFriendDidSelectReview(review: review)
        
    }
    
    func fillReview(review: String){
        self.myDelegate?.reviewFriendDidSelectReview(review: review)
    }
    
}
