//
//  MyControl.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/15/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit

class MyControl: UIControl {

    //MARK: - Touch events methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        toggleHighlight(true)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        toggleHighlight(false)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        toggleHighlight(false)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        toggleHighlight(false)
        sendActionsForControlEvents(.TouchUpInside)
    }

    //MARK: Highlight methods
    private func toggleHighlight(active:Bool){
        if active{
            applyHighlight()
        }else{
            delay(0.1, closure: { () -> () in
                self.unapplyHighlight()
            })
        }
    }
    
    func applyHighlight(){
        alpha = 0.6
    }
    
    func unapplyHighlight(){
        alpha = 1
    }
    
    //MARK: - Misc methods
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
