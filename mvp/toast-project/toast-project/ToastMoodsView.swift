//
//  ToastMoodsView.swift
//  toast-project
//
//  Created by Diego Cruz on 2/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ToastMoodsView: ToastCarouselView,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var moodsCollectionView: UICollectionView!
    @IBOutlet weak var nextButton: UIButton!
    var moods:[PFObject] = []
    var selectedMoods:[PFObject] = []
    let selectedColor = UIColor(red:0.113, green:0.702, blue:1, alpha:1)
    
    @IBAction func nextPressed(sender: UIButton) {
        myDelegate?.toastCarouselViewDelegate(indexSelected: index!,value: selectedMoods)
    }
    
    func insertMoods(newMoods:[PFObject]){
        moods=newMoods
        moodsCollectionView.registerNib(UINib(nibName: "ToastMoodCell", bundle: nil), forCellWithReuseIdentifier: "moodCell")
        moodsCollectionView.reloadData()
    }
    
    //MARK: - CollectionView datasource methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return moods.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("moodCell", forIndexPath: indexPath) as UICollectionViewCell
        (cell.viewWithTag(101) as UILabel).text = getCapitalString(moods[indexPath.row]["name"] as String!)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let selectedLabel = collectionView.cellForItemAtIndexPath(indexPath)?.viewWithTag(101) as UILabel
        
        if let selectedIndex = find(selectedMoods,moods[indexPath.row]) {
            selectedMoods.removeAtIndex(selectedIndex)
            selectedLabel.textColor = UIColor.whiteColor()
        }else{
            selectedMoods.append(moods[indexPath.row])
            selectedLabel.textColor = selectedColor
        }
        
        toogleNextButton()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(CGRectGetWidth(moodsCollectionView.bounds)/3, 44)
    }
    
    func toogleNextButton(){

        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.nextButton.alpha = CGFloat(self.selectedMoods.count)
        })
    }
    
    func getCapitalString(original:String) -> String{
        return prefix(original, 1).capitalizedString + suffix(original, countElements(original) - 1)
    }
}
