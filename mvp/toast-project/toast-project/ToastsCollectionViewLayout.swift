//
//  ToastsCollectionViewLayout.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class ToastsCollectionViewLayout: UICollectionViewFlowLayout {
   
    override init() {
        super.init()
        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    
    func setup(){
        let deviceWidth = CGRectGetWidth(UIScreen.mainScreen().bounds)
        
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        scrollDirection = .Horizontal
        let itemWidth = 260*deviceWidth/320
        sectionInset = UIEdgeInsetsMake(0,(deviceWidth/2) - (itemWidth/2), 0,(deviceWidth/2) - (itemWidth/2));
    }
    
    func halfWidth() -> CGFloat{
        return (CGRectGetWidth(collectionView!.bounds) / 2)
    }
    
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        var offsetAdjustment = 10000.0 as CGFloat
        let horizontalCenter = proposedContentOffset.x + halfWidth()
        let targetRect = CGRectMake(proposedContentOffset.x, 0, CGRectGetWidth(collectionView!.bounds), CGRectGetHeight(collectionView!.bounds))
        let array = super.layoutAttributesForElementsInRect(targetRect)
        
        for layoutAt in array as! [UICollectionViewLayoutAttributes]{
            
            let myCenterX = layoutAt.center.x
            let diff = Float(abs(myCenterX - horizontalCenter))
            let absOffset = Float(abs(offsetAdjustment))
            
            if diff < absOffset {
                offsetAdjustment = myCenterX - horizontalCenter
            }
        }
        
        return CGPointMake(proposedContentOffset.x + offsetAdjustment, proposedContentOffset.y)
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        let attributes = super.layoutAttributesForElementsInRect(rect) as! [UICollectionViewLayoutAttributes]
        let visibleCenter = collectionView!.bounds.size.width/2 + collectionView!.contentOffset.x
        
        for at in attributes{
            var newTransform = at.transform3D
            let distanceToCenter:Double = abs(Double(CGRectGetMidX(at.frame)) - Double(visibleCenter))
            let newScale = CGFloat(1 - (distanceToCenter/2000))
            newTransform = CATransform3DMakeScale(newScale, newScale, 1)
            at.transform3D = newTransform
            at.alpha = CGFloat(Double(1.0) - (distanceToCenter/500.0))
        }
        
        return attributes
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}
