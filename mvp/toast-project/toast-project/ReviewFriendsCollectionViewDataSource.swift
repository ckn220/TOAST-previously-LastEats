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
    var favoriteFriends:[PFObject] = []
    
    override init(items: NSArray, cellIdentifier: String, configureBlock: CollectionViewCellConfigureBlock) {
        super.init(items: items, cellIdentifier: cellIdentifier, configureBlock: configureBlock)
        
        //Get Favorite Friends
        let favoritesRelation = PFUser.currentUser().relationForKey("favoriteFriends")
        favoritesRelation.query().findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.favoriteFriends = result as [PFObject]
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(items.count,3)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.itemIdentifier!, forIndexPath: indexPath) as ReviewFriendCell
        let item: AnyObject = self.itemAtIndexPath(indexPath)
        
        if (self.configureCellBlock != nil) {
            self.configureCellBlock!(cell: cell, item: item)
        }
        
        if indexPath.row != currentSelectedToast{
            deselectFriend(cell)
        }else{
            selectFriend(cell)
        }
        
        let favoriteButton = cell.favoriteButton
        favoriteButton.tag = indexPath.row
        if contains(favoriteFriends, item as PFObject){
            favoriteButton.selected = true
        }else{
            favoriteButton.selected = false
        }
        favoriteButton.addTarget(self, action: "favoriteButtonPressed:", forControlEvents: .TouchUpInside)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        previousSelectedToast = currentSelectedToast
        currentSelectedToast = indexPath.row
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as ReviewFriendCell
        
            UIView.animateWithDuration(0.4, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .CurveEaseInOut, animations: { () -> Void in
                if self.currentSelectedToast != self.previousSelectedToast {
                
                let lastcell = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: self.previousSelectedToast, inSection: 0)) as ReviewFriendCell!
                self.deselectFriend(lastcell)
                }
                self.selectFriend(cell)
                }, completion: nil)
        
        let toastSelected = self.items[indexPath.row] as PFObject
        let review = (toastSelected["review"] as String)
        fillReview(review)
    }

    func selectFriend(cell:ReviewFriendCell){
        cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        cell.layer.opacity = 1
        cell.friendNameLabel.alpha = 1
        cell.favoriteButton.alpha = 1
    }
    
    func deselectFriend(cell:ReviewFriendCell){
        cell.layer.transform = CATransform3DMakeScale(0.65, 0.65, 1)
        cell.layer.opacity = 0.5
        cell.friendNameLabel.alpha = 0
        cell.favoriteButton.selected = false
        cell.favoriteButton.alpha = 0
    }
 
    func fillReview(review: String){
        self.myDelegate?.reviewFriendDidSelectReview(review: review)
    }
    
    @objc func favoriteButtonPressed(sender:UIButton){
        let toast = items[sender.tag] as PFObject
        let favoritesRelation = PFUser.currentUser().relationForKey("favorites")
        
        toast["user"].fetchIfNeededInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                let friend = result
                if !sender.selected {
                    sender.selected = true
                    favoritesRelation.addObject(friend)
                }else{
                    sender.selected = false
                    favoritesRelation.removeObject(friend)
                }
                PFUser.currentUser().saveEventually(nil)
            }else{
                NSLog("%@", error.description)
            }
        }
    }
}
