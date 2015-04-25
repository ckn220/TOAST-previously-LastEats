//
//  HeartButton.swift
//  toast-project
//
//  Created by Diego Cruz on 4/18/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class HeartButton: ReviewDetailButton {
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        //// Color Declarations
        let strokeColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
        let selectedColor = UIColor(red: 0.987, green: 0.250, blue: 0.500, alpha: 1.000)
        let selectedBG = UIColor(white: 1, alpha: 0.2)
        
        //// Bezier Drawing
        var bezierPath = UIBezierPath()
        bezierPath.moveToPoint(CGPointMake(56.43, 12.98))
        bezierPath.addCurveToPoint(CGPointMake(48.69, 12.98), controlPoint1: CGPointMake(54.29, 11.04), controlPoint2: CGPointMake(50.83, 11.04))
        bezierPath.addLineToPoint(CGPointMake(47.24, 14.3))
        bezierPath.addLineToPoint(CGPointMake(45.79, 12.98))
        bezierPath.addCurveToPoint(CGPointMake(38.05, 12.98), controlPoint1: CGPointMake(43.65, 11.04), controlPoint2: CGPointMake(40.19, 11.04))
        bezierPath.addCurveToPoint(CGPointMake(38.05, 20.89), controlPoint1: CGPointMake(35.65, 15.17), controlPoint2: CGPointMake(35.65, 18.7))
        bezierPath.addLineToPoint(CGPointMake(47.24, 29.25))
        bezierPath.addLineToPoint(CGPointMake(56.43, 20.89))
        bezierPath.addCurveToPoint(CGPointMake(56.43, 12.98), controlPoint1: CGPointMake(58.83, 18.7), controlPoint2: CGPointMake(58.83, 15.17))
        bezierPath.addLineToPoint(CGPointMake(56.43, 12.98))
        bezierPath.closePath()
        
        
        if isOn{
            selectedColor.setFill()
            bezierPath.fill()
            
            selectedBG.setFill()
            buttonPath.fill()
        }else{
            strokeColor.setStroke()
            bezierPath.lineWidth = 0.5
            bezierPath.stroke()
        }

    }

}
