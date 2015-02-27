//
//  BackgroundImageView.swift
//  toast-project
//
//  Created by Diego Cruz on 2/12/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import AVFoundation

class BackgroundImageView: UIView {

    var myImage: UIImage?
    var myOpacity:CGFloat = 0.0
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: self.bounds)
        CGContextSaveGState(context)
        rectanglePath.addClip()

        drawImage()
        if myOpacity > 0{
            drawOpacity()
        }
        
        CGContextRestoreGState(context)
    }
    
    func insertImage(newImage:UIImage){
        myImage = newImage
        self.setNeedsDisplay()
        
    }
    
    func insertImage(newImage:UIImage, withOpacity opacity:CGFloat){
        myOpacity = opacity
        insertImage(newImage)
    }
    
    func drawImage(){
        if myImage != nil{
            let originalHeight = myImage!.size.height
            let originalWidth = myImage!.size.width
            var newHeight:CGFloat
            var newWidth:CGFloat
            var newY:CGFloat
            var newX:CGFloat
            
            if originalHeight >= originalWidth {
                newWidth = CGRectGetWidth(self.bounds)
                newHeight = originalHeight * (newWidth/originalWidth)
            }else{
                newHeight = CGRectGetHeight(self.bounds)
                newWidth = originalWidth * (newHeight/originalHeight)
            }
            
            newY = (CGRectGetHeight(self.bounds) - newHeight)/2
            newX = (CGRectGetWidth(self.bounds) - newWidth)/2
            let imageRect = CGRectMake(newX, newY, newWidth, newHeight)
            myImage?.drawInRect(imageRect)
        }
    }
    
    func drawOpacity(){
        let opacityRectangle = UIBezierPath(rect: self.bounds)
        let color = UIColor(red: 38.0/255, green: 38.0/255, blue: 38.0/255, alpha: myOpacity)
        color.setFill()
        opacityRectangle.fill()
    }
}
