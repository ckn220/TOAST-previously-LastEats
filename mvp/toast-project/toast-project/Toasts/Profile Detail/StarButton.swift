//
//  StarButton.swift
//  toast-project
//
//  Created by Diego Cruz on 5/18/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class StarButton: ReviewDetailButton {

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        drawStarButtonCanvas(frame: rect)
    }
    
    func drawStarButtonCanvas(frame frame: CGRect) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Subframes
        let starGroup: CGRect = CGRectMake(frame.minX + floor((frame.width - 15.65) * 0.49998 + 0.32) + 0.18, frame.minY + floor((frame.height - 15.64) * 0.46372 + 0.41) + 0.09, 15.65, 15.64)
        
        //// starGroup
        //// starBezier Drawing
        let starBezierPath = UIBezierPath()
        starBezierPath.moveToPoint(CGPointMake(starGroup.minX + 15.65, starGroup.minY + 5.98))
        starBezierPath.addLineToPoint(CGPointMake(starGroup.minX + 9.94, starGroup.minY + 5.98))
        starBezierPath.addLineToPoint(CGPointMake(starGroup.minX + 7.82, starGroup.minY))
        starBezierPath.addLineToPoint(CGPointMake(starGroup.minX + 5.7, starGroup.minY + 5.98))
        starBezierPath.addLineToPoint(CGPointMake(starGroup.minX, starGroup.minY + 5.98))
        starBezierPath.addLineToPoint(CGPointMake(starGroup.minX + 4.65, starGroup.minY + 9.48))
        starBezierPath.addLineToPoint(CGPointMake(starGroup.minX + 2.99, starGroup.minY + 15.64))
        starBezierPath.addLineToPoint(CGPointMake(starGroup.minX + 7.82, starGroup.minY + 11.95))
        starBezierPath.addLineToPoint(CGPointMake(starGroup.minX + 12.66, starGroup.minY + 15.64))
        starBezierPath.addLineToPoint(CGPointMake(starGroup.minX + 11, starGroup.minY + 9.48))
        starBezierPath.addLineToPoint(CGPointMake(starGroup.minX + 15.65, starGroup.minY + 5.98))
        starBezierPath.closePath()
        starBezierPath.usesEvenOddFillRule = true;
        CGContextSaveGState(context)
        colorStar(starBezierPath,context: context!)
    }
    
    private func colorStar(bezier:UIBezierPath,context:CGContext){
        if isOn{
            colorGradient(bezier, context: context)
        }else{
            colorHollow(bezier)
        }
    }
    
    private func colorGradient(bezier:UIBezierPath,context:CGContext){
        
        //// Color Declarations
        let myYellow = UIColor(red: 0.996, green: 0.811, blue: 0.329, alpha: 1.000)
        let myOrange = UIColor(red: 0.939, green: 0.310, blue: 0.097, alpha: 1.000)
        
        //// Gradient Declarations
        let starGradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [myYellow.CGColor, myOrange.CGColor], [0, 1])
        
        bezier.addClip()
        let starBezierBounds: CGRect = CGPathGetPathBoundingBox(bezier.CGPath)
        CGContextDrawLinearGradient(context, starGradient,
            CGPointMake(starBezierBounds.midX + 0 * starBezierBounds.width / 15.65, starBezierBounds.midY + -7.82 * starBezierBounds.height / 15.64),
            CGPointMake(starBezierBounds.midX + 0 * starBezierBounds.width / 15.65, starBezierBounds.midY + 7.82 * starBezierBounds.height / 15.64),
            CGGradientDrawingOptions())
        CGContextRestoreGState(context)
    }
    
    private func colorHollow(bezier:UIBezierPath){
        UIColor.whiteColor().setStroke()
        bezier.lineWidth = 1
        bezier.stroke()
    }
}
