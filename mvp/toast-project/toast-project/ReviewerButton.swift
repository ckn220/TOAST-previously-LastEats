//
//  ReviewerButton.swift
//  toast-project
//
//  Created by Diego Cruz on 3/20/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class ReviewerButton: UIButton {
    
    var myImage:UIImage?{
        didSet{
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        // Drawing code
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Rectangle Drawing
        let ovalPath = UIBezierPath(ovalInRect: self.bounds)
        CGContextSaveGState(context)
        ovalPath.addClip()
        
        drawImage()
        CGContextRestoreGState(context)
        
        let strokeColor = UIColor(white:1.0, alpha:0.7)
        strokeColor.setStroke()
        ovalPath.lineWidth = 1
        ovalPath.stroke()
    }
    
    func drawImage(){
        if myImage != nil{
            let originalHeight = myImage!.size.height
            let originalWidth = myImage!.size.width
            var newHeight:CGFloat
            var newWidth:CGFloat
            var newY:CGFloat
            var newX:CGFloat
            
            let parentWidth = CGRectGetWidth(self.bounds)
            let parentHeight = CGRectGetHeight(self.bounds)
            
            if compareDimensions(parentHeight > parentWidth,imageHeightBigger: originalHeight > originalWidth)  {
                newWidth = parentWidth
                newHeight = originalHeight * (newWidth/originalWidth)
            }else{
                newHeight = parentHeight
                newWidth = originalWidth * (newHeight/originalHeight)
            }
            
            newY = (CGRectGetHeight(self.bounds) - newHeight)/2
            newX = (CGRectGetWidth(self.bounds) - newWidth)/2
            let imageRect = CGRectMake(newX, newY, newWidth, newHeight)
            myImage?.drawInRect(imageRect)
        }
    }
    
    func compareDimensions(parentHeightBigger:Bool,imageHeightBigger:Bool) -> Bool{
        if parentHeightBigger{
            return imageHeightBigger
        }else{
            return !imageHeightBigger
        }
    }
}
