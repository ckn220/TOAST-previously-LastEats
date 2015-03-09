//
//  ToastHashtagsView.swift
//  toast-project
//
//  Created by Diego Cruz on 2/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ToastHashtagsView: ToastCarouselView {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var hashtagsCollectionView: UICollectionView!
    
    var hashtags:[PFObject] = []
    var selectedHashtags:[PFObject] = []
    let selectedColor = UIColor(red:0.113, green:0.702, blue:1, alpha:1)
    
    @IBAction func nextPressed(sender: UIButton) {
        myDelegate?.toastCarouselViewDelegate(indexSelected: index!,value: selectedHashtags)
    }
    
    func insertHashtags(newHashtags:[PFObject]){
        hashtags=newHashtags
        hashtagsCollectionView.registerNib(UINib(nibName: "ToastHashtagCell", bundle: nil), forCellWithReuseIdentifier: "hashtagCell")
        hashtagsCollectionView.reloadData()
    }
    
    //MARK: - CollectionView datasource methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashtags.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("hashtagCell", forIndexPath: indexPath) as UICollectionViewCell
        (cell.viewWithTag(101) as UILabel).text = "#" + (hashtags[indexPath.row]["name"] as String!)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let selectedLabel = collectionView.cellForItemAtIndexPath(indexPath)?.viewWithTag(101) as UILabel
        
        if let selectedIndex = find(selectedHashtags,hashtags[indexPath.row]) {
            selectedHashtags.removeAtIndex(selectedIndex)
            selectedLabel.textColor = UIColor.whiteColor()
        }else{
            selectedHashtags.append(hashtags[indexPath.row])
            selectedLabel.textColor = selectedColor
        }
        
        toogleNextButton()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(CGRectGetWidth(hashtagsCollectionView.bounds)/2, 44)
    }
    
    func toogleNextButton(){
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.nextButton.alpha = CGFloat(self.selectedHashtags.count)
        })
    }
}
