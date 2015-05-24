//
//  PostContributeViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 4/4/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class PostContributeViewController: UIViewController,UIViewControllerTransitioningDelegate,PostActionsDelegate {

    @IBOutlet weak var messageHeader: UILabel!
    @IBOutlet weak var welcomeMessageView: UIView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var postContainer: UIView!
    @IBOutlet weak var topConstraintPostContainer: NSLayoutConstraint!
    
    var tempToast:[String:AnyObject]!
    var postRelatedVC:PostRelatedViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure(){
        configureWelcomeMessage()
    }
    
    private func configureWelcomeMessage(){
        configureUserLabel()
        welcomeMessageView.alpha = 0
        welcomeMessageView.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1)
    }
    
    private func configureUserLabel(){
        let user = PFUser.currentUser()
        let names:[String] = (user["name"] as! String).componentsSeparatedByString(" ")
        userNameLabel.text = names[0]+"!"
        messageHeader.text = "Nice toast, "+names[0]+"!"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        UIView.animateKeyframesWithDuration(0.3, delay: 0.2, options: .CalculationModeLinear, animations: { () -> Void in
            
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.75, animations: { () -> Void in
                self.welcomeMessageView.alpha = 1
                self.welcomeMessageView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1)
            })
            
            UIView.addKeyframeWithRelativeStartTime(0.75, relativeDuration: 0.25, animations: { () -> Void in
                self.welcomeMessageView.layer.transform = CATransform3DMakeScale(1, 1, 1)
            })
            
        }) { (completed) -> Void in
            UIView.animateKeyframesWithDuration(0.4, delay: 0.5, options: .CalculationModeLinear, animations: { () -> Void in
                
                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 1, animations: { () -> Void in
                    self.welcomeMessageView.alpha = 0
                    var newPosition = self.welcomeMessageView.layer.position
                    newPosition.y = -200
                    self.welcomeMessageView.layer.position = newPosition
                })
                
                UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: { () -> Void in
                    self.closeButton.alpha = 1
                    self.messageHeader.alpha = 1
                })
                
                UIView.addKeyframeWithRelativeStartTime(0.3, relativeDuration: 0.7, animations: { () -> Void in
                    self.postContainer.alpha = 1
                    var newPosition = self.postContainer.layer.position
                    newPosition.y = CGRectGetHeight(self.view.bounds)/2
                    self.postContainer.layer.position = newPosition
                })
                
            }, completion: { (completed) -> Void in
                /*self.messageHeader.alpha = 0
                self.postRelatedVC.showHeader(self.messageHeader.text!)*/
            })
        }
    }

    //MARK: - Transitioning delegate methods
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PostContributeTransitioning()
    }

    //MARK: - Misc
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //MARK: - Segue methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "postActionsSegue"{
            let destination = segue.destinationViewController as! PostActionsViewController
            destination.myTempToast = tempToast
            destination.myDelegate = self
        }
    }
    
    //MARK: - PostActionsDelegate methods
    func postActionsAddAnotherPressed() {
        if let presentingParent = self.presentingViewController?.presentingViewController{
            presentingParent.dismissViewControllerAnimated(true, completion: { () -> Void in
                let contributeScene = self.storyboard?.instantiateViewControllerWithIdentifier("contributeScene") as! UIViewController
                presentingParent.showDetailViewController(contributeScene, sender: presentingParent)
            })
        }
    }
    
    func postActionsDonePressed() {
        self.presentingViewController?.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK - Action methods
    @IBAction func closePressed(sender: UIButton) {
        self.presentingViewController?.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
