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

class ReviewDetailViewController: UIViewController,CCHLinkTextViewDelegate,ReviewHeaderDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var reviewLinkView: CCHLinkTextView!
    @IBOutlet weak var heartButton: HeartButton!
    @IBOutlet weak var heartCountView: LikeCountView!
    @IBOutlet weak var headerParentView: UIView!
    
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    var myOldParentHeader:UIView?
    var myToast:PFObject?
    var titleString: String?
    let headerQueue = NSOperationQueue()
    var isTopToast = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    //MARK: - Configure methods
    private func configure(){
        configureTitle()
        configureHeader()
        configureReview()
        configureActionButtons()
    }
    
    private func configureTitle(){
        if titleString != nil{
            titleLabel.text = "Toasts for "+titleString!
        }
    }
    
    //MARK: Configure user methods
    private func configureHeader(){
        if myOldParentHeader != nil{
            let myHeaderView = myOldParentHeader!.subviews[0] as! ReviewHeaderCell
            setHeaderToDetail(myHeaderView)
            loadingView.alpha = 0
        }else{
            requestHeaders()
        }
    }
    
    private func setHeaderToDetail(header:ReviewHeaderCell){
        if let ffHeader = header as? FriendOfFriendHeaderCell{
            ffHeader.subtitleHeightConstraint.constant = 34
        }else{
            let fHeader = header as! FriendHeaderCell
        }
        header.layoutIfNeeded()
    }
    
    private func requestHeaders(){
        headerQueue.addOperationWithBlock { () -> Void in
            let user = self.myToast!["user"] as! PFUser
            PFCloud.callFunctionInBackground("friendOfFriend", withParameters: ["reviewerId":user.objectId]) { (result, error) -> Void in
                if error == nil{
                    if let friend = result as? PFUser{
                        self.configureFriendOfFriendHeader(friend:friend,friendOfFriend: user)
                    }else{
                        self.configureFriendHeader(friend:user)
                    }
                }else{
                    NSLog("friendOfFriend error: %@",error.description)
                }
                
            }
        }
        
    }
    
    private func configureFriendHeader(#friend:PFUser){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            let header = self.getFriendHeaderView()
            header.configure(friend: friend,myDelegate:self,superView:self.headerParentView,isTopToast: self.isTopToast)
            self.headerParentView.addSubview(header)
        }
    }
    
    private func configureFriendOfFriendHeader(#friend:PFUser,friendOfFriend:PFUser){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            let header = self.getFriendOfFriendHeaderView()
            header.configure(friend: friend, friendFriend: friendOfFriend,myDelegate:self,superView:self.headerParentView, isTopToast: self.isTopToast)
            self.headerParentView.addSubview(header)
        }
    }
    
    private func getFriendHeaderView() -> ReviewHeaderCell{
        return NSBundle.mainBundle().loadNibNamed("ReviewDetailHeaders", owner: nil, options: nil)[0] as! ReviewHeaderCell
    }
    
    private func getFriendOfFriendHeaderView() -> ReviewHeaderCell{
        return NSBundle.mainBundle().loadNibNamed("ReviewDetailHeaders", owner: nil, options: nil)[1] as! ReviewHeaderCell
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
        reviewLinkView.scrollEnabled = false
        reviewLinkView.layoutIfNeeded()
    }
    
    private func initLinkView(view:CCHLinkTextView){
        view.linkDelegate = self
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
        attr[CCHLinkAttributeName] = hashtag.componentsSeparatedByString("#")[1]
        return NSAttributedString(string: hashtag, attributes: attr)
    }
    
    private func myAttributes() -> [NSObject:AnyObject]{
        var attributes = [NSObject:AnyObject]()
        attributes[NSFontAttributeName] = UIFont(name: "Avenir-Medium", size: 16)
        attributes[NSForegroundColorAttributeName] = UIColor.whiteColor()
        return attributes
    }
    
    //MARK: Configure actions methods
    private func configureActionButtons(){
        requestHasHeart(toast: myToast!, completion: { (hasHeart) -> Void in
                self.heartButton.isOn = hasHeart
        })
        setHeartCount(forItem: myToast!)
    }
    
    private func requestHasHeart(#toast:PFObject,completion:(hasHeart:Bool) -> Void){
        let heartsQuery = PFUser.currentUser().relationForKey("hearts").query()
        heartsQuery.whereKey("objectId", equalTo: myToast!.objectId)
        heartsQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                completion(hasHeart: count == 1)
            }else{
                NSLog("requestHasHeart error: %@",error.description)
            }
        }
    }
    
    private func setHeartCount(forItem item:PFObject){
        let userQuery = PFQuery(className: "_User")
        userQuery.whereKey("hearts", equalTo: item)
        userQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                self.heartCountView.count = Int(count)
            }else{
                NSLog("setHeartCount error:%@",error.description)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setBG()
        setHeader()
    }
    
    private func setBG(){
        let myBG = self.view as! BackgroundImageView
        myBG.setImage("default", opacity: 0.6)
    }
    
    private func setHeader(){
        if myOldParentHeader != nil{
            let myHeaderView = myOldParentHeader!.subviews[0] as? UIView
            myHeaderView?.frame = headerParentView.bounds
            headerParentView.addSubview(myHeaderView!)
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsetHeader()
    }
    
    private func unsetHeader(){
        if myOldParentHeader != nil{
            let myHeaderView = headerParentView.subviews[1] as? UIView
            if let ffHeader = myHeaderView as? FriendOfFriendHeaderCell{
                ffHeader.subtitleHeightConstraint.constant = 17
            }else{
                let fHeader = myHeaderView as! FriendHeaderCell
            }
            myHeaderView!.layoutIfNeeded()
            myHeaderView!.removeFromSuperview()
            myHeaderView!.frame = myOldParentHeader!.bounds
            myOldParentHeader!.addSubview(myHeaderView!)
        }
        
    }

    //MARK: - Action methods
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func heartButtonPressed(sender: HeartButton) {
        var heartFunction:String
        if sender.isOn{
            heartFunction = "heartToast"
            heartCountView.count++
        }else{
            heartFunction = "unheartToast"
            heartCountView.count--
        }
        
        PFCloud.callFunctionInBackground(heartFunction, withParameters: ["toastId":myToast!.objectId]) { (result, error) -> Void in
            if error != nil{
                NSLog("%@",error.description)
            }
        }
    }
    
    //MARK: - LinkTextView delegate methods
    func linkTextView(linkTextView: CCHLinkTextView!, didTapLinkWithValue value: AnyObject!) {
        let rawHashtag = value as! String
        let cleanedHashtag = HashtagsManager.cleanHashtag(rawHashtag)
        
        let destination = storyboard?.instantiateViewControllerWithIdentifier("toastsScene") as! ToastsViewController
        destination.myHashtagName = cleanedHashtag
        self.showViewController(destination, sender: self)
    }
    
    //MARK: - ReviewHeader delegate methods
    func friendPicturePressed(ffriend: PFUser?) {
        
    }
    
    func reviewHeaderDoneLoading() {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.loadingView.alpha = 0
        }
    }
}
