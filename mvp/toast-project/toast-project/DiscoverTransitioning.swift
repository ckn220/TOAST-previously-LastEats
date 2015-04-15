//
//  DiscoverTransitioning.swift
//  toast-project
//
//  Created by Diego Cruz on 2/25/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class DiscoverTransitioning: NSObject, UIViewControllerAnimatedTransitioning{
   
    var isPush:Bool?
    
    init(isPush: Bool) {
        self.isPush = isPush
        super.init()
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval{
        return 0.6
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning)  {
        if isPush! {
            animatePush(transitionContext: transitionContext)
        }
        else {
            animatePop(transitionContext: transitionContext)
        }
    }
    
    func animatePush(#transitionContext: UIViewControllerContextTransitioning){
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! Discover1ViewController!
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let toV = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let containerView = transitionContext.containerView()
        
        var toTable:UIView
        var buttonView:UIView
        var buttonLayer:CALayer
        var buttonLabel:UILabel
        var initialPosition:CGPoint
        if toVC is SelectMoodViewController {
            buttonView = fromVC.moodButtonView
            toTable = (toVC as! SelectMoodViewController).moodsTableView
        }else{
            buttonView = fromVC.locationButtonView
            toTable = UIView()
        }
        buttonLayer = buttonView.layer
        buttonLabel = buttonView.viewWithTag(101) as! UILabel
        initialPosition = buttonLayer.position
        
        toV.frame = transitionContext.finalFrameForViewController(toVC)
        toV.alpha = 0
        toTable.alpha = 0
        containerView.addSubview(toV)
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in

            buttonLayer.transform = CATransform3DMakeScale(0.94, 0.94, 1)
            buttonLabel.alpha = 0
            
            }) { (completion) -> Void in
                
                let newXScale = CGRectGetWidth(fromVC.view.bounds) / CGRectGetWidth(buttonLayer.bounds)
                let newYScale = 64 / CGRectGetHeight(buttonLayer.bounds)
                
                
                UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
                    buttonLayer.transform = CATransform3DMakeScale(newXScale, newYScale, 1)
                    buttonLayer.position = CGPoint (x: CGRectGetWidth(fromVC.view.bounds)/2,y: 32)
                    buttonLayer.borderColor = UIColor.clearColor().CGColor
                }, completion: nil)
                
                UIView.animateWithDuration(0.4, delay: 0.2, options: .CurveEaseInOut, animations: { () -> Void in
                    toV.alpha = 1
                    }, completion: { (completion) -> Void in
                        
                        UIView.animateWithDuration(0.15, delay: 0.1, options: .CurveEaseInOut, animations: { () -> Void in
                            
                            toTable.alpha = 1
                            
                        }, completion: { (completion) -> Void in
                            buttonLayer.transform = CATransform3DMakeScale(1, 1, 1)
                            buttonLayer.position = initialPosition
                            buttonLayer.opacity = 0
                            buttonView.viewWithTag(301)?.alpha = 0.1
                            transitionContext.completeTransition(completion)
                        })
                })
        }
    }
    
    func animatePop(#transitionContext: UIViewControllerContextTransitioning){
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let fromV = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)! as! Discover1ViewController
        let toV = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let containerView = transitionContext.containerView()
        
        toV.frame = transitionContext.finalFrameForViewController(toVC)
        containerView.insertSubview(toV, belowSubview: fromV)
        fromV.backgroundColor = UIColor.clearColor()
        fromV.opaque = false
        
        var myTable:UIView
        var myNav:UIView
        if fromVC is SelectMoodViewController{
            let moodVC = fromVC as! SelectMoodViewController
            myTable = moodVC.moodsTableView
            myNav = moodVC.myNavBar
        }else{
            myTable = UIView()
            myNav = UIView()
        }
        //////
        var buttonLabel:UIView
        var buttonView:UIView
        var buttonLayer:CALayer
        if fromVC is SelectMoodViewController {
            buttonView = toVC.moodButtonView
        }else{
            buttonView = toVC.locationButtonView
        }
        buttonLayer = buttonView.layer
        buttonLabel = buttonView.viewWithTag(101) as! UILabel
        /////
        
        let newXScale = CGRectGetWidth(buttonView.frame)/CGRectGetWidth(myNav.frame)
        let newYScale = CGRectGetHeight(buttonView.frame)/CGRectGetHeight(myNav.frame)
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            myTable.alpha = 0
            myNav.viewWithTag(901)?.alpha = 0
            myNav.viewWithTag(902)?.alpha = 0
        })
        
        UIView.animateWithDuration(0.1,delay: 0.1, options: .CurveEaseInOut,animations: { () -> Void in
            myNav.backgroundColor = UIColor(white: 0, alpha: 0.3)
        }) { (completion) -> Void in
            
            UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseOut, animations: { () -> Void in
                
                for element in fromVC.view.subviews{
                    let imView:UIView = element as! UIView
                    if !imView.isEqual(myNav){
                        imView.alpha = 0
                    }
                }
                
                for element in myNav.subviews{
                    let imView:UIView = element as! UIView
                    imView.alpha = 0
                }
                
                myNav.layer.position.y += 280+12
                myNav.backgroundColor = UIColor(white: 1, alpha: 0.3)
                myNav.layer.transform = CATransform3DMakeScale(newXScale, newYScale, 1)
                
                
                }) { (completion) -> Void in
                    
                    UIView.animateKeyframesWithDuration(0.4, delay: 0, options:
                        .CalculationModeLinear, animations: { () -> Void in
                            
                            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.2, animations: { () -> Void in
                                myNav.alpha = 0
                                buttonView.viewWithTag(301)!.alpha = 0.0
                                buttonLayer.opacity = 1
                            })
                            
                            UIView.addKeyframeWithRelativeStartTime(0.25, relativeDuration: 0.75, animations: { () -> Void in
                                buttonLabel.alpha = 0.4
                                buttonLayer.opacity = 1
                                
                            })
                            
                    }, completion: { (completion) -> Void in
                        fromV.removeFromSuperview()
                        transitionContext.completeTransition(completion)
                    })
            }
        }
        
        
    }
    
}
