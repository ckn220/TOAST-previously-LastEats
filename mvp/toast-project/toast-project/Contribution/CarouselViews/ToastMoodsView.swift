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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("moodCell", forIndexPath: indexPath) 
        configureMoodText(cell: cell, item: moods[indexPath.row])
        
        return cell
    }
    
    func configureMoodText(cell cell:UICollectionViewCell,item:PFObject){
        let moodLabel = cell.viewWithTag(101) as! UILabel
        moodLabel.text = getCapitalString(item["name"] as! String!)
        
        var newAligment:NSTextAlignment
        switch((moods).indexOf(item)!){
        case 0...4 :
            newAligment = .Left
        case 5...9 :
            newAligment = .Center
        case 10...14 :
            newAligment = .Right
        default :
            newAligment = .Left
        }
        moodLabel.textAlignment = newAligment
        
        let isSelected = (selectedMoods).indexOf(item) != nil
        applySelectedStyle(moodLabel, selected: isSelected)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let selectedLabel = collectionView.cellForItemAtIndexPath(indexPath)?.viewWithTag(101) as! UILabel
        
        if let selectedIndex = selectedMoods.indexOf(moods[indexPath.row]) {
            selectedMoods.removeAtIndex(selectedIndex)
            applySelectedStyle(selectedLabel, selected: false)
        }else{
            selectedMoods.append(moods[indexPath.row])
            applySelectedStyle(selectedLabel, selected: true)
        }
        
        myDelegate?.toastCarouselViewMoodsSelected(selectedMoods)
    }
    
    private func applySelectedStyle(label:UILabel,selected:Bool){
        if selected{
            label.textColor = selectedColor
            label.font = UIFont(name: "Avenir-Roman", size: 16)
        }else{
            label.textColor = UIColor.whiteColor()
            label.font = UIFont(name: "Avenir-Roman", size: 16)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(cellWidth(row: indexPath.row), 44)
    }
    
    private func cellWidth(row row:Int)-> CGFloat{
        var width:CGFloat
        switch(row){
        case 0...4 :
            width = 94
        case 5...9 :
            width = moodsCollectionView.bounds.width - 94 - 54
        case 10...14 :
            width = 54
        default :
            width = 0
        }
        return width
    }
    
    func getCapitalString(original:String) -> String{
        return String(original.characters.prefix(1)).capitalizedString + String(original.characters.suffix(original.characters.count - 1))
    }
}
