//
//  MainViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/15/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class MainViewController: UIViewController,DiscoverDelegate,MainMenuTableDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var discoverContainerView: UIView!
    var animator:UIDynamicAnimator?
    var snapToCenter:UISnapBehavior?
    var snapToSide: UISnapBehavior?
    var discoverBehavior: UIDynamicItemBehavior?
    
    var mainNav:UINavigationController?
    
    var isOpen = false
    var totalOffset:CGFloat = 0
    var canPan = true
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
        if canPan {
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
    }
    
    func removeMySnaps(){
        animator?.removeAllBehaviors()
    }
    
    func addSnap(snap:UISnapBehavior){
        animator?.addBehavior(snap)
        animator?.addBehavior(discoverBehavior)
        
        isOpen = snap.isEqual(snapToSide)
        updateMyStatusBar(hidden: isOpen)
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
        canPan = true
    }
    
    func discoverDidDissapear() {
        canPan = false
    }
    
    func discoverMenuPressed() {
        removeMySnaps()
        if isOpen{
            addSnap(snapToCenter!)
        }else{
            addSnap(snapToSide!)
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
        return canPan
    }
    
    //MARK: - MainMenuTable delegate methods
    func mainMenuTableFriendsPressed() {
        let friendsScene = self.storyboard?.instantiateViewControllerWithIdentifier("friendsListScene") as! FriendsListViewController
        friendsScene.myUser = PFUser.currentUser()
        friendsScene.fromMain = true
        friendsScene.myDelegate = self
        
        changeMainTo(friendsScene)
    }
    
    func mainMenuTableDiscoverPressed() {
        let discoverScene = self.storyboard?.instantiateViewControllerWithIdentifier("discoverScene") as! DiscoverViewController
        discoverScene.myDelegate = self
        
        changeMainTo(discoverScene)
    }
    
    func mainMenuTableMyToastsPressed() {
        let toastsScene = self.storyboard?.instantiateViewControllerWithIdentifier("toastsScene") as! ToastsViewController
        toastsScene.myFriend = PFUser.currentUser()
        
        changeMainTo(toastsScene)
    }
    
    func mainMenuTableContributePressed() {
        let contributeScene = self.storyboard?.instantiateViewControllerWithIdentifier("contributeScene") as! UIViewController
        self.showDetailViewController(contributeScene, sender: nil)
    }
    
    private func changeMainTo(newVC:UIViewController){
        mainNav?.setViewControllers([newVC], animated: false)
        closeMenu()
    }
    
    private func closeMenu(){
        discoverMenuPressed()
    }
}