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
        
        minimumLineSpacing = 18
        minimumInteritemSpacing = 18
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
        
        for layoutAt in array as [UICollectionViewLayoutAttributes]{
            
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
        let attributes = super.layoutAttributesForElementsInRect(rect) as [UICollectionViewLayoutAttributes]
        let visibleCenter = collectionView!.bounds.size.width/2 + collectionView!.contentOffset.x
        
        for at in attributes{
            var newFrame = at.frame
            let distanceToCenter:Double = abs(Double(CGRectGetMidX(newFrame)) - Double(visibleCenter))
            newFrame.origin.y += CGFloat(distanceToCenter/8)
            at.frame = newFrame
            at.alpha = CGFloat(Double(1.0) - (distanceToCenter/500.0))
        }
        
        return attributes
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}
