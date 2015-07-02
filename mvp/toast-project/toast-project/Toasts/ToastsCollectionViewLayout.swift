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
        
        minimumLineSpacing = -2
        minimumInteritemSpacing = 0
        scrollDirection = .Horizontal
        let itemWidth = 272*deviceWidth/320
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
    
    /*
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let collectionViewSize = self.collectionView!.bounds.size;
        let proposedContentOffsetCenterX = proposedContentOffset.x + self.collectionView!.bounds.size.width * 0.5;
        
        var proposedRect = self.collectionView!.bounds;
        
        // Comment out if you want the collectionview simply stop at the center of an item while scrolling freely
        //proposedRect = CGRectMake(proposedContentOffset.x, 0.0, collectionViewSize.width, collectionViewSize.height);
        
        var candidateAttributes:UICollectionViewLayoutAttributes?;
        for attributes in layoutAttributesForElementsInRect(proposedRect)! {
            
            // == First time in the loop == //
            if candidateAttributes == nil{
                candidateAttributes = attributes as? UICollectionViewLayoutAttributes;
                continue;
            }
            
            if fabs(attributes.center.x.distanceTo(proposedContentOffsetCenterX)) < fabs(candidateAttributes!.center.x.distanceTo(proposedContentOffsetCenterX)){
                candidateAttributes = attributes as? UICollectionViewLayoutAttributes;
            }
        }
        
        return CGPointMake(candidateAttributes!.center.x - self.collectionView!.bounds.size.width * 0.5, proposedContentOffset.y);
    }*/
    
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
