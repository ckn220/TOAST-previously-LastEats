//
//  ToastCollectionViewDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

typealias CollectionViewCellConfigureBlock = (cell:UICollectionViewCell, item:AnyObject?) -> ()

class CollectionViewDataSource: NSObject, UICollectionViewDataSource {
    
    var items:NSArray = []
    var itemIdentifier:String?
    var configureCellBlock:CollectionViewCellConfigureBlock?
    
    init(items: NSArray, cellIdentifier: String, configureBlock: CollectionViewCellConfigureBlock) {
        self.items = items
        self.itemIdentifier = cellIdentifier
        self.configureCellBlock = configureBlock
        super.init()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.itemIdentifier!, forIndexPath: indexPath) as UICollectionViewCell
        let item: AnyObject = self.itemAtIndexPath(indexPath)
        
        if (self.configureCellBlock != nil) {
            self.configureCellBlock!(cell: cell, item: item)
        }
        
        return cell
    }
    
    func itemAtIndexPath(indexPath: NSIndexPath) -> AnyObject {
        return self.items[indexPath.row]
    }
    
}
