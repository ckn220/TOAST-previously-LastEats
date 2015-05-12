//
//  ReviewDetailViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 3/20/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

class ReviewDetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var userPictureView: BackgroundImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var reviewLinkView: CCHLinkTextView!
    @IBOutlet weak var heartButton: HeartButton!
    @IBOutlet weak var followButton: FollowButton!
    
    var myToast:PFObject?
    var titleString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    //MARK: - Configure methods
    private func configure(){
        configureTitle()
        configureUser()
        configureReview()
        configureActions()
    }
    
    private func configureTitle(){
        if titleString != nil{
            titleLabel.text = "Toasts for "+titleString!
        }
    }
    
    //MARK: Configure user methods
    private func configureUser(){
        let user = myToast!["user"] as! PFUser
        configureUserPicture(user)
        configureUserName(user)
    }
    
    private func configureUserPicture(user:PFUser){
        initUserPicture()
        let pictureURL = user["pictureURL"] as! String
        let cache = Shared.imageCache
        
        cache.fetch(URL: NSURL(string:pictureURL)!, failure: { (error) -> () in
            NSLog("configureUserPicture error: \(error!.description)")
            }, success: {(image) -> () in
                self.userPictureView.myImage = image
        })
    }
    
    private func initUserPicture(){
        let layer = userPictureView.layer
        layer.cornerRadius = CGRectGetWidth(layer.frame)/2
        layer.borderColor = UIColor(white: 1, alpha: 0.7).CGColor
        layer.borderWidth = 1.0
    }
    
    private func configureUserName(user:PFUser){
        let name = user["name"] as! String
        userNameLabel.text = name
    }
    
    //MARK: Configure review methods
    private func configureReview(){
        initLinkView(reviewLinkView)
        let review = myToast!["review"] as! String
        var words = review.componentsSeparatedByString(" ")
        var finalReview = NSMutableAttributedString(string: "")
        for word in words{
            finalReview.appendAttributedString(attributedWord(word))
            finalReview.appendAttributedString(attributedWord(" "))
        }
        reviewLinkView.attributedText = finalReview
        reviewLinkView.layoutIfNeeded()
    }
    
    private func initLinkView(view:CCHLinkTextView){
        view.linkTextAttributes = [NSForegroundColorAttributeName:UIColor(hue:0.555, saturation:0.45, brightness:1, alpha:1)]
        view.linkTextTouchAttributes = [NSForegroundColorAttributeName:UIColor(hue:0.555, saturation:0.45, brightness:0.7, alpha:1),NSBackgroundColorAttributeName:UIColor.clearColor()]
    }
    
    private func attributedWord(word:String)->NSAttributedString{
        if let hashIndex = find(word,"#"){
            return attributedHashtag(word)
        }else{
            return attributedNormal(word)
        }
    }
    
    private func attributedNormal(word:String)->NSAttributedString{
        return NSAttributedString(string: word, attributes: myAttributes())
    }
    
    private func attributedHashtag(hashtag:String)->NSAttributedString{
        var attr = myAttributes()
        attr[CCHLinkAttributeName] = 0
        return NSAttributedString(string: hashtag, attributes: attr)
    }
    
    private func myAttributes() -> [NSObject:AnyObject]{
        var attributes = [NSObject:AnyObject]()
        attributes[NSFontAttributeName] = UIFont(name: "Avenir-Medium", size: 16)
        attributes[NSForegroundColorAttributeName] = UIColor.whiteColor()
        return attributes
    }
    
    //MARK: Configure actions methods
    private func configureActions(){
        getUserActions(toast: myToast!, completion: { (actions) -> Void in
            self.heartButton.isOn = actions[0] as! Bool
            self.followButton.isOn = actions[1] as! Bool
        })
    }

    private func getUserActions(#toast:PFObject,completion:(actions:NSArray) -> Void){
        let cache = Cache<NSArray>(name:"userActions")
        cache.fetch(key: toast.objectId, failure: { (error) -> () in
            self.requestUserActions(toast: toast, completion: completion)
            }, success: { (actions) -> () in
                completion(actions: actions)
        })
    }
    
    private func requestUserActions(#toast:PFObject,completion:(actions:NSArray) -> Void){
        PFCloud.callFunctionInBackground("userActionsForToast", withParameters: ["toastId":toast.objectId]) { (result, error) -> Void in
            if error == nil{
                let actions = result as! NSArray
                self.saveActions(actions,toast:toast)
                completion(actions: actions)
            }else{
                NSLog("requestUserActions error: %@", error.description)
                let errorActions = [0,0]
                completion(actions: errorActions)
            }
        }
    }
    
    private func saveActions(actions:NSArray,toast:PFObject){
        let cache = Cache<NSArray>(name:"userActions")
        cache.set(value: actions, key: toast.objectId, success: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let cache = Cache<UIImage>(name: "neighborhoods")
        cache.fetch(key: "default", failure: { (error) -> () in
            NSLog("viewWillAppear error: %@",error!.description)
            }, success: {(image) -> () in
                let myBG = self.view as! BackgroundImageView
                myBG.insertImage(image, withOpacity: 0.65)
        })
    }

    //MARK: - Action methods
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func heartButtonPressed(sender: HeartButton) {
        var heartFunction = "heartToast"
        if !sender.isOn{
            heartFunction = "unheartToast"
        }
        
        PFCloud.callFunctionInBackground(heartFunction, withParameters: ["toastId":myToast!.objectId]) { (result, error) -> Void in
            if error != nil{
                NSLog("%@",error.description)
            }
        }
    }
    
    @IBAction func followButtonPressed(sender: FollowButton) {
        var followFunction = "followUser"
        if !sender.isOn{
            followFunction = "unfollowUser"
        }
        
        let user = (myToast!["user"] as! PFUser).objectId
        PFCloud.callFunctionInBackground(followFunction, withParameters: ["userId":user]) { (result, error) -> Void in
            if error != nil{
                NSLog("%@",error.description)
            }
        }
    }
}
