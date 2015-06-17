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

class LoginViewController: UIViewController,CLLocationManagerDelegate,LoginInstagramDelegate {
    
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
        myBG.setImage("loginBG", opacity: 0.35)
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
        PFFacebookUtils.logInWithPermissions(["public_profile","user_friends"], block: {
            (user: PFUser!, error: NSError!) -> Void in
            
            if error != nil {
                NSLog("Facebook Login failed: %@", error.description)
            }else{
                if user == nil {
                    NSLog("Facebook Login canceled.")
                    
                } else if user.isNew {
                    NSLog("Facebook signup succeded")
                    self.facebookDidSignup()
                    
                } else {
                    NSLog("Facebook login succeded")
                    self.goToSuccess()
                }
            }
            
        })
    }
    
    func facebookDidSignup(){
        PFUser.currentUser()["savedFirstTime"] = 1
        var group = dispatch_group_create()
        dispatch_group_enter(group)
        getFacebookDetails(group: group)
        dispatch_group_enter(group)
        getFacebookPicture(group: group)
        dispatch_group_enter(group)
        getFacebookFriends(group: group)
        
        facebookDidSignupCompletion(group: group)
    }
    
    func facebookDidSignupCompletion(#group: dispatch_group_t){
        myGroupCompletion(group: group) { () -> Void in
            PFUser.currentUser().saveInBackgroundWithBlock({ (success, error) -> Void in
                if error == nil{
                    self.goToSuccess()
                }else{
                    NSLog("facebookDidSignupCompletion error: %@",error.description)
                }
            })
        }
    }
    
    private func myGroupCompletion(#group: dispatch_group_t,block: ()->Void){
        dispatch_group_notify(group, dispatch_get_main_queue(), block)
    }
    
    func getFacebookDetails(#group: dispatch_group_t){
        
        FBRequestConnection.startWithGraphPath("/me?fields=name,email", completionHandler: { (connection, result, error) -> Void in
            
            if (error == nil){
                let imUser = PFUser.currentUser()
                let myResult = result as! Dictionary<String,AnyObject>
                
                imUser["name"] = myResult["name"]
                imUser["facebookId"] = myResult["id"]
                imUser["email"] = myResult["email"]
            }
            else {
                NSLog("getFacebookDetails error: %@", error.description)
            }
            
            dispatch_group_leave(group)
        })
        
    }
    
    func getFacebookPicture(#group: dispatch_group_t){
        FBRequestConnection.startWithGraphPath("/me/picture?type=large&redirect=false", completionHandler: { (connection, result, error) -> Void in
            
            if (error == nil){
                let imUser = PFUser.currentUser()
                let pictureURL = (result["data"] as! NSDictionary)["url"] as! String
                imUser["pictureURL"] = pictureURL
            }
            else {
                NSLog("getFacebookPicture error: %@", error.description)
            }
            
            dispatch_group_leave(group)
        })
    }
    
    func getFacebookFriends(#group: dispatch_group_t){
        // Get List Of Friends
        let friendsRequest : FBRequest = FBRequest.requestForMyFriends()
        friendsRequest.startWithCompletionHandler{(connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            
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
        let userQuery = PFUser.query()
        userQuery.whereKey("facebookId", containedIn: friends)
        userQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                for friend in result as! [PFObject]{
                    PFUser.currentUser().relationForKey("friends").addObject(friend)
                }
            }else{
                NSLog("searchFacebookFriendsOnToast error: %@",error.description)
            }
            dispatch_group_leave(group)
        }
    }
    
    
    //MARK: - Instagram Authentication
    @IBAction func instagramDidPressed(sender: UITapGestureRecognizer) {
        animatePressed(buttonView: sender.view!.viewWithTag(301)!)
        let destinationNav = storyboard?.instantiateViewControllerWithIdentifier("loginInstagramNavScene") as! UINavigationController
        let destination = destinationNav.viewControllers[0] as! LoginInstagramViewController
        destination.myDelegate = self
        
        self.showDetailViewController(destinationNav, sender: self)
    }
    
    func loginInstagramDidClose(#token: String) {
        if token.isEmpty == false {
            
            var query = PFQuery(className:"TokenStorage")
            query.whereKey("accessToken", equalTo:token)
            
            query.findObjectsInBackgroundWithBlock({ (objects:[AnyObject]!, error) -> Void in
                
                if error == nil {
                    
                    if objects.count > 0 {
                        
                        let mySessionToken = objects[0]["userSessionToken"] as! String
                        self.signinInstagram(sessionToken: mySessionToken)
                    }
                    else{
                        self.signupInstagram(token: token)
                    }
                }
                else{
                    UIAlertView(title: "Instagram login failed", message: error.description, delegate: self, cancelButtonTitle: "OK").show()
                }
                
            })
            
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func signupInstagram(#token : String){
        
        let user = PFUser()
        
        let uuidUSer: CFUUIDRef = CFUUIDCreate(nil)
        let newUsername: CFStringRef = CFUUIDCreateString(nil, uuidUSer)
        
        let uuidPass: CFUUIDRef = CFUUIDCreate(nil)
        let newPassword: CFStringRef = CFUUIDCreateString(nil, uuidPass)
        
        user.username = newUsername as String
        user.password = newPassword as String
        
        user.signUpInBackgroundWithBlock {
            (succeeded: Bool, error: NSError!) -> Void in
            if error == nil {
                NSLog("Signed up in with Instagram")
                
                let newTokenStorage = PFObject(className: "TokenStorage")
                newTokenStorage["accessToken"] = token
                newTokenStorage["userSessionToken"] = user.sessionToken
                newTokenStorage.saveInBackgroundWithBlock(nil)
                
                self.getInstagramUserDetails(user: user)
            } else {
                NSLog("%@", error.description)
            }
        }
        
        
    }
    
    func signinInstagram(#sessionToken: String){
        
        PFUser.becomeInBackground(sessionToken, block: { (user, error) -> Void in
            NSLog("Logged in with Instagram")
            self.goToSuccess()
            
        })
        
    }
    
    func getInstagramUserDetails(#user: PFUser){
        
        InstagramEngine.sharedEngine().getSelfUserDetailsWithSuccess({ (user : InstagramUser!) -> Void in
            
            let imUser = PFUser.currentUser()
            imUser["name"] = user.fullName
            imUser["instagramId"] = user.Id
            imUser["pictureURL"] = user.profilePictureURL.URLString
            self.goToSuccess()
        },failure: nil)
    }
    
    //MARK: - General login
    func animatePressed(#buttonView:UIView){
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
        
        if segue.identifier == "loginInstagramSegue" {
            
            let destinationNav = segue.destinationViewController as! UINavigationController
            let destination = destinationNav.viewControllers[0] as! LoginInstagramViewController
            
            destination.myDelegate = self
            
        }
        
    }
      
    func goToSuccess(){
        let user = PFUser.currentUser()
        updatePushWithUser(user)
        
        let newSceneNav = self.storyboard?.instantiateViewControllerWithIdentifier("mainScene") as! UIViewController
        self.presentViewController(newSceneNav, animated: true, completion: nil)
        
    }
    
    //MARK: - Push methods
    private func updatePushWithUser(user:PFUser){
        let installation = PFInstallation.currentInstallation()
        installation["user"] = user
        installation.saveInBackgroundWithBlock(nil)
    }
    
}
