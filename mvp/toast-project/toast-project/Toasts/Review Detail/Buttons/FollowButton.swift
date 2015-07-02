//
//  FollowButton.swift
//  toast-project
//
//  Created by Diego Cruz on 4/18/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class FollowButton: ReviewDetailButton {

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let fillColor = UIColor(red: 0.172, green: 0.768, blue: 0.607, alpha: 1.000)
        
        if isOn{
            fillColor.setFill()
            buttonPath.fill()
            self.setTitle("Following", forState: .Normal)
        }else{
            self.setTitle("Follow", forState: .Normal)
        }
    }
    
}
