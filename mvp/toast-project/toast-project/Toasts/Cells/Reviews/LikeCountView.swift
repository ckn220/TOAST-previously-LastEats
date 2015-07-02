//
//  LikeCountView.swift
//  toast-project
//
//  Created by Diego Cruz on 5/15/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

@IBDesignable
class LikeCountView: UIView {

    var count:Int=0{
        didSet{
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        // Drawing code
        var lastWord = " likes"
        if count == 1{
            lastWord = " like"
        }
        drawCanvasLikeCount(countString:"\(count)"+lastWord)
    }
    
    func drawCanvasLikeCount(#countString: String) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Color Declarations
        let fillColor5 = UIColor(red: 0.538, green: 0.538, blue: 0.538, alpha: 1.000)
        let textForeground = UIColor(red: 0.592, green: 0.694, blue: 0.808, alpha: 1.000)
        
        //// heartGroup
        CGContextSaveGState(context)
        CGContextBeginTransparencyLayer(context, nil)
        
        //// Clip heartClip
        var heartClipPath = UIBezierPath()
        heartClipPath.moveToPoint(CGPointMake(11.02, 4.81))
        heartClipPath.addCurveToPoint(CGPointMake(6.79, 4.81), controlPoint1: CGPointMake(9.85, 3.73), controlPoint2: CGPointMake(7.96, 3.73))
        heartClipPath.addLineToPoint(CGPointMake(6, 5.54))
        heartClipPath.addLineToPoint(CGPointMake(5.21, 4.81))
        heartClipPath.addCurveToPoint(CGPointMake(0.98, 4.81), controlPoint1: CGPointMake(4.04, 3.73), controlPoint2: CGPointMake(2.15, 3.73))
        heartClipPath.addCurveToPoint(CGPointMake(0.98, 9.2), controlPoint1: CGPointMake(-0.33, 6.02), controlPoint2: CGPointMake(-0.33, 7.98))
        heartClipPath.addLineToPoint(CGPointMake(6, 13.83))
        heartClipPath.addLineToPoint(CGPointMake(11.02, 9.2))
        heartClipPath.addCurveToPoint(CGPointMake(11.02, 4.81), controlPoint1: CGPointMake(12.33, 7.98), controlPoint2: CGPointMake(12.33, 6.02))
        heartClipPath.addLineToPoint(CGPointMake(11.02, 4.81))
        heartClipPath.closePath()
        heartClipPath.usesEvenOddFillRule = true;
        
        heartClipPath.addClip()
        
        
        //// heartRectangle Drawing
        let heartRectanglePath = UIBezierPath(rect: CGRectMake(-5, 1.27, 20.6, 18.55))
        fillColor5.setFill()
        heartRectanglePath.fill()
        
        
        CGContextEndTransparencyLayer(context)
        CGContextRestoreGState(context)
        
        
        //// likeCountLabel Drawing
        let likeCountLabelRect = CGRectMake(16.22, 0, 36.67, 19)
        let likeCountLabelStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        likeCountLabelStyle.alignment = NSTextAlignment.Center
        
        let likeCountLabelFontAttributes = [NSFontAttributeName: UIFont(name: "Avenir-Book", size: 11)!, NSForegroundColorAttributeName: textForeground, NSParagraphStyleAttributeName: likeCountLabelStyle]
        
        let likeCountLabelTextHeight: CGFloat = NSString(string: countString).boundingRectWithSize(CGSizeMake(likeCountLabelRect.width, CGFloat.infinity), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: likeCountLabelFontAttributes, context: nil).size.height
        CGContextSaveGState(context)
        CGContextClipToRect(context, likeCountLabelRect);
        NSString(string: countString).drawInRect(CGRectMake(likeCountLabelRect.minX, likeCountLabelRect.minY + (likeCountLabelRect.height - likeCountLabelTextHeight) / 2, likeCountLabelRect.width, likeCountLabelTextHeight), withAttributes: likeCountLabelFontAttributes)
        CGContextRestoreGState(context)
    }

}
