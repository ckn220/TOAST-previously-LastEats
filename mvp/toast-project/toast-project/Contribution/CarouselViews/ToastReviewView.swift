//
//  ToastReviewView.swift
//  toast-project
//
//  Created by Diego Cruz on 2/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ToastReviewView: ToastCarouselView,UITextViewDelegate,ReviewAccesoryViewDelegate {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var placeholderView: UITextView!
    @IBOutlet weak var reviewTextView: UITextView!
    var moods:[PFObject]!
    var keyboargHeight:CGFloat?{
        didSet{
            var inset = reviewTextView.contentInset
            inset.bottom = keyboargHeight!
            reviewTextView.contentInset = inset
        }
    }
    
    func toggleFocus(isVisible:Bool){
        if isVisible{
            toggleAlpha(1)
        }else{
            toggleAlpha(0)
        }
    }
    
    private func toggleAlpha(newAlpha:CGFloat){
        
        if newAlpha == 1{
            UIView.animateWithDuration(0.2, delay: 0, options: .CurveLinear, animations: { () -> Void in
                self.containerView.alpha = newAlpha
                }) {(completed) -> Void in
                    self.delay(0.2, closure: { () -> () in
                        self.reviewTextView.becomeFirstResponder()
                        return
                    })
            }
        }else{
            self.reviewTextView.resignFirstResponder()
            UIView.animateWithDuration(0.2, delay: 0, options: .CurveLinear, animations: { () -> Void in
                self.containerView.alpha = newAlpha
            }, completion: nil)
        }
    }
    
    private func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    //MARK: - UITextView delegate methods
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        textView.inputAccessoryView = accesoryReview()
        
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        myDelegate?.toastCarouselViewReviewEditing(textView.text)
    }
    
    private func accesoryReview()->ReviewAccesoryView{
        let accesory = NSBundle.mainBundle().loadNibNamed("ReviewAccesoryView", owner: nil, options: nil)[0] as! ReviewAccesoryView
        accesory.myDelegate = self
        accesory.moods = moods
        return accesory
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        let newLength = textView.text.utf16.count + text.utf16.count - range.length
        togglePlaceHolder(newLength)
    
        return true
    }
    
    func togglePlaceHolder(newLength:Int){
        if newLength == 0{
            placeholderView.alpha = 1
        }else{
            placeholderView.alpha = 0
        }
    }
    
    private func configureTextView(){
        reviewTextView.font = UIFont(name: "Avenir-Roman", size: 14)
        reviewTextView.textColor = UIColor.blackColor()

    }
    
    //MARK: - ReviewAccesoryView delegate methods
    func reviewAccesoryViewDidSelect(hashtag: PFObject) {
        togglePlaceHolder(1)
        reviewTextView.text = reviewTextView.text+" #"+(hashtag["name"] as! String)
        myDelegate?.toastCarouselViewReviewEditing(reviewTextView.text)
    }
}
