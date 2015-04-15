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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        Parse.enableLocalDatastore()
        Parse.setApplicationId("HnLgxzOU0ZOTYIRxrRB3ulXDlsS1FGzBl96ytBSk", clientKey: "Towu7llPAMzgeeOUmZjPpXNXM5JoTH1K57BBGwxY")
        
        PFFacebookUtils.initializeFacebook();
        
        if PFUser.currentUser() == nil{
            goToLogin()
        }else{
            goToDiscover()
        }

        return true
    }
    
    func goToLogin(){
        PFUser.logOut()
        let myStoryboard = UIStoryboard(name: "Main", bundle: nil)
        self.window?.rootViewController = myStoryboard.instantiateViewControllerWithIdentifier("loginScene") as? UIViewController
    }
    
    func goToDiscover(){
        let myStoryboard = UIStoryboard(name: "Main", bundle: nil)
        self.window?.rootViewController = myStoryboard.instantiateViewControllerWithIdentifier("mainScene") as? UIViewController
    }
    
    func application(application: UIApplication,openURL url: NSURL,sourceApplication: String?,annotation: AnyObject?) -> Bool {
            return FBAppCall.handleOpenURL(url, sourceApplication:sourceApplication,withSession:PFFacebookUtils.session())
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        FBAppCall.handleDidBecomeActiveWithSession(PFFacebookUtils.session())
    }
    
    func applicationWillTerminate(application: UIApplication) {
        PFFacebookUtils.session().close()
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

