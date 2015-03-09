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

    @IBAction func namePressed(sender: UIButton) {
        myDelegate?.toastCarouselViewDelegate(indexSelected: index!,value: nil)
    }
    
    override func reloadValues() {
        if let newValue = myDelegate?.toastCarouselViewDelegateGetTempToast()["placeName"] as? String{
            nameLabel.text = newValue
            nameLabel.alpha = 1
        }else{
            nameLabel.text = "Write a name"
            nameLabel.alpha = 0.5
        }
    }

}
