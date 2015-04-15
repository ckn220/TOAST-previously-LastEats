//
//  ToastNameView.swift
//  toast-project
//
//  Created by Diego Cruz on 2/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class ToastNameView: ToastCarouselView {

    @IBOutlet weak var nameLabel: UILabel!

    
    override func reloadValues() {
        if let newValue = myDelegate?.toastCarouselViewGetTempToast()["placeName"] as? String{
            nameLabel.text = newValue
            nameLabel.alpha = 1
        }else{
            nameLabel.text = "Write a name"
            nameLabel.alpha = 0.5
        }
    }

}
