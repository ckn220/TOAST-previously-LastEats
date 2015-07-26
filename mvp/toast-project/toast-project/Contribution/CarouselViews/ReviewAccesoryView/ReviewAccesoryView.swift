//
//  ReviewAccesoryView.swift
//  toast-project
//
//  Created by Diego Cruz on 3/29/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol ReviewAccesoryViewDelegate{
    func reviewAccesoryViewDidSelect(hashtag:PFObject)
}

class ReviewAccesoryView: UIView,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var hashtagCollectionView: UICollectionView!
    var myHashtags = [PFObject]()
    var myDelegate: ReviewAccesoryViewDelegate?
    var moods:[PFObject]!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        configure()
    }
    
    func configure(){
        
        hashtagCollectionView.registerNib(UINib(nibName: "ToastHashtagCell", bundle: nil), forCellWithReuseIdentifier: "hashtagCell")
        //configureCollectionView()
        configureHashtags()
    }
    
    private func configureCollectionView(){
        let layout = (hashtagCollectionView.collectionViewLayout as! UICollectionViewFlowLayout)
        layout.estimatedItemSize = CGSize(width: 60,height: 30)
    }
    
    private func configureHashtags(){
        
        let objectsId = objectsIdArray(moods: moods)
        PFCloud.callFunctionInBackground(/*"moodsTopHashtags"*/"defaultHashtags", withParameters: ["moods":objectsId,"limit":45]) { (results, error) -> Void in
            if error == nil{
                self.myHashtags = results as! [PFObject]
                NSLog("Hashtags count: %d", self.myHashtags.count)
                self.hashtagCollectionView.reloadData()
            }else{
                NSLog("configureHashtags error: %@",error!.description)
            }
        }
    }
    
    private func objectsIdArray(#moods:[PFObject])->[String]{
        var array=[String]()
        for m in moods{
            array.append(m.objectId!)
        }
        
        return array
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myHashtags.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("hashtagCell", forIndexPath: indexPath) as! UICollectionViewCell
        let item = myHashtags[indexPath.row]
        configureCell(cell, item: item)
        
        return cell
    }
    
    private func configureCell(cell:UICollectionViewCell, item:PFObject){
        let label = cell.viewWithTag(101) as! UILabel
        label.text = "#"+(item["name"] as! String)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 10, 0, 10)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let itemWidth = CGRectGetWidth(collectionView.bounds) * 0.4
        return CGSizeMake(itemWidth, 30)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        myDelegate?.reviewAccesoryViewDidSelect(myHashtags[indexPath.row])
    }
}
