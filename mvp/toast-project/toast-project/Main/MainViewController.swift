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

class MainViewController: UIViewController,DiscoverDelegate,MainMenuTableDelegate, UIGestureRecognizerDelegate,MFMailComposeViewControllerDelegate, FBSDKSharingDelegate,MFMessageComposeViewControllerDelegate {

    @IBOutlet var myPanGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var discoverContainerView: UIView!
    var animator:UIDynamicAnimator?
    var snapToCenter:UISnapBehavior?
    var snapToSide: UISnapBehavior?
    var discoverBehavior: UIDynamicItemBehavior?
    
    var mainNav:UINavigationController?
    var mailScene:MFMailComposeViewController!
    
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
        animator?.addBehavior(discoverBehavior!)
        
        isOpen = snap.isEqual(snapToSide)
        
        updateMyStatusBar(hidden: isOpen)
        evaluateMyPanDisabling()
    }
    
    func offsetIsValid(offset offset:CGFloat)->Bool{
        if isOpen {
            return totalOffset < 0
        }else{
            return totalOffset >= 0
        }
    }
    
    func endedOpen(view view: UIView){
        var originalX:CGFloat
        let newX = view.layer.position.x
        
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
    
    func updateMyStatusBar(hidden hidden: Bool){
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
            let rootVC = mainNav?.viewControllers[0]
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
        friendsScene.myUser = PFUser.currentUser()!
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
    
    func mainMenuTableMapPressed() {
        let mapScene = storyboard?.instantiateViewControllerWithIdentifier("mapScene") as! MapViewController
        mapScene.myDelegate = self
        
        changeMainTo(mapScene)
    }
    
    func mainMenuTableAcvititvyPressed() {
        let activityScene = storyboard?.instantiateViewControllerWithIdentifier("activityScene") as! ActivityViewController
        activityScene.myDelegate = self
        myPanGestureRecognizer.enabled = true
        changeMainTo(activityScene)
    }
    
    func mainMenuTableMyToastsPressed() {
        let toastsScene = self.storyboard?.instantiateViewControllerWithIdentifier("profileDetailScene") as! ProfileDetailViewController
        toastsScene.myUser = PFUser.currentUser()!
        toastsScene.myDelegate = self
        myPanGestureRecognizer.enabled = false
        
        changeMainTo(toastsScene)
    }
    
    func mainMenuTableContributePressed() {
        let contributeScene = self.storyboard!.instantiateViewControllerWithIdentifier("contributeScene")
        self.showDetailViewController(contributeScene, sender: nil)
    }
    
    func mainMenuTableInviteAFriendPressed() {
        func inviteFromFacebook(withText message:String){
            let content = FBSDKShareLinkContent()
            content.contentTitle = "Try Toast app!"
            content.contentDescription = ""
            content.contentURL = NSURL(string: "http://www.toastapp.co/")!
            
            FBSDKMessageDialog.showWithContent(content, delegate: self)
        }
        
        func inviteFromMessage(withText message:String){
            let messageController = MFMessageComposeViewController()
            messageController.body = "Try Toast app! http://www.toastapp.co/"
            messageController.messageComposeDelegate = self
            presentViewController(messageController, animated: true, completion: nil)
        }
        
        func chooseInvitationSource(){
            let message = "http://toastapp.co/"
            let chooseInvitationController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            let messageButton = UIAlertAction(title: "Message", style: .Default) { (action) -> Void in
                inviteFromMessage(withText: message)
            }
            let facebookButton = UIAlertAction(title: "Facebook Messenger", style: .Default) { (action) -> Void in
                inviteFromFacebook(withText: message)
            }
            let cancelButton = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            
            chooseInvitationController.addAction(messageButton)
            chooseInvitationController.addAction(facebookButton)
            chooseInvitationController.addAction(cancelButton)
            presentViewController(chooseInvitationController, animated: true, completion: nil)
        }
        //
        chooseInvitationSource()
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
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - MessageComposer delegate methods
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - FBSDKSharing delegate methods
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        
    }
    
    func sharerDidCancel(sharer: FBSDKSharing!) {
        
    }
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        
    }
}
