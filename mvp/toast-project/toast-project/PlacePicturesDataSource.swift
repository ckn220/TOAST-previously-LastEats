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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("pictureCell", forIndexPath: indexPath) as! UICollectionViewCell
        let pictureView = cell.viewWithTag(101) as! BackgroundImageView
        let loadingView = cell.viewWithTag(501) as! UIActivityIndicatorView
        resetCell(pictureView: pictureView, loadingView: loadingView)
        
        myCache.fetch(URL: NSURL(string: pictureURLS[indexPath.row])!, failure: { (error) -> () in
            NSLog("cellForItems error: %@",error!.description)
            }, success: {(image) -> () in
                pictureView.myImage = image
                loadingView.alpha = 0
        })
        
        return cell
    }
    
    private func resetCell(#pictureView:BackgroundImageView,loadingView:UIActivityIndicatorView){
        pictureView.myImage = nil
        loadingView.alpha = 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let dim = UIScreen.mainScreen().bounds
        return CGSizeMake(dim.width, dim.height)
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
