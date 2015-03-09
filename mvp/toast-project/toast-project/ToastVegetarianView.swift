//
//  ToastVegetarianView.swift
//  toast-project
//
//  Created by Diego Cruz on 2/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class ToastVegetarianView: ToastCarouselView {

    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    
    @IBAction func yesPressed(sender: UIButton) {
        toogleYesNo(sender)
    }
    @IBAction func noPressed(sender: UIButton) {
        toogleYesNo(sender)
    }
    
    func toogleYesNo(sender:UIButton){
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            if sender.isEqual(self.yesButton){
                self.noButton.tintColor = UIColor.whiteColor()
                self.yesButton.tintColor = self.yesColor
            }else{
                self.yesButton.tintColor = UIColor.whiteColor()
                self.noButton.tintColor = self.noColor
            }
            }) { (completion) -> Void in
                self.myDelegate?.toastCarouselViewDelegate(indexSelected: self.index!,value: sender.isEqual(self.yesButton))
                return
                
            }
        
        
    }
}
