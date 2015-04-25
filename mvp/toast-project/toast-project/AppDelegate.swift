
//
//  AppDelegate.swift
//  toast-project
//
//  Created by Diego Cruz on 1/2/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    //MARK: -
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        configure(application: application)
        handleLaunch(launchOptions)

        return true
    }
    
    //MARK: Configure methods
    private func configure(#application: UIApplication){
        configureParse()
        configurePushNotifications(application: application)
    }
    
    private func configureParse(){
        Parse.enableLocalDatastore()
        Parse.setApplicationId("HnLgxzOU0ZOTYIRxrRB3ulXDlsS1FGzBl96ytBSk", clientKey: "Towu7llPAMzgeeOUmZjPpXNXM5JoTH1K57BBGwxY")
        PFFacebookUtils.initializeFacebook();
    }
    
    private func configurePushNotifications(#application:UIApplication){
        let userNotificationTypes = (UIUserNotificationType.Alert |
            UIUserNotificationType.Badge |
            UIUserNotificationType.Sound);
        
        let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }
    
    //MARK: Handle Launch methods
    private func handleLaunch(launchOptions: [NSObject: AnyObject]?){
        if let remoteNotification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject : AnyObject] {
            handleLaunchFromPush(remoteNotification)
            
        }else{
            handleLaunchFromNormal()
        }
    }
    
    private func handleLaunchFromPush(notification: [NSObject : AnyObject]){
        let toastId = notification["toastId"] as! String
        showReview(toastId: toastId)
    }
    
    private func showReview(#toastId:String){
        PFQuery(className: "Toast").getObjectInBackgroundWithId(toastId, block: { (toast, error) -> Void in
            if error == nil{
                let destination = self.reviewDetailScene(toast: toast)
                let nav = self.mainNav()
                nav.pushViewController(destination, animated: true)
                
            }else{
                NSLog("%@",error.description)
                self.handleLaunchFromNormal()
            }
        })
    }
    
    private func reviewDetailScene(#toast: PFObject) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let destination = storyboard.instantiateViewControllerWithIdentifier("reviewDetailScene") as! ReviewDetailViewController
        destination.myToast = toast
        
        return destination
    }
    
    private func mainNav() -> UINavigationController {
        let mainScene = window?.rootViewController as! MainViewController
        return mainScene.mainNav!
    }
    
    private func handleLaunchFromNormal(){
        if PFUser.currentUser() == nil{
            goToLogin()
        }else{
            goToDiscover()
        }
    }
    
    
    func goToLogin(){
        PFUser.logOut()
        removeUserFromPush()
        let myStoryboard = UIStoryboard(name: "Main", bundle: nil)
        self.window?.rootViewController = myStoryboard.instantiateViewControllerWithIdentifier("loginScene") as? UIViewController
    }
    
    private func removeUserFromPush(){
        let installation = PFInstallation.currentInstallation()
        installation.removeObjectForKey("user")
        installation.saveInBackgroundWithBlock(nil)
    }
    
    func goToDiscover(){
        let myStoryboard = UIStoryboard(name: "Main", bundle: nil)
        self.window?.rootViewController = myStoryboard.instantiateViewControllerWithIdentifier("mainScene") as? UIViewController
    }
    
    //MARK: -
    func application(application: UIApplication,openURL url: NSURL,sourceApplication: String?,annotation: AnyObject?) -> Bool {
            return FBAppCall.handleOpenURL(url, sourceApplication:sourceApplication,withSession:PFFacebookUtils.session())
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        FBAppCall.handleDidBecomeActiveWithSession(PFFacebookUtils.session())
    }
    
    func applicationWillTerminate(application: UIApplication) {
        PFFacebookUtils.session().close()
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.addUniqueObject("global", forKey: "channels")
        installation.saveInBackgroundWithBlock(nil)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        let toastId = userInfo["toastId"] as! String
        let message = (userInfo["aps"] as! NSDictionary)["alert"] as! String
        
        let a = UIAlertController(title: "Notification", message: message, preferredStyle: .Alert)
        let showButton = UIAlertAction(title: "Show", style: .Default) { (action) -> Void in
            self.showReview(toastId: toastId)
        }
        let cancelButton = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        a.addAction(showButton)
        a.addAction(cancelButton)
        self.mainNav().showDetailViewController(a, sender: nil)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }


}

