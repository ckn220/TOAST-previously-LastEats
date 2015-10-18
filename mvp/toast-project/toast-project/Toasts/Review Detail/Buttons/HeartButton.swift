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
        
        //// heartBezier Drawing
        let heartBezierPath = UIBezierPath()
        heartBezierPath.moveToPoint(CGPointMake(35.76, 7.54))
        heartBezierPath.addCurveToPoint(CGPointMake(30.43, 7.54), controlPoint1: CGPointMake(34.29, 6.17), controlPoint2: CGPointMake(31.9, 6.17))
        heartBezierPath.addLineToPoint(CGPointMake(29.43, 8.47))
        heartBezierPath.addLineToPoint(CGPointMake(28.43, 7.54))
        heartBezierPath.addCurveToPoint(CGPointMake(23.1, 7.54), controlPoint1: CGPointMake(26.96, 6.17), controlPoint2: CGPointMake(24.57, 6.17))
        heartBezierPath.addCurveToPoint(CGPointMake(23.1, 13.11), controlPoint1: CGPointMake(21.45, 9.08), controlPoint2: CGPointMake(21.45, 11.57))
        heartBezierPath.addLineToPoint(CGPointMake(29.43, 19))
        heartBezierPath.addLineToPoint(CGPointMake(35.76, 13.11))
        heartBezierPath.addCurveToPoint(CGPointMake(35.76, 7.54), controlPoint1: CGPointMake(37.41, 11.57), controlPoint2: CGPointMake(37.41, 9.08))
        heartBezierPath.addLineToPoint(CGPointMake(35.76, 7.54))
        
        
        if isOn{
            selectedColor.setFill()
            heartBezierPath.fill()
            
            selectedBG.setFill()
            buttonPath.fill()
        }else{
            strokeColor.setStroke()
            heartBezierPath.lineWidth = 0.5
            heartBezierPath.stroke()
        }

    }

}
