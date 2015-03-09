//
//  ToastSubmitView.swift
//  toast-project
//
//  Created by Diego Cruz on 2/27/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class ToastSubmitView: ToastCarouselView {

    
    @IBAction func submitPressed(sender: UIButton) {
        myDelegate?.toastCarouselViewDelegate(indexSelected: index!, value: nil)
    }

}
