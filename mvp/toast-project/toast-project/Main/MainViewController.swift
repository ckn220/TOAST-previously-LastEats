//
//  MainViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/15/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import MessageUI
import FBSDKShareKit

class MainViewController: UIViewController,DiscoverDelegate,MainMenuTableDelegate, UIGestureRecognizerDelegate,MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate {

    @IBOutlet var myPanGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var discoverContainerView: UIView!
    var animator:UIDynamicAnimator?
    var snapToCenter:UISnapBehavior?
    var snapToSide: UISnapBehavior?
    var discoverBehavior: UIDynamicItemBehavior?
    
    var mainNav:UINavigationController?
    var mailScene:MFMailComposeViewController!
    var inviteMessageScene:MFMessageComposeViewController!
    
    var isOpen = false
    var totalOffset:CGFloat = 0
    var hideStatusBar = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        animator = UIDynamicAnimator(referenceView: self.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        discoverBehavior = UIDynamicItemBehavior(items: [discoverContainerView])
        discoverBehavior?.allowsRotation = false
        
        snapToCenter = UISnapBehavior(item: discoverContainerView,snapToPoint: self.view.center)
        let newCenter = self.view.center
        let offset = CGRectGetWidth(menuContainerView.bounds)
        snapToSide = UISnapBehavior(item: discoverContainerView, snapToPoint: CGPointMake(newCenter.x + offset, newCenter.y))

    }
    
    //MARK: Pan Gesture methods
    @IBAction func handlePan(sender: UIPanGestureRecognizer) {
            if sender.state == .Began {
                removeMySnaps()
                updateMyStatusBar(hidden: true)
            }else if sender.state == .Ended {
                endedOpen(view: sender.view!)
                totalOffset = 0
            }else {
                let myLayer = sender.view?.layer
                let translationX = sender.translationInView(self.view).x
                totalOffset += translationX
                
                if offsetIsValid(offset: translationX) {
                    myLayer?.position.x += translationX
                }
            }
            sender.setTranslation(CGPointZero, inView: self.view)
        
    }
    
    func removeMySnaps(){
        animator?.removeAllBehaviors()
    }
    
    func addSnap(snap:UISnapBehavior){
        animator?.addBehavior(snap)
        animator?.addBehavior(discoverBehavior)
        
        isOpen = snap.isEqual(snapToSide)
        
        updateMyStatusBar(hidden: isOpen)
        evaluateMyPanDisabling()
    }
    
    func offsetIsValid(#offset:CGFloat)->Bool{
        if isOpen {
            return totalOffset < 0
        }else{
            return totalOffset >= 0
        }
    }
    
    func endedOpen(#view: UIView){
        var originalX:CGFloat
        let newX = view.layer.position.x
        let parentWidth = CGRectGetWidth(self.view.bounds)
        
        if !isOpen {
            originalX = self.view.center.x
            
            if newX - originalX > originalX/3{
                addSnap(snapToSide!)
            }else{
                addSnap(snapToCenter!)
            }
        }else{
            originalX = self.view.center.x + CGRectGetWidth(menuContainerView.frame)
            
            if originalX - newX > self.view.center.x/3{
                addSnap(snapToCenter!)
            }else{
                addSnap(snapToSide!)
            }
        }
    }
    
    func updateMyStatusBar(#hidden: Bool){
        /*hideStatusBar = hidden
        setNeedsStatusBarAppearanceUpdate()*/
    }
    
    //MARK: Discover delegate methods
    func discoverDidAppear() {
    }
    
    func discoverDidDissapear() {
    }
    
    func discoverMenuPressed() {
        removeMySnaps()
        if isOpen{
            addSnap(snapToCenter!)
            
        }else{
            addSnap(snapToSide!)
            myPanGestureRecognizer.enabled =  true
        }
    }
    
    private func evaluateMyPanDisabling(){
        if !isOpen {
            let rootVC = mainNav?.viewControllers[0] as! UIViewController
            if rootVC is DiscoverViewController{
                myPanGestureRecognizer.enabled = false
            }
        }
        
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        switch segue.identifier! {
            case "embedDiscoverSegue":
            prepareDiscoverSegue(segue)
            case "embedMenuSegue":
            prepareMenuSegue(segue)
            default:
            return
        }
    }
    
    private func prepareDiscoverSegue(segue: UIStoryboardSegue){
        mainNav = segue.destinationViewController as? UINavigationController
        if let destination = mainNav?.viewControllers[0] as? DiscoverViewController {
            destination.myDelegate = self
        }
    }
    
    private func prepareMenuSegue(segue: UIStoryboardSegue){
        let mainMenu = segue.destinationViewController as! MainMenuTableViewController
        mainMenu.myDelegate = self
    }
    
    //MARK: Misc methods
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return hideStatusBar
    }

    //MARK: - Gesture recognizer delegate methods
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return true
    }
    
    //MARK: - MainMenuTable delegate methods
    func mainMenuTableFriendsPressed() {
        let friendsScene = self.storyboard?.instantiateViewControllerWithIdentifier("friendsListScene") as! FriendsListViewController
        friendsScene.myUser = PFUser.currentUser()
        friendsScene.fromMain = true
        friendsScene.myDelegate = self
        myPanGestureRecognizer.enabled = true
        
        changeMainTo(friendsScene)
    }
    
    func mainMenuTableDiscoverPressed() {
        let discoverScene = self.storyboard?.instantiateViewControllerWithIdentifier("discoverScene") as! DiscoverViewController
        discoverScene.myDelegate = self
        myPanGestureRecognizer.enabled = false
        
        changeMainTo(discoverScene)
    }
    
    func mainMenuTableActivityPressed() {
        let activityScene = storyboard?.instantiateViewControllerWithIdentifier("activityScene") as! ActivityViewController
        activityScene.myDelegate = self
        
        changeMainTo(activityScene)
    }
    
    func mainMenuTableMyToastsPressed() {
        let toastsScene = self.storyboard?.instantiateViewControllerWithIdentifier("profileDetailScene") as! ProfileDetailViewController
        toastsScene.myUser = PFUser.currentUser()
        toastsScene.myDelegate = self
        myPanGestureRecognizer.enabled = false
        
        changeMainTo(toastsScene)
    }
    
    func mainMenuTableContributePressed() {
        let contributeScene = self.storyboard?.instantiateViewControllerWithIdentifier("contributeScene") as! UIViewController
        self.showDetailViewController(contributeScene, sender: nil)
    }
    
    func mainMenuTableInvitePressed() {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            let invitationText = "Invitation text for Toast."
            let invitationURL = "http://lasteats.com"
            
            let chooseAction = UIAlertController(title: nil, message: "Choose a way to invite your friends", preferredStyle: UIAlertControllerStyle.ActionSheet)
            if MFMessageComposeViewController.canSendText(){
                chooseAction.addAction(self.messageAction("\(invitationText) \(invitationURL)"))
            }
            chooseAction.addAction(self.facebookAction(invitationText,urlString:invitationURL))
            self.presentViewController(chooseAction, animated: true, completion: nil)
        }
        
    }
    
    private func messageAction(text:String) -> UIAlertAction{
        return UIAlertAction(title: "Text message", style: .Default) { (alert) -> Void in
            self.closeMenu()
            self.inviteMessageScene = MFMessageComposeViewController()
            self.inviteMessageScene.body = text
            self.inviteMessageScene.messageComposeDelegate = self
            self.presentViewController(self.inviteMessageScene, animated: true, completion: nil)
        }
    }
    
    private func facebookAction(text:String, urlString:String) -> UIAlertAction{
        return UIAlertAction(title: "Facebook Messenger", style: .Default) { (alert) -> Void in
            self.closeMenu()
            let content = FBSDKShareLinkContent()
            content.contentURL = NSURL(string: urlString)
            content.contentTitle = "Try Toast app"
            content.contentDescription = text
            FBSDKMessageDialog.showWithContent(content, delegate: nil)
        }
    }
    
    func mainMenuTableContactUsPressed() {
        closeMenu()
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.mailScene = MFMailComposeViewController()
            self.mailScene.setToRecipients(["colin.narver@gmail.com"])
            self.mailScene.setSubject("Toast Support")
            self.mailScene.mailComposeDelegate = self
            self.presentViewController(self.mailScene, animated: true, completion: nil)
        }
        
    }
    
    private func changeMainTo(newVC:UIViewController){
        mainNav?.setViewControllers([newVC], animated: false)
        closeMenu()
    }
    
    private func closeMenu(){
        discoverMenuPressed()
    }
    
    //MARK: - MailComposer delegate methods
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - MessageComposer delegate methods
    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
