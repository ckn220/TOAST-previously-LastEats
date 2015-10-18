//
//  ContributeTransitioning.swift
//  toast-project
//
//  Created by Diego Cruz on 4/2/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class PostContributeTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    let myDuration = 0.35
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval{
        return myDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning)  {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)! as! ContributeViewController
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)! as! PostContributeViewController
        let toV = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let finalFrame = transitionContext.finalFrameForViewController(toVC)
        let contextView = transitionContext.containerView()
        
        //Dissapearing fromVC elements
        let fromNavBar = fromVC.myNavBar
        let fromCarousel = fromVC.myCarousel
        let fromReviewView = fromVC.reviewView
        UIView.animateKeyframesWithDuration(myDuration, delay: 0, options: .CalculationModeLinear, animations: { () -> Void in
            
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 1, animations: { () -> Void in
                fromCarousel.layer.transform = CATransform3DMakeScale(0.001, 0.001, 1)
                fromReviewView.layer.transform = CATransform3DMakeScale(0.001, 0.001, 1)
            })
            
            UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: { () -> Void in
                fromNavBar.alpha = 0
                fromCarousel.alpha = 0
            })
            
        }) { (completed) -> Void in
            //Appearing toV
            toV.frame = finalFrame
            contextView!.addSubview(toV)
            transitionContext.completeTransition(true)
        }
    }
}
