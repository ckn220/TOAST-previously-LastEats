//
//  BlackGradientView.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/17/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit

@IBDesignable class MapBlackGradientView: UIView {

    override func drawRect(rect: CGRect) {
        // Drawing code
        drawBgCanvas(myFrame: rect)
    }

    func drawBgCanvas(myFrame myFrame: CGRect = CGRectMake(0, 0, 240, 120)) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Color Declarations
        let bgClearColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 0.000)
        let bgDarkColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 0.883)
        
        //// Gradient Declarations
        let bgGradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [bgClearColor.CGColor, bgClearColor.blendedColorWithFraction(0.5, ofColor: bgDarkColor).CGColor, bgDarkColor.CGColor], [0.04, 0.18, 0.77])!
        
        //// Rectangle Drawing
        let rectangleRect = CGRectMake(myFrame.minX, myFrame.minY, myFrame.width, myFrame.height)
        let rectanglePath = UIBezierPath(rect: rectangleRect)
        CGContextSaveGState(context)
        rectanglePath.addClip()
        CGContextDrawLinearGradient(context, bgGradient,
            CGPointMake(rectangleRect.midX, rectangleRect.minY),
            CGPointMake(rectangleRect.midX, rectangleRect.maxY),
            CGGradientDrawingOptions())
        CGContextRestoreGState(context)
    }


}
