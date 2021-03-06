//
//  LoginViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 1/2/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import CoreLocation
import Alamofire
import ParseFacebookUtilsV4

class LoginViewController: UIViewController,CLLocationManagerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureBG()
        //validateFacebookSession()
    }
    
    private func configureBG(){
        let myBG = self.view as! BackgroundImageView
        myBG.setImage(fileName: "loginBG", opacity: 0.35)
    }
    /*
    func validateFacebookSession(){
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        let label = facebookButtonView.viewWithTag(101) as! UILabel
        let initialText = label.text
        
        if accountType.accessGranted == true {
            if FBSession.activeSession().isOpen == true {
                FBRequestConnection.startForMeWithCompletionHandler({ (request, result, error) -> Void in
                    
                    let name:String = result["name"] as! String
                    label.text = "Continue as! "+name
                })
            }
        }
        else{
            label.text = initialText
        }
    }*/
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    //MARK: - Facebook Authentication
    @IBAction func facebookDidPressed(sender: AnyObject) {
        //animatePressed(buttonView: sender.view!.viewWithTag(301)!)
        facebookLogin()
    }
    
    func facebookLogin(){
            PFFacebookUtils.logInInBackgroundWithReadPermissions(["public_profile","user_friends"]) { (user, error) -> Void in
            
            if let error = error{
                NSLog("facebookLogin error: %@", error.description)
            }else if let user = user{
                if user.isNew{
                    self.facebookDidSignup()
                }else{
                    self.goToSuccess()
                }
            }else{
                NSLog("facebookLogin canceled")
            }
        }
    }
    
    func facebookDidSignup(){
        PFUser.currentUser()!["savedFirstTime"] = 1
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        getFacebookDetails(group: group)
        dispatch_group_enter(group)
        getFacebookFriends(group: group)
        
        facebookDidSignupCompletion(group: group)
    }
    
    func facebookDidSignupCompletion(group group: dispatch_group_t){
        myGroupCompletion(group: group) { () -> Void in
            PFUser.currentUser()!.saveInBackgroundWithBlock({ (success, error) -> Void in
                if error == nil{
                    self.goToSuccess()
                }else{
                    NSLog("facebookDidSignupCompletion error: %@",error!.description)
                }
            })
        }
    }
    
    private func myGroupCompletion(group group: dispatch_group_t,block: ()->Void){
        dispatch_group_notify(group, dispatch_get_main_queue(), block)
    }
    
    func getFacebookDetails(group group: dispatch_group_t){
        
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields":"name,email"]).startWithCompletionHandler { (_, result, error) -> Void in
            if (error == nil){
                let imUser = PFUser.currentUser()!
                let myResult = result as! Dictionary<String,AnyObject>
                
                imUser["name"] = myResult["name"]
                imUser["facebookId"] = myResult["id"]
                if let email = myResult["email"] as? String{
                    imUser["email"] = email
                }
                
            }
            else {
                NSLog("getFacebookDetails error: %@", error.description)
            }
            
            dispatch_group_leave(group)
        }
        
    }
    
    func getFacebookFriends(group group: dispatch_group_t){
        FBSDKGraphRequest(graphPath: "/me/friends", parameters: nil).startWithCompletionHandler { (_, result, error) -> Void in
            if error == nil {
                let resultdict = result as! NSDictionary
                let friends = resultdict["data"] as! NSArray
                var friendsIds = [String]()
                
                for imFriend in friends {
                    friendsIds.append(imFriend["id"] as! String)
                }
                self.searchFacebookFriendsOnToast(friendsIds, group: group)
            }else{
                NSLog("getFacebookFriends error: %@",error.description)
            }
        }
    }
    
    private func searchFacebookFriendsOnToast(friends:[String],group: dispatch_group_t){
        let userQuery = PFUser.query()!
        userQuery.whereKey("facebookId", containedIn: friends)
        userQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                for friend in result!{
                    PFUser.currentUser()!.relationForKey("friends").addObject(friend)
                }
            }else{
                NSLog("searchFacebookFriendsOnToast error: %@",error!.description)
            }
            dispatch_group_leave(group)
        }
    }
    
    //MARK: - General login
    func animatePressed(buttonView buttonView:UIView){
        UIView.animateKeyframesWithDuration(0.2, delay: 0, options: .CalculationModePaced, animations: { () -> Void in
            
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.1, animations: { () -> Void in
                buttonView.alpha = 0.3
            })
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.1, animations: { () -> Void in
                buttonView.alpha = 0
            })
            
        }, completion: nil)
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
      
    func goToSuccess(){
        let user = PFUser.currentUser()!
        updatePushWithUser(user)
        
        let newSceneNav = self.storyboard!.instantiateViewControllerWithIdentifier("mainScene")
        self.presentViewController(newSceneNav, animated: true, completion: nil)
        
    }
    
    //MARK: - Push methods
    private func updatePushWithUser(user:PFUser){
        let installation = PFInstallation.currentInstallation()
        installation["user"] = user
        installation.saveInBackgroundWithBlock(nil)
    }
    
}
