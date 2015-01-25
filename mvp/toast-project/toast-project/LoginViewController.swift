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

    @IBOutlet weak var myTimeLabel: UILabel!
    @IBOutlet weak var myWeatherLabel: UILabel!
    @IBOutlet weak var myLastLabel: UILabel!
    
    var myDateFormatter : NSDateFormatter?
    
    
    var myWeather:(temperature:Int,state:Int,date:NSDate)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myDateFormatter = NSDateFormatter()
        myDateFormatter!.dateStyle = .ShortStyle
        
        PFUser.logOut()
        
        // Do any additional setup after loading the view.
        /*manager.delegate = self
        
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            manager.requestWhenInUseAuthorization()
        }
        */
        
        Alamofire.request(.GET, "http://api.openweathermap.org/data/2.5/weather?q=new,york,city&APPID=1cec9211c792bf8f901772d017c9ff5b")
            .responseJSON { (imRequest, imResponse, JSON, error) in
                
                if error == nil{
                    
                    let days = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
                    let times = ["early morning","late morning","early afternoon","late afternoon","night"]
                    
                    println()
                    var result = JSON as NSDictionary
                    
                    var temp = result["main"]!["temp"] as Int
                    
                    self.myWeather = (temp,result["cod"] as Int,NSDate())
                    
                    let myTimeInfo = self.getTimeInfo()
                    
                    self.myTimeLabel.text = "It's " + days[myTimeInfo.day-1] + " " + times[(myTimeInfo.time*4)/24]
                    
                    UIView.animateWithDuration(0.6, animations: { () -> Void in
                        self.myTimeLabel.alpha = 1
                        }, completion: { (completion) -> Void in
                            
                            UIView.animateWithDuration(0.6, delay: 0.4, options: .CurveLinear, animations: { () -> Void in
                                self.myLastLabel.alpha = 1
                                }, completion: nil)
                    })
                    
                }
                else{
                    let a = UIAlertView(title: "Open Weather Error", message: error?.description, delegate: self, cancelButtonTitle: "OK")
                    a.show()
                }
                
        }
        
    }

    func getTimeInfo() -> (day:Int,time:Int){
        
        let myCalendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        let myWeekDay = myCalendar?.components(NSCalendarUnit.CalendarUnitWeekday | NSCalendarUnit.CalendarUnitHour, fromDate: NSDate())
        return (myWeekDay!.weekday,myWeekDay!.hour)
   
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    
    @IBAction func facebookDidPressed(sender: UIButton) {
        
        PFFacebookUtils.logInWithPermissions(["public_profile","email"], block: { (imUser : PFUser!, imError : NSError!) -> Void in
            
            if imUser == nil {
                
                let a = UIAlertView(title: "Sign in failed", message: imError?.localizedFailureReason, delegate: nil, cancelButtonTitle: "OK")
                a.show()
                
                NSLog("%@", imError.description)
                
            }
            else if imUser.isNew == true {
                
                NSLog("User signed up and logged in through Facebook!")
                
                FBRequestConnection.startWithGraphPath("/me?fields=name,gender,picture,email", completionHandler: { (connection, result, error) -> Void in
                    
                    if (error == nil){
                        let imUser : PFUser = PFUser.currentUser()
                        let myResult = result as Dictionary<String,AnyObject>
                        //let stringBirthday = myResult["birthday"] as String
                        
                        imUser["name"] = myResult["name"]
                        //imUser["birth"] = self.myDateFormatter?.dateFromString(stringBirthday)
                        var userGender : Int
                        switch (myResult["gender"] as String) {
                        case "male":
                            userGender = 0
                        default:
                            userGender = 1
                        }
                        imUser["gender"] = userGender
                        
                        let pictureDic = myResult["picture"] as Dictionary<String,AnyObject>
                        let dataDic = myResult["data"] as Dictionary<String,AnyObject>
                        
                        let picString = dataDic["url"] as String
                        var myError : NSError?
                        
                        let picData = NSData(contentsOfURL: NSURL(string: picString)!, options: nil, error: &myError)
                        
                        if myError == nil {
                            let profilePicFile : PFFile = PFFile(name: "profilePic.jpg", data: picData)
                            profilePicFile.saveInBackgroundWithBlock({ (succeed, error) -> Void in
                                
                                if error == nil{
                                    imUser["profilePicture"]=profilePicFile
                                    imUser.saveEventually()
                                }
                                
                            })
                        }
                        
                        imUser.saveEventually()
                        self.goToSuccess(isFB: true)
                    }
                    
                    NSLog("%@", error.description)
                    
                })
                
                
            
            } else{
                
                NSLog("User logged in through Facebook!");
                
                self.goToSuccess(isFB: true)
            }
            
        })
        
    }
    
    func loginInstagramDidClose(#token: String) {
        if token.isEmpty == false {
            PFUser.becomeInBackground(token, block: { (user:PFUser!, error) -> Void in
                
                if error == nil {
                    
                    if user.isNew == true {
                        
                        InstagramEngine.sharedEngine().getSelfUserDetailsWithSuccess({ (instaUser) -> Void in
                            
                            let imUser:InstagramUser = instaUser as InstagramUser
                            
                            user["name"] = imUser.fullName
                            
                            Alamofire.request(.GET, imUser.profilePictureURL.URLString).response({ (request, response, data, error) -> Void in
                                
                                if error == nil {
                                    let profilePicFile : PFFile = PFFile(name: "profilePic.jpg", data: data as NSData)
                                    profilePicFile.saveInBackgroundWithBlock({ (succeed, error) -> Void in
                                        
                                        if error == nil{
                                            user["profilePicture"]=profilePicFile
                                            user.saveEventually()
                                        }
                                        
                                    })
                                }
                                
                            })
                            
                        }, failure: { (error) -> Void in
                            NSLog("%@", error.description)
                        })
                        
                    }
                    
                    self.goToSuccess(isFB: false)
                }
                else{
                    UIAlertView(title: "Instagram login failed", message: error.description, delegate: self, cancelButtonTitle: "OK").show()
                }
                
            })
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    /*
    // MARK: - Core Location
    func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    }
    */
    
    
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
    
    
    
    
    func goToSuccess(#isFB: Bool){
        let newSceneNav = self.storyboard?.instantiateViewControllerWithIdentifier("loginSuccessNavScene") as UINavigationController
        let newScene = newSceneNav.viewControllers[0] as LoginSuccesViewController
        
        newScene.isFB = isFB
        
        self.presentViewController(newSceneNav, animated: true, completion: nil)
        
    }
    
}
