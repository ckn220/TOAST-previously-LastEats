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
        let gradientColor5 = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.000)
        let gradientColor6 = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 0.628)
        
        //// Gradient Declarations
        let gradient2 = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [gradientColor5.CGColor, gradientColor5.blendedColorWithFraction(0.5, ofColor: gradientColor6).CGColor, gradientColor6.CGColor], [0, 0.25, 1])
        
        
        //// Subframes
        let group3: CGRect = CGRectMake(frame.minX + 0.2, frame.minY + floor((frame.height + 0.02) * 0.54193 - 0.48) + 0.98, frame.width - 0.1, frame.height - 0.95 - floor((frame.height + 0.02) * 0.54193 - 0.48))
        
        
        //// Group 3
        //// Rectangle Drawing
        let rectangleRect = CGRectMake(group3.minX + floor(group3.width * 0.00000 + 0.5), group3.minY + floor(group3.height * 0.00000 + 0.5), floor(group3.width * 1.00000 - 0.4) - floor(group3.width * 0.00000 + 0.5) + 0.9, floor(group3.height * 1.00000 + 0.15) - floor(group3.height * 0.00000 + 0.5) + 0.35)
        let rectanglePath = UIBezierPath(rect: rectangleRect)
        CGContextSaveGState(context)
        rectanglePath.addClip()
        CGContextDrawLinearGradient(context, gradient2,
            CGPointMake(rectangleRect.midX + -0.01 * rectangleRect.width / 537.9, rectangleRect.midY + -69.18 * rectangleRect.height / 138.35),
            CGPointMake(rectangleRect.midX + -0.01 * rectangleRect.width / 537.9, rectangleRect.midY + -10.24 * rectangleRect.height / 138.35),
            UInt32(kCGGradientDrawsBeforeStartLocation) | UInt32(kCGGradientDrawsAfterEndLocation))
        CGContextRestoreGState(context)
    }

}
