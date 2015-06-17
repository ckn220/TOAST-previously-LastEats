//
//  MainMenuTableView.swift
//  toast-project
//
//  Created by Diego Cruz on 6/13/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class MainMenuTableView: UITableView {


    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        drawBGView(frame: rect)
    }
    
    
    func drawBGView(#frame: CGRect) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Color Declarations
        let color2 = UIColor(red: 0.489, green: 0.489, blue: 0.489, alpha: 1.000)
        
        //// Text Drawing
        let textRect = CGRectMake(frame.minX + 19, frame.minY + frame.height - 36, 118, 21)
        var textTextContent = NSString(string: "Top Toast Labs Inc.")
        let textStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        textStyle.alignment = NSTextAlignment.Left
        
        let textFontAttributes = [NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 13)!, NSForegroundColorAttributeName: color2, NSParagraphStyleAttributeName: textStyle]
        
        let textTextHeight: CGFloat = textTextContent.boundingRectWithSize(CGSizeMake(textRect.width, CGFloat.infinity), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: textFontAttributes, context: nil).size.height
        CGContextSaveGState(context)
        CGContextClipToRect(context, textRect);
        textTextContent.drawInRect(CGRectMake(textRect.minX, textRect.minY + (textRect.height - textTextHeight) / 2, textRect.width, textTextHeight), withAttributes: textFontAttributes)
        CGContextRestoreGState(context)
    }


}
