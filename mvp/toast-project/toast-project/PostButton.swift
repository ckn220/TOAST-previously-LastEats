//
//  PostButton.swift
//  toast-project
//
//  Created by Diego Cruz on 5/15/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

@IBDesignable
class PostButton: UIButton {

    var buttonPath:UIBezierPath!
    var myColor:UIColor = UIColor.whiteColor(){
        didSet{
            self.setTitleColor(myColor, forState: .Normal)
            self.setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        // Drawing code
        drawBase()
    }
    
    func drawBase(){
        //// Rectangle Drawing
        buttonPath = UIBezierPath(roundedRect: baseFrame(), cornerRadius: 2)
        myColor.setStroke()
        buttonPath.lineWidth = 0.5
        buttonPath.stroke()
    }
    
    private func baseFrame() ->CGRect{
        var newFrame = self.bounds
        newFrame.origin.x = 1
        newFrame.origin.y = 1
        newFrame.size.width -= 2
        newFrame.size.height -= 2
        
        return newFrame
    }

}
