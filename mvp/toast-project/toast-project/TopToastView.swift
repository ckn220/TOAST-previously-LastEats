//
//  TopToastView.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/16/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit

@IBDesignable class TopToastView: UIView {

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderColor = UIColor.whiteColor().CGColor
        layer.borderWidth = 1
    }

}
