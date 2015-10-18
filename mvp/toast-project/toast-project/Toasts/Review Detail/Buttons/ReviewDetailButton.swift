//
//  ReviewDetailButton.swift
//  toast-project
//
//  Created by Diego Cruz on 4/18/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

@IBDesignable
class ReviewDetailButton: UIButton {

    var buttonPath:UIBezierPath!
    var isOn:Bool = false {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        toggleButton()
        super.touchesEnded(touches, withEvent: event)
    }
    
    func toggleButton(){
        isOn = !isOn
    }
    
    override func drawRect(rect: CGRect) {
        drawBase()
    }
    
    func drawBase(){
        //// Rectangle Drawing
        buttonPath = UIBezierPath(roundedRect: baseFrame(), cornerRadius: 19)
        UIColor(white: 1, alpha: 0.6).setStroke()
        buttonPath.lineWidth = 0.5
        buttonPath.stroke()
    }
    
    private func baseFrame() ->CGRect{
        var newFrame = self.bounds
        newFrame.origin.x = 1
        newFrame.origin.y = 1
        newFrame.size.width -= 2
        newFrame.size.height -= 2
        
        return newFrame
    }

}
