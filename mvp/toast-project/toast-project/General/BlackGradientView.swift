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
        drawGradientCanvas(myFrame: self.bounds)
    }
    
    func drawGradientCanvas(#myFrame: CGRect) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Color Declarations
        let gradientColor5 = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.000)
        let gradientColor6 = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 0.628)
        
        //// Gradient Declarations
        let gradient2 = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [gradientColor5.CGColor, gradientColor5.blendedColorWithFraction(0.5, ofColor: gradientColor6).CGColor, gradientColor6.CGColor], [0, 0.06, 1])
        
        //// gradientRectangle Drawing
        let gradientRectangleRect = CGRectMake(myFrame.minX, myFrame.minY, myFrame.width, myFrame.height)
        let gradientRectanglePath = UIBezierPath(roundedRect: gradientRectangleRect, cornerRadius: 2)
        CGContextSaveGState(context)
        gradientRectanglePath.addClip()
        CGContextDrawLinearGradient(context, gradient2,
            CGPointMake(gradientRectangleRect.midX + -0 * gradientRectangleRect.width / 269, gradientRectangleRect.midY + -34.5 * gradientRectangleRect.height / 69),
            CGPointMake(gradientRectangleRect.midX + -0 * gradientRectangleRect.width / 269, gradientRectangleRect.midY + -5.11 * gradientRectangleRect.height / 69),
            UInt32(kCGGradientDrawsBeforeStartLocation) | UInt32(kCGGradientDrawsAfterEndLocation))
        CGContextRestoreGState(context)
    }

}
