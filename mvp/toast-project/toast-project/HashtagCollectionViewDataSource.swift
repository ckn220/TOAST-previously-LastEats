//
//  HashtagCollectionViewDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 2/9/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class HashtagCollectionViewDataSource: CollectionViewDataSource,UICollectionViewDelegateFlowLayout {
   
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if collectionView.tag == 501{
            let myItem = self.items[indexPath.row] as PFObject
            let myString = "#" + (myItem["name"] as String)
            return myString.sizeWithAttributes([NSFontAttributeName:UIFont.systemFontOfSize(15.0)])
        }else{
            return CGSizeZero
        }
        
    }
    
}
