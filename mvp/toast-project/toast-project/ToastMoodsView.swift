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
    var moods:[PFObject] = []
    var selectedMoods:[PFObject] = []
    let selectedColor = UIColor(red:0.113, green:0.702, blue:1, alpha:1)
    
    func restartMoods(){
        selectedMoods = []
        myDelegate?.toastCarouselViewMoodsSelected(selectedMoods)
        moodsCollectionView.reloadData()
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("moodCell", forIndexPath: indexPath) as! UICollectionViewCell
        configureMoodText(cell: cell, item: moods[indexPath.row])
        
        return cell
    }
    
    func configureMoodText(#cell:UICollectionViewCell,item:PFObject){
        let moodLabel = cell.viewWithTag(101) as! UILabel
        moodLabel.text = getCapitalString(item["name"] as! String!)
        
        var newAligment:NSTextAlignment
        switch(find(moods,item)!){
        case 0...3 :
            newAligment = .Left
        case 4...7 :
            newAligment = .Center
        case 8...11 :
            newAligment = .Right
        default :
            newAligment = .Left
        }
        moodLabel.textAlignment = newAligment
        
        if let selectedIndex = find(selectedMoods,item) {
            moodLabel.textColor = selectedColor
        }else{
            moodLabel.textColor = UIColor.whiteColor()
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let selectedLabel = collectionView.cellForItemAtIndexPath(indexPath)?.viewWithTag(101) as! UILabel
        
        if let selectedIndex = find(selectedMoods,moods[indexPath.row]) {
            selectedMoods.removeAtIndex(selectedIndex)
            selectedLabel.textColor = UIColor.whiteColor()
        }else{
            selectedMoods.append(moods[indexPath.row])
            selectedLabel.textColor = selectedColor
        }
        
        myDelegate?.toastCarouselViewMoodsSelected(selectedMoods)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(CGRectGetWidth(moodsCollectionView.bounds)/3, 44)
    }
    
    func getCapitalString(original:String) -> String{
        return prefix(original, 1).capitalizedString + suffix(original, count(original) - 1)
    }
}
