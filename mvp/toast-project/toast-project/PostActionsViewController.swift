//
//  PostActionsViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 5/15/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol PostActionsDelegate {
    func postActionsDonePressed()
    func postActionsAddAnotherPressed()
}

class PostActionsViewController: UIViewController {

    @IBOutlet weak var yesButton: PostButton!
    @IBOutlet weak var postQuestionLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var yesSpacingConstraint: NSLayoutConstraint!
    
    var myDelegate:PostActionsDelegate?
    var myTempToast:[String:AnyObject]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureVenueName()
    }
    
    private func configureVenueName(){
        let name = myTempToast["placeName"] as! String
        let firstText = "Want to make "
        let lastText = " your Top Toast?"
        
        var finalText = NSMutableAttributedString(string: firstText)
        finalText.appendAttributedString(nameString(name))
        finalText.appendAttributedString(normalString(lastText))
        postQuestionLabel.attributedText = finalText
    }
    
    private func normalString(text:String)->NSAttributedString{
        return NSAttributedString(string: text)
    }
    
    private func nameString(text:String)->NSAttributedString{
        return NSAttributedString(string: text, attributes: [NSForegroundColorAttributeName:UIColor(red:0, green:0.569, blue:1, alpha:1)])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Actions methods
    @IBAction func yesPressed(sender: PostButton) {
        setTopToast()
        changeToDone()
    }
    
    private func setTopToast(){
        PFCloud.callFunctionInBackground("setLastTopToast", withParameters: nil) { (result, error) -> Void in
        }
    }
    
    private func changeToDone(){
        
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
            
            self.yesButton.setTitle("Done", forState: .Normal)
            let doneColor = UIColor(red:0.313, green:0.89, blue:0.76, alpha:1)
            self.yesButton.myColor = doneColor
            
            }) { (completed) -> Void in
                self.delay(0.8, closure: { () -> () in
                    self.myDelegate?.postActionsDonePressed()
                })
        }
    }
    
    @IBAction func addAnotherPressed(sender: PostButton) {
        myDelegate?.postActionsAddAnotherPressed()
    }
    
    @IBAction func donePressed(sender: PostButton) {
        myDelegate?.postActionsDonePressed()
    }
    
    //MARK: - Misc methods
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
