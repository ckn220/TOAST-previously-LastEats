//
//  HashtagCollectionViewDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 2/9/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol HashtagDelegate {
    func hashtagSelected(hashtag: PFObject)
}

class HashtagCollectionViewDataSource: NSObject,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
   
    var myDelegate:HashtagDelegate?
    var hashtags:[PFObject] = []
    
    init(hashtags:[PFObject],myDelegate:HashtagDelegate?){
        super.init()
        self.hashtags = hashtags
        self.myDelegate = myDelegate
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashtags.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("hashtagCell", forIndexPath: indexPath) as HashtagCell
        cell.configure(item: hashtags[indexPath.row], index: indexPath.row)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let totalWidth = CGRectGetWidth(collectionView.bounds)
        return CGSizeMake(totalWidth/2, 18)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let selectedItem = self.hashtags[indexPath.row] as PFObject
        myDelegate?.hashtagSelected(selectedItem)
    }
    
}
