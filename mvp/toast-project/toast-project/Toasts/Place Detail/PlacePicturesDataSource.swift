//
//  PlacePicturesDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 5/18/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Haneke

protocol PlacePicturesDelegate{
    func placePicturesChangeCurrent(currentIndex:Int)
}

class PlacePicturesDataSource: NSObject, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    var myDelegate:PlacePicturesDelegate?
    var pictureURLS:[String]!
    var myCache = Cache<UIImage>(name: "placePictures")
    
    init(items:[String],delegate:PlacePicturesDelegate){
        super.init()
        pictureURLS = items
        myDelegate = delegate
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pictureURLS.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("pictureCell", forIndexPath: indexPath) 
        let pictureView = cell.viewWithTag(101) as! UIImageView
        let loadingView = cell.viewWithTag(501) as! UIActivityIndicatorView
        resetCell(pictureView: pictureView, loadingView: loadingView)
        pictureView.hnk_setImageFromURL(NSURL(string: pictureURLS[indexPath.row])!, success: { (image) -> () in
            pictureView.image = image
            loadingView.alpha = 0
        })
        
        return cell
    }
    
    private func resetCell(pictureView pictureView:UIImageView,loadingView:UIActivityIndicatorView){
        pictureView.image = nil
        loadingView.alpha = 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let dim = UIScreen.mainScreen().bounds
        return CGSizeMake(dim.width, dim.width)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let index = currentIndex(scrollView.contentOffset.x)
        myDelegate?.placePicturesChangeCurrent(index)
    }
    
    func currentIndex(contentOffsetx:CGFloat) -> Int{
        let dimensions = UIScreen.mainScreen().bounds
        return Int(contentOffsetx/dimensions.width)
    }
}
