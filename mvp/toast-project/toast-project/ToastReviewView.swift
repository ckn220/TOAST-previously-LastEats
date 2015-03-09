//
//  ToastReviewView.swift
//  toast-project
//
//  Created by Diego Cruz on 2/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class ToastReviewView: ToastCarouselView {

    @IBOutlet weak var reviewTextView: UITextView!
    
    @IBAction func reviewPressed(sender: UIButton) {
        myDelegate?.toastCarouselViewDelegate(indexSelected: index!, value: nil)
    }

    @IBAction func nextPressed(sender: AnyObject) {
        myDelegate?.toastCarouselViewDelegate(indexSelected: index!, value: 1)
    }
}
