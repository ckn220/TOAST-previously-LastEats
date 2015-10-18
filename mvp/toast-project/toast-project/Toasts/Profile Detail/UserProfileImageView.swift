//
//  UserProfileImageView.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/14/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit

class UserProfileImageView: BackgroundImageView {

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = CGRectGetWidth(layer.bounds)/2
        layer.borderWidth = 1
        layer.borderColor = UIColor.whiteColor().CGColor
    }
}
