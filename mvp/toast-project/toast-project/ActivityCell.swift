//
//  ActivityCell.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/15/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

protocol ActivityCellDelegate{
    func cachedPlace(activity:PFObject) -> PFObject?
    func savePlaceInCache(place:PFObject,activity:PFObject)
    //
    func cachedFriend(activity:PFObject) -> FriendCache?
    func saveFriendInCache(friend:PFUser?,activity:PFObject)
}

class ActivityCell: UITableViewCell {

    //MARK: - Properties
    //MARK: IBOutlets
    //Header
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var userImageView: UserProfileImageView!
    @IBOutlet weak var friendImageView: UserProfileImageView!
    @IBOutlet weak var friendImageViewWidthConstraint: NSLayoutConstraint!
    //
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerSubtitleLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    //Body
    @IBOutlet weak var bodyView: UIView!
    @IBOutlet weak var placeImageView: BackgroundImageView!
    @IBOutlet weak var bodyTItleLabel: UILabel!
    @IBOutlet weak var bodySubtitleLabel: UILabel!
    @IBOutlet weak var topToastView: TopToastView!
    @IBOutlet weak var paragraphLabel: UILabel!
    //Bottom
    @IBOutlet weak var activityCountLabel: UILabel!
    @IBOutlet weak var addAToastControl: MyControl!
    //MARK: Variables
    var myDelegate:ActivityCellDelegate?
    weak var activity:PFObject!{
        didSet{
            let action = activity["action"] as! PFObject
            actionName = action["name"] as! String
        }
    }
    var friend:PFUser?
    weak var place:PFObject?
    var actionName:String!
    
    //MARK: - Configure methods
    func configure(activity:PFObject,myDelegate:ActivityCellDelegate?=nil){
        self.activity = activity
        self.myDelegate = myDelegate
        configureHeader()
        configureBody()
    }
    
    //MARK: Header
    private func configureHeader(){
        getFriendOfFriend { (friend) -> () in
            self.headerView.alpha = 1
            self.friend = friend
            self.configureHeaderImages()
            self.configureHeaderTitles()
            self.configureTimeStamp()
        }
    }
    
    private func getFriendOfFriend(completion:(friend:PFUser?)->()){
        if let cachedFriendFriend = myDelegate?.cachedFriend(activity){
            completion(friend: cachedFriendFriend.friend)
        }else{
            headerView.alpha = 0
            let user = activity["user"] as! PFUser
            PFCloud.callFunctionInBackground("friendOfFriend", withParameters: ["reviewerId":user.objectId!]) { (result, error) -> Void in
                if let error = error{
                    NSLog("getFriendOfFriend error: %@",error.description)
                }else{
                    self.myDelegate?.saveFriendInCache(result as? PFUser, activity: self.activity)
                    completion(friend: result as? PFUser)
                }
            }
        }
    }
    
    private func configureHeaderImages(){
        configureUserImage()
        configureFriendImage()
    }
    
    private func configureHeaderTitles(){
        configureTitle()
        configureSubtitle()
    }
    
    //Images
    private func configureUserImage(){
        let user = activity["user"] as! PFUser
        userImageView.setImage(user: user)
    }
    
    private func configureFriendImage(){
        if let friend = friend{
            friendImageViewWidthConstraint.constant = 28
            friendImageView.setImage(user: friend)
        }else{
            friendImageViewWidthConstraint.constant = 0
        }
    }
    
    //Title-Subtitle
    private func configureTitle(){
        let user = activity["user"] as! PFUser
        headerTitleLabel.text = user["name"] as? String
    }
    
    private func configureSubtitle(){
        func date(forUser user:PFUser) -> String{
            let calendar = NSCalendar.currentCalendar()
            let date = user.createdAt
            let components = calendar.components([.Month,.Year], fromDate: date!)
            let months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
            
            return "\(months[components.month]) \(components.year)"
        }
        
        func correctedName(name:String) -> String{
            let originalCount = name.characters.count
            let limit = 14
            if originalCount > limit{
                var words = name.componentsSeparatedByString(" ")
                let newLastName = (words[1] as NSString).substringToIndex(1)
                return "\(words[0]) \(newLastName)."
            }else{
                return name
            }
        }
        
        var subtitleString:String
        let user = activity["user"] as! PFUser
        if user.objectId == PFUser.currentUser()!.objectId{ // Current User
            subtitleString = "Toasting since \(date(forUser: user))"
        }else if user.objectId == "Ljr4MlYQP0"{ // Colin
            subtitleString = "Founder of Top Toast Labs"
        }else{
            if friend != nil{ //Friend of friend
                let friendName = friend!["name"] as! String
                subtitleString = "Friends with \(correctedName(friendName)) on Facebook"
            }else{ //Friend
                let name = user["name"] as! String
                let nameComponents = name.componentsSeparatedByString(" ")
                subtitleString = "You are friends with \(nameComponents[0]) on Facebook"
            }
        }
        
        headerSubtitleLabel.text = subtitleString
    }
    
    //Timestamp
    private func configureTimeStamp(){
        func timeDifference() -> NSTimeInterval{
            let activityDate = activity.updatedAt!
            return -1 * activityDate.timeIntervalSinceNow
        }
        
        func format(time:NSTimeInterval) -> (value:String,unit:String){
            let minNumber:Double = 60
            let hourNumber:Double = 60*minNumber
            let dayNumber:Double = 24*hourNumber
            let monthNumber:Double = 30*dayNumber
            let yearNumber:Double = 12*monthNumber
            var value=""
            var unit=""
            
            /*if time/yearNumber >= 1{
                value = "\(Int(time/yearNumber))"
                unit = "yrs"
            }else if time/monthNumber >= 1{
                value = "\(Int(time/monthNumber))"
                unit = "months"
            }*/
            if time/monthNumber >= 1{
                value = "over 30"
                unit = "days"
            }else if time/dayNumber >= 1{
                value = "\(Int(time/dayNumber))"
                unit = "days"
            }else if time/hourNumber >= 1{
                value = "\(Int(time/hourNumber))"
                unit = "hrs"
            }else if time/minNumber >= 1{
                value = "\(Int(time/minNumber))"
                unit = "min "
            }else{
                value = "just now"
            }
            
            if value == "1"{
                value = "about a"
                unit = (unit as NSString).substringToIndex(unit.characters.count - 1)
            }
            
            return (value.uppercaseString,unit.uppercaseString)
        }
        
        let timeStamp = format(timeDifference())
        timestampLabel.text = "\(timeStamp.value) \(timeStamp.unit)"
    }
    
    //MARK: Body
    private func configureBody(){
        
        func getPlace(completion:()->()){
            if let place = myDelegate?.cachedPlace(activity){
                self.place = place
                completion()
            }else{
                if let toast = activity["toastDest"] as? PFObject, let place = toast["place"] as? PFObject{
                    place.fetchIfNeededInBackgroundWithBlock { (result, error) -> Void in
                        if let error = error{
                            NSLog("configureBody error: %@",error.description)
                        }else{
                            if let place = result{
                                self.place = place
                                self.myDelegate?.savePlaceInCache(place, activity: self.activity)
                            }
                        }
                        completion()
                    }
                }else{
                    NSLog("configureBody error")
                    completion()
                }
            }
        }
        
        bodyView.alpha = 0
        activityCountLabel.alpha = 0
        getPlace { () -> () in
            self.configureBottom()
            switch self.actionName{
            case "adds":
                self.configureToastsContent()
            case "hearts":
                self.configureLikesContent()
            case "topToasts":
                self.configureTopToastsContent()
            default:
                break
            }
        }
    }
    
    private func configureToastsContent(){
        configurePlaceImage()
        configureContentTitleLabel()
    }
    
    private func configureTopToastsContent(){
        configurePlaceImage()
        configureContentTitleLabel()
    }
    
    private func configureLikesContent(){
        configureContentTitleLabel()
        configureContentLikeSubtitleLabel()
        configureContentParagraphLabel()
    }
    
    //Place
    private func configurePlaceImage(){
        if let place = place,let photos = place["photos"] as? [String]{
            let photo = photos[0]
            placeImageView.setImage(URL: photo, opacity: 0.2, completion: { () -> Void in
                self.bodyView.alpha = 1
            })
        }
    }
    
    //Content
    private func configureContentTitleLabel(){
        if let place = place{
            bodyTItleLabel.text = place["name"] as? String
        }
    }
    
    private func configureContentLikeSubtitleLabel(){
        if let toast = activity["toastDest"] as? PFObject{
            (toast["user"] as? PFObject)?.fetchIfNeededInBackgroundWithBlock({ (user, error) -> Void in
                if let error = error{
                    NSLog("configureContentLikeSubtitleLabel error: %@",error.description)
                }else{
                    let name = user!["name"] as! String
                    let words = name.componentsSeparatedByString(" ")
                    self.bodySubtitleLabel.text = "Likes \(words[0])'s toast"
                }
            })
        }
    }
    
    private func configureContentParagraphLabel(){
        if let toast = activity["toastDest"] as? PFObject, let review = toast["review"] as? String{
            bodyView.alpha = 1
            paragraphLabel.text = "\"\(review)\""
        }
    }
    
    //MARK: Bottom
    private func configureBottom(){
        configureActivityCount()
    }
    
    //Activity Count
    private func configureActivityCount(){
        switch actionName{
            case "hearts":
            configureLikeCount()
        default:
            configureToastCount()
        }
    }
    
    private func configureToastCount(){
        place?.relationForKey("toasts").query()?.countObjectsInBackgroundWithBlock({ (toastCount, error) -> Void in
            if let error = error{
                NSLog("configureToastCount error: %@",error.description)
            }else{
                var sufix = "Toasts"
                if toastCount == 1{
                    sufix = "Toast"
                }
                self.activityCountLabel.text = "\(toastCount) \(sufix)"
                self.activityCountLabel.alpha = 1
            }
        })
    }
    
    private func configureLikeCount(){
        let toast = activity["toastDest"] as! PFObject
        let likesCount = toast["heartsCount"] as! Int
        var sufix = "Likes"
        if likesCount == 1{
            sufix = "Like"
        }
        activityCountLabel.text = "\(likesCount) \(sufix)"
        activityCountLabel.alpha = 1
    }
    
    //MARK: - Action methods
    //MARK: Header
    @IBAction func userTapped(sender: BackgroundImageView) {
        let user = activity["user"] as! PFUser
        var userInfo = [String:AnyObject]()
        userInfo["user"] = user
        if let friend = friend{
            userInfo["friend"] = friend
        }
        NSNotificationCenter.defaultCenter().postNotificationName("ActivityUserTapped", object: self, userInfo: userInfo)
    }
    
    //MARK: Body
    @IBAction func placeTapped(sender: BackgroundImageView) {
        let toast = activity["toastDest"] as! PFObject
        NSNotificationCenter.defaultCenter().postNotificationName("ActivityPlaceTapped", object: self, userInfo: ["toast":toast])
    }
    
    //MARK: Bottom
    @IBAction func toastCountControl(sender: MyControl) {
        if let place = place{
            NSNotificationCenter.defaultCenter().postNotificationName("ActivityToastCountTapped", object: self, userInfo: ["place":place])
        }
    }
    
    @IBAction func likeCountTapped(sender: MyControl) {
        let toast = activity["toastDev"] as! PFObject
        NSNotificationCenter.defaultCenter().postNotificationName("ActivityLikeCountTapped", object: self, userInfo: ["toast":toast])
    }
    
    @IBAction func addAToastControl(sender: MyControl) {
        if let place = place{
            NSNotificationCenter.defaultCenter().postNotificationName("ActivityAddAToastTapped", object: self, userInfo: ["place":place])
        }
    }
}
