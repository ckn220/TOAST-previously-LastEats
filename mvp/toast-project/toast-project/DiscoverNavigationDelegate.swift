//
//  DiscoverNavigationDelegate.swift
//  toast-project
//
//  Created by Diego Cruz on 2/25/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class DiscoverNavigationDelegate: NSObject, UINavigationControllerDelegate {
   
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if fromVC is Discover1ViewController{
            if toVC is SelectMoodViewController || toVC is SelectLocationViewController{
                return DiscoverTransitioning(isPush: true)
            }else{
                return nil
            }
        }else if toVC is Discover1ViewController{
            if fromVC is SelectMoodViewController || fromVC is SelectLocationViewController{
                return DiscoverTransitioning(isPush: false)
            }else{
                return nil
            }
        }else{
            return nil
        }
    }
    
}
