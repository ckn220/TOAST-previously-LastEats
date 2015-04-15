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
    
    @IBOutlet weak var facebookButtonView: UIVisualEffectView!
    @IBOutlet weak var intagramButtonView: UIVisualEffectView!
    
    var myDateFormatter : NSDateFormatter?
    var myWeather:(temperature:Int,state:Int,date:NSDate)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myDateFormatter = NSDateFormatter()
        myDateFormatter!.dateStyle = .ShortStyle
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        insertVisualEffect(button: facebookButtonView)
        insertVisualEffect(button: intagramButtonView)
        
        validateFacebookSession()
    }
    
    func insertVisualEffect(#button:UIView){
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.whiteColor().CGColor
    }
    
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
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    //MARK: - Facebook Authentication
    @IBAction func facebookDidPressed(sender: UIPanGestureRecognizer) {
        animatePressed(buttonView: sender.view!.viewWithTag(301)!)
    PFFacebookUtils.logInWithPermissions(["public_profile"], block: {
            (user: PFUser!, error: NSError!) -> Void in
            
            if error != nil {
                NSLog("%@", error.description)
            }
            
            if user == nil {
                NSLog("Uh oh. The user cancelled the Facebook login.")
                
            } else if user.isNew {
                NSLog("User signed up and logged in through Facebook!")
                self.getFacebookDetails()
                
            } else {
                NSLog("User logged in through Facebook!")
                self.goToSuccess(isFB: true)
            }
        })
    }
    
    func getFacebookDetails(){
        
        FBRequestConnection.startWithGraphPath("/me?fields=name,picture", completionHandler: { (connection, result, error) -> Void in
            
            if (error == nil){
                let imUser = PFUser.currentUser()
                let myResult = result as! Dictionary<String,AnyObject>
                
                NSLog("%@", myResult["name"] as! String)
                imUser["name"] = myResult["name"]
                imUser["facebookId"] = myResult["id"]
                imUser.saveEventually({ (success, error) -> Void in })
                
                let pictureDic = myResult["picture"] as! Dictionary<String,AnyObject>
                let dataDic = pictureDic["data"] as! Dictionary<String,AnyObject>
                
                let picString = dataDic["url"] as! String
                
                self.getProfilePicture(url: picString, isFB: true)
                
            }
            else {
                NSLog("%@", error.description)
            }
        })
        
    }
    
    func searchFacebookFriends(){
        // Get List Of Friends
        let friendsRequest : FBRequest = FBRequest.requestForMyFriends()
        friendsRequest.startWithCompletionHandler{(connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            
            if error == nil {
                let resultdict = result as! NSDictionary
                let friends = resultdict["data"] as! NSArray
                
                for imFriend in friends {
                    self.validateFacebookFriend(imFriend as! NSDictionary)
                }
                
                PFUser.currentUser().saveEventually({ (success, error) -> Void in
                    if error == nil{
                        self.goToSuccess(isFB: true)
                    }else{
                        NSLog("%@",error.description)
                    }
                })
                
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    func validateFacebookFriend(friend:NSDictionary){
        let user = PFUser.currentUser()
        
        let usersQuery = PFQuery(className: "User")
        usersQuery.whereKey("facebookId", equalTo: friend["id"])
        usersQuery.getFirstObjectInBackgroundWithBlock { (result, error) -> Void in
            if error == nil {
                result.relationForKey("friends").addObject(user)
                user.relationForKey("friends").addObject(result)
                result.saveEventually(nil)
            }else{
                NSLog("%@",error.description)
            }
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
                // Hooray! Let them use the app now.
                NSLog("Signed up in with Instagram")
                
                let newTokenStorage = PFObject(className: "TokenStorage")
                newTokenStorage["accessToken"] = token
                newTokenStorage["userSessionToken"] = user.sessionToken
                newTokenStorage.saveEventually({ (success, error) -> Void in })
                
                self.getInstagramUserDetails(user: user)
                
            } else {
                NSLog("%@", error.description)
            }
        }
        
        
    }
    
    func signinInstagram(#sessionToken: String){
        
        PFUser.becomeInBackground(sessionToken, block: { (user, error) -> Void in
            NSLog("Logged in with Instagram")
            self.goToSuccess(isFB: false)
            
        })
        
    }
    
    func getInstagramUserDetails(#user: PFUser){
        
        
        InstagramEngine.sharedEngine().getSelfUserDetailsWithSuccess({ (user : InstagramUser!) -> Void in
            
            PFUser.currentUser()["name"] = user.fullName
            PFUser.currentUser()["instagramId"] = user.Id
            PFUser.currentUser().saveEventually({ (success, error) -> Void in })
            
            self.getProfilePicture(url: user.profilePictureURL.URLString, isFB: false)
            
            }, failure: { (error) -> Void in
                
                NSLog("%@", error.description)
                self.goToSuccess(isFB: false)
                
        })
        
        
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
    
    func getProfilePicture(#url: String, isFB: Bool)
    {
        Alamofire.request(.GET, url).response({ (request, response, data, error) -> Void in
            
            if error == nil{
                
                let profilePicFile : PFFile = PFFile(name: "profilePic.jpg", data: data as! NSData)
                PFUser.currentUser()["profilePicture"]=profilePicFile
                profilePicFile.saveInBackgroundWithBlock({ (success, error) -> Void in
                    
                    if success == true {
                        PFUser.currentUser()["profilePicture"]=profilePicFile
                        self.searchFacebookFriends()
                        
                    }else{
                        NSLog("%@", error.description)
                        
                    }
                    
                })
                
                self.goToSuccess(isFB: isFB)
                
            }
            else{
                NSLog("%@",error!)
                
                self.goToSuccess(isFB: isFB)
            }
            
        })
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
    
    
    
    
    func goToSuccess(#isFB: Bool){
        let newSceneNav = self.storyboard?.instantiateViewControllerWithIdentifier("mainScene") as! UIViewController
        //as UINavigationController
        //let newScene = newSceneNav.viewControllers[0] as! LoginSuccesViewController
        
        //newScene.isFB = isFB
        
        self.presentViewController(newSceneNav, animated: true, completion: nil)
        
    }
    
}
