//
//  ToastCarouselView.swift
//  toast-project
//
//  Created by Diego Cruz on 2/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol ToastCarouselViewDelegate {
    func toastCarouselViewDelegateGetTempToast() -> [String:AnyObject]
    func toastCarouselViewDelegate(indexSelected index:Int, value: AnyObject?)
}

class ToastCarouselView: UIView {

    let yesColor = UIColor(red: 0.181, green: 0.793, blue: 0.668, alpha: 1)
    let noColor = UIColor(red: 119.0/255, green: 124.0/255, blue: 146.0/255, alpha: 1)
    var index:Int?
    var myDelegate:ToastCarouselViewDelegate?
    
    func setViewValues(#index: Int){
        self.index = index
    }
    
    func reloadValues(){
        
    }
}
