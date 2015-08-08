//
//  TopToastLabel.swift
//  toast-project
//
//  Created by Diego Cruz on 7/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class TopToastLabel: UILabel {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.borderColor = UIColor.whiteColor().CGColor
        layer.borderWidth = 1.0
    }
    
    override func intrinsicContentSize() -> CGSize {
        var size = super.intrinsicContentSize()
        size.width += 8
        size.height += 2
        
        return size
    }
}
