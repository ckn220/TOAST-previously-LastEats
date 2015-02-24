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

    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var myTimeLabel: UILabel!
    @IBOutlet weak var myWeatherLabel: UILabel!
    @IBOutlet weak var myLastLabel: UILabel!
    
    var myDateFormatter : NSDateFormatter?
    var myWeather:(temperature:Int,state:Int,date:NSDate)?
    var loggedUser:PFUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myDateFormatter = NSDateFormatter()
        myDateFormatter!.dateStyle = .ShortStyle
        
        printWeatherInfo()
        printTimeInfo()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        
        if accountType.accessGranted == true {
            
            if FBSession.activeSession().isOpen == true {
                
                FBRequestConnection.startForMeWithCompletionHandler({ (request, result, error) -> Void in
                    
                    let name:String = result["name"] as String
                    
                    self.facebookButton.setTitle("CONTINUE AS "+name.uppercaseString, forState: UIControlState.Normal)
                    self.facebookButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16)
                    
                })
                
            }
            
        }
        else{
            
            self.facebookButton.setTitle("SIGN IN WITH FACEBOOK", forState: UIControlState.Normal)
            self.facebookButton.titleLabel?.font = UIFont.boldSystemFontOfSize(18)
            
        }
   
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFUser.logOut()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func printWeatherInfo(){
        
        Alamofire.request(.GET, "http://api.openweathermap.org/data/2.5/weather?q=new,york&APPID=1cec9211c792bf8f901772d017c9ff5b")
            .responseJSON { (imRequest, imResponse, JSON, error) in
                
                //NSLog("%@", JSON as NSDictionary)
                
                if error == nil{

                    let result = JSON as NSDictionary
                    
                    if (result["message"] == nil) {
                        var temp = result["main"]!["temp"] as Int
                        
                        var tempText : String
                        var condiText : String
                        
                        switch (temp - 273) {
                        case -1000...10:
                            tempText = "cold"
                        case 11...18:
                            tempText = "fresh"
                        case 20...1000:
                            tempText = "hot"
                        default:
                            tempText = "cool"
                        }
                        
                        let cond = result["weather"]![0]["id"] as Int
                        
                        switch cond{
                        case 200...299:
                            condiText = "stormy"
                        case 300...399:
                            condiText = "drizzly"
                        case 500...599:
                            condiText = "rainy"
                        case 600...699:
                            condiText = "snowy"
                        case 800...802:
                            condiText = "clear"
                        case 803...899:
                            condiText = "cloudy"
                        default:
                            condiText = "normal"
                        }
                        
                        self.myWeatherLabel.text = "It's " + tempText + " and " + condiText
                        
                        UIView.animateWithDuration(0.4, animations: { () -> Void in
                            self.myTimeLabel.alpha = 1
                            self.myWeatherLabel.alpha=1
                            self.myLastLabel.alpha = 1
                            }, completion: nil)
                    }
                    else{
                        let a = UIAlertView(title: "Open Weather Error", message: error?.description, delegate: self, cancelButtonTitle: "OK")
                        a.show()
                    }
                    
                    
                    
                    
                    
                }
                else{
                    let a = UIAlertView(title: "Open Weather Error", message: error?.description, delegate: self, cancelButtonTitle: "OK")
                    a.show()
                }
                
        }
        
    }
    
    func printTimeInfo(){
        
        let days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        let times = ["early morning","late morning","early afternoon","late afternoon","night","late night"]
        
        let myTimeInfo = self.getTimeInfo()
        let dayText = days[myTimeInfo.day-1]
        var timeText :String
        
        switch myTimeInfo.time {
        case 0...4:
            timeText = times[5]
        case 5...8:
            timeText = times[0]
        case 9...11:
            timeText = times[1]
        case 12...15:
            timeText = times[2]
        case 16...18:
            timeText = times[3]
        case 19...23:
            timeText = times[4]
        default:
            timeText = times[5]
        }
        
        self.myTimeLabel.text = "It's " + dayText + " " + timeText
    }

    func getTimeInfo() -> (day:Int,time:Int){
        
        let myCalendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        let myWeekDay = myCalendar?.components(NSCalendarUnit.CalendarUnitWeekday | NSCalendarUnit.CalendarUnitHour, fromDate: NSDate())
        return (myWeekDay!.weekday,myWeekDay!.hour)
   
    }
    
    @IBAction func facebookDidPressed(sender: UIButton) {
        
        PFFacebookUtils.logInWithPermissions(["public_profile"], {
            (user: PFUser!, error: NSError!) -> Void in
            
            if error != nil {
                NSLog("%@", error.description)
            }
            
            if user == nil {
                NSLog("Uh oh. The user cancelled the Facebook login.")
            } else {
                self.loggedUser =  user
                if user.isNew {
                    NSLog("User signed up and logged in through Facebook!")
                    self.getFacebookDetails()
                } else {
                    NSLog("User logged in through Facebook!")
                    self.goToSuccess()
                }
            }
        
        })
        
    }
    
    func getFacebookDetails(){
        
        FBRequestConnection.startWithGraphPath("/me?fields=name,picture", completionHandler: { (connection, result, error) -> Void in
            if error == nil{
                let myResult = result as Dictionary<String,AnyObject>
                
                self.loggedUser?["name"] = myResult["name"]
                self.loggedUser?["facebookId"] = myResult["id"]
                self.loggedUser?.saveEventually({ (success, error) -> Void in
                    if error == nil{
                        self.searchFacebookFriends()
                    }else{
                        NSLog("%@", error.description)
                    }
                })
                
                let pictureDic = myResult["picture"] as Dictionary<String,AnyObject>
                let dataDic = pictureDic["data"] as Dictionary<String,AnyObject>
                let picString = dataDic["url"] as String
                
                self.getProfilePicture(url: picString)
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
                let resultdict = result as NSDictionary
                let friends = resultdict["data"] as NSArray
                
                for imFriend in friends {
                    self.validateFacebookFriend(imFriend as NSDictionary)
                }
                
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    func validateFacebookFriend(friend:NSDictionary){
        let usersQuery = PFQuery(className: "User")
        usersQuery.whereKey("facebookId", equalTo: friend["id"])
        usersQuery.getFirstObjectInBackgroundWithBlock { (result, error) -> Void in
            if error == nil {
                result.relationForKey("friends").addObject(self.loggedUser!)
                self.loggedUser?.relationForKey("friends").addObject(result)
                result.saveEventually(nil)
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    func loginInstagramDidClose(#token: String) {
        if token.isEmpty == false {
            var query = PFQuery(className:"TokenStorage")
            query.whereKey("accessToken", equalTo:token)
            query.findObjectsInBackgroundWithBlock({ (objects:[AnyObject]!, error) -> Void in
                if error == nil {
                    if objects.count > 0 {
                        let mySessionToken = objects[0]["userSessionToken"] as String
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
        
        loggedUser = PFUser()
        let uuidUSer: CFUUIDRef = CFUUIDCreate(nil)
        let newUsername: CFStringRef = CFUUIDCreateString(nil, uuidUSer)
        
        let uuidPass: CFUUIDRef = CFUUIDCreate(nil)
        let newPassword: CFStringRef = CFUUIDCreateString(nil, uuidPass)
        
        loggedUser?.username = newUsername
        loggedUser?.password = newPassword
        
        loggedUser?.signUpInBackgroundWithBlock {
            (succeeded: Bool!, error: NSError!) -> Void in
            if error == nil {
                // Hooray! Let them use the app now.
                NSLog("Signed up in with Instagram")
                let newTokenStorage = PFObject(className: "TokenStorage")
                newTokenStorage["accessToken"] = token
                newTokenStorage["userSessionToken"] = self.loggedUser?.sessionToken
                newTokenStorage.saveEventually(nil)
                self.getInstagramUserDetails()

            } else {
                NSLog("%@", error.description)
            }
        }
        
        
    }
    
    func signinInstagram(#sessionToken: String){
        
        PFUser.becomeInBackground(sessionToken, block: { (user, error) -> Void in
            if error == nil{
                NSLog("Logged in with Instagram")
                self.loggedUser = user
                self.goToSuccess()
            }else{
                NSLog("%@", error.description)
            }
        })
    }
    
    func getInstagramUserDetails(){
        
        InstagramEngine.sharedEngine().getSelfUserDetailsWithSuccess({ (instaUser : InstagramUser!) -> Void in
            self.loggedUser?["name"] = instaUser.fullName
            self.loggedUser?["instagramId"] = instaUser.Id
            self.getProfilePicture(url: instaUser.profilePictureURL.URLString)
        }, failure: { (error) -> Void in
            NSLog("%@", error.description)
            self.goToSuccess()
        })
    }
    
    
    func getProfilePicture(#url: String)
    {
        Alamofire.request(.GET, url).response({ (request, response, data, error) -> Void in
            
            if error == nil{
                let profilePicFile : PFFile = PFFile(name: "profilePic.jpg", data: data as NSData)
                profilePicFile.saveInBackgroundWithBlock({ (success, error) -> Void in
                    if error == nil{
                        self.loggedUser?["profilePicture"] = profilePicFile
                        self.loggedUser?.saveInBackgroundWithBlock({ (success, error) -> Void in
                            if error == nil {
                                self.goToSuccess()
                            }else{
                                NSLog("%@",error!.description)
                            }
                        })
                    }else{
                        NSLog("%@",error!.description)
                    }
                })
            }
            else{
                NSLog("%@",error!.description)
            }
        })
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "loginInstagramSegue" {
            let destinationNav = segue.destinationViewController as UINavigationController
            let destination = destinationNav.viewControllers[0] as LoginInstagramViewController
            destination.myDelegate = self
        }
    }
    
    func goToSuccess(){
        let newSceneNav = self.storyboard?.instantiateViewControllerWithIdentifier("mainScene") as MainViewController
        newSceneNav.loggedUser = loggedUser
        self.presentViewController(newSceneNav, animated: true, completion: nil)
    }
}
