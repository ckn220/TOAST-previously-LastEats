//
//  BlackGradientView.swift
//  toast-project
//
//  Created by Diego Cruz on 5/7/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class BlackGradientView: UIView {
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        drawGradientCanvas(frame: self.bounds)
    }
    
    func drawGradientCanvas(#frame: CGRect) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Color Declarations
        let gradientColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.000)
        let gradientColor2 = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 0.6)
        
        //// Gradient Declarations
        let shadowGradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [gradientColor2.CGColor, gradientColor2.CGColor,gradientColor.CGColor], [0,0.5, 1])
        
        //// Rectangle Drawing
        let rectangleRect = CGRectMake(frame.minX, frame.minY, frame.width, frame.height)
        let rectanglePath = UIBezierPath(rect: rectangleRect)
        CGContextSaveGState(context)
        rectanglePath.addClip()
        CGContextDrawLinearGradient(context, shadowGradient,
            CGPointMake(rectangleRect.midX, rectangleRect.maxY),
            CGPointMake(rectangleRect.midX, rectangleRect.minY),
            0)
        CGContextRestoreGState(context)
    }


}
