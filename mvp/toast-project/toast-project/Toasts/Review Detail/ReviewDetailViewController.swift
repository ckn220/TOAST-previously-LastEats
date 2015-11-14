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
import CCHLinkTextView

class ReviewDetailViewController: UIViewController,CCHLinkTextViewDelegate,ReviewHeaderDelegate {

    //MARK: - Properties
    //MARK: IBOutlets
    //Top Bar
    @IBOutlet weak var titleLabel: UILabel!
    //Header
    @IBOutlet weak var headerParentView: UIView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    //Body
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reviewLinkView: CCHLinkTextView!
    //Actions
    //Bottom Info
    @IBOutlet weak var heartButton: HeartButton!
    @IBOutlet weak var heartCountView: LikeCountView!
    
    //MARK: Variables
    //Top Bar
    var titleString: String?
    //Header
    var myOldParentHeader:UIView?
    //General
    var myToast:PFObject?{
        didSet{
            if let myToast = myToast,
                let place = myToast["place"] as? PFObject{
                    place.fetchIfNeededInBackgroundWithBlock({ (place, error) -> Void in
                        if let error = error{
                            NSLog("setPlace error: %@",error.description)
                        }else{
                            self.myPlace = place
                        }
                    })
            }
        }
    }
    var myPlace:PFObject?
    let headerQueue = NSOperationQueue()
    var isTopToast:Bool{
        get{
            if let myToast = myToast,let isTopToast = myToast["isTopToast"] as? Bool where isTopToast{
                return true
            }else{
                return false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    //MARK: - Configure methods
    private func configure(){
        configureTopBar()
        configureHeader()
        configureBody()
        configureActions()
    }
    
    //MARK: TopBar
    private func configureTopBar(){
        configureTitle()
    }
    
    private func configureTitle(){
        if let toast = myToast,
            let place = toast["place"] as? PFObject,
            let name = place["name"] as? String{
            titleLabel.text = "Toasts for \(name)"
        }
    }
    
    //MARK: Header
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
        /*if let ffHeader = header as? FriendOfFriendHeaderCell{
            ffHeader.subtitleHeightConstraint.constant = 34
        }else{
            _ = header as! FriendHeaderCell
        }*/
        header.layoutIfNeeded()
    }
    
    private func requestHeaders(){
        headerQueue.addOperationWithBlock { () -> Void in
            let user = self.myToast!["user"] as! PFUser
            PFCloud.callFunctionInBackground("friendOfFriend", withParameters: ["reviewerId":user.objectId!]) { (result, error) -> Void in
                if error == nil{
                    if let friend = result as? PFUser{
                        self.configureFriendOfFriendHeader(friend:friend,friendOfFriend: user)
                    }else{
                        self.configureFriendHeader(friend:user)
                    }
                }else{
                    NSLog("friendOfFriend error: %@",error!.description)
                }
                self.loadingView.alpha = 0
            }
        }
        
    }
    
    private func configureFriendHeader(friend friend:PFUser){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            friend.fetchIfNeededInBackgroundWithBlock({ (friend, error) -> Void in
                if let error = error{
                    NSLog("configureFriendHeader error: %@",error.description)
                }else{
                    let header = self.getFriendHeaderView()
                    header.configure(friend: friend as! PFUser,myDelegate:self,superView:self.headerParentView,isTopToast: self.isTopToast)
                    header.frame = self.headerParentView.bounds
                    self.headerParentView.addSubview(header)
                }
            })
        }
    }
    
    private func configureFriendOfFriendHeader(friend friend:PFUser,friendOfFriend:PFUser){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            friend.fetchIfNeededInBackgroundWithBlock({ (friend, error) -> Void in
                if let error = error{
                    NSLog("configureFriendOfFriendHeader error: %@",error.description)
                }else{
                    let header = self.getFriendOfFriendHeaderView()
                    header.configure(friend: friend as! PFUser, friendFriend: friendOfFriend,myDelegate:self,superView:self.headerParentView, isTopToast: self.isTopToast)
                    header.frame = self.headerParentView.bounds
                    self.headerParentView.addSubview(header)
                }
            })
            
        }
    }
    
    private func getFriendHeaderView() -> ReviewHeaderCell{
        return NSBundle.mainBundle().loadNibNamed("ReviewDetailHeaders", owner: nil, options: nil)[0] as! ReviewHeaderCell
    }
    
    private func getFriendOfFriendHeaderView() -> ReviewHeaderCell{
        return NSBundle.mainBundle().loadNibNamed("ReviewDetailHeaders", owner: nil, options: nil)[1] as! ReviewHeaderCell
    }
    
    //MARK: Body
    private func configureBody(){
        configureReview()
    }
    
    private func configureReview(){
        initLinkView(reviewLinkView)
        let review = myToast!["review"] as! String
        let words = review.componentsSeparatedByString(" ")
        let finalReview = NSMutableAttributedString(string: "")
        for word in words{
            finalReview.appendAttributedString(attributedWord(word))
            finalReview.appendAttributedString(attributedWord(" "))
        }
        reviewLinkView.attributedText = finalReview
        textViewHeightConstraint.constant = heightForText(reviewLinkView)
        reviewLinkView.scrollEnabled = false
    }
    
    private func heightForText(textview:CCHLinkTextView) -> CGFloat{
        let newSize = textview.sizeThatFits(CGSizeMake(CGRectGetWidth(view.bounds), 100000))
        return newSize.height.advancedBy(22)
    }
    
    private func initLinkView(view:CCHLinkTextView){
        view.linkDelegate = self
        view.linkTextAttributes = [NSForegroundColorAttributeName:UIColor(hue:0.555, saturation:0.45, brightness:1, alpha:1)]
        view.linkTextTouchAttributes = [NSForegroundColorAttributeName:UIColor(hue:0.555, saturation:0.45, brightness:0.7, alpha:1),NSBackgroundColorAttributeName:UIColor.clearColor()]
    }
    
    private func attributedWord(word:String)->NSAttributedString{
        if let _ = word.characters.indexOf("#"){
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
    
    private func myAttributes() -> [String:AnyObject]{
        var attributes = [String:AnyObject]()
        attributes[NSFontAttributeName] = UIFont(name: "Avenir-Medium", size: 16)
        attributes[NSForegroundColorAttributeName] = UIColor.whiteColor()
        return attributes
    }
    
    //MARK: Actions
    private func configureActions(){
        requestHasHeart(toast: myToast!, completion: { (hasHeart) -> Void in
                self.heartButton.isOn = hasHeart
        })
        setHeartCount(forItem: myToast!)
    }
    
    private func requestHasHeart(toast toast:PFObject,completion:(hasHeart:Bool) -> Void){
        let heartsQuery = PFUser.currentUser()!.relationForKey("hearts").query()!
        heartsQuery.whereKey("objectId", equalTo: myToast!.objectId!)
        heartsQuery.countObjectsInBackgroundWithBlock { (count, error) -> Void in
            if error == nil{
                completion(hasHeart: count == 1)
            }else{
                NSLog("requestHasHeart error: %@",error!.description)
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
                NSLog("setHeartCount error:%@",error!.description)
            }
        }
    }
    
    
    //MARK: - ViewWillAppear methods
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setBG()
        setHeader()
    }
    
    private func setBG(){
        let myBG = self.view as! BackgroundImageView
        myBG.setImage(fileName:"default", opacity: 0.6)
    }
    
    private func setHeader(){
        if myOldParentHeader != nil{
            let myHeaderView = myOldParentHeader!.subviews[0]
            myHeaderView.frame = headerParentView.bounds
            headerParentView.addSubview(myHeaderView)
        }
        
    }
    
    //MARK: - ViewWillDisappear methods
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsetHeader()
    }
    
    private func unsetHeader(){
        if myOldParentHeader != nil{
            let myHeaderView = headerParentView.subviews[1]
            /*if let ffHeader = myHeaderView as? FriendOfFriendHeaderCell{
                ffHeader.subtitleHeightConstraint.constant = 17
            }else{
                _ = myHeaderView as! FriendHeaderCell
            }*/
            myHeaderView.layoutIfNeeded()
            myHeaderView.removeFromSuperview()
            myHeaderView.frame = myOldParentHeader!.bounds
            myOldParentHeader!.addSubview(myHeaderView)
        }
        
    }

    //MARK: - Action methods
    //MARK: Segue
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "placeDetailSegue"{
            return myPlace != nil
        }else{
            return true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController as! PlaceDetailViewController
        destination.myPlace = myPlace
    }
    
    //MARK: Back
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //MARK: Heart
    @IBAction func heartButtonPressed(sender: HeartButton) {
        var heartFunction:String
        if sender.isOn{
            heartFunction = "heartToast"
            heartCountView.count++
        }else{
            heartFunction = "unheartToast"
            heartCountView.count--
        }
        
        PFCloud.callFunctionInBackground(heartFunction, withParameters: ["toastId":myToast!.objectId!]) { (result, error) -> Void in
            if error != nil{
                NSLog("%@",error!.description)
            }
        }
    }
    //MARK: User
    @IBAction func headerPressed(sender: MyControl) {
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("profileDetailScene") as! ProfileDetailViewController
        destination.myUser = myToast!["user"] as! PFUser
        destination.fromMap = true
        self.showViewController(destination, sender: self)
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
    
    //MARK: - DEV only methods
    @IBAction func devFunPressed(sender: AnyObject) {
        devSetMood(functionName: "setFunMood")
    }
    
    @IBAction func devCasualPressed(sender: AnyObject) {
        devSetMood(functionName: "setCasualMood")
    }
    
    @IBAction func devBoozyPressed(sender: AnyObject) {
        devSetMood(functionName: "setBoozyMood")
    }
    
    private func devSetMood(functionName name:String){
        func parameters()->[String:String]{
            return ["toastId":myToast!.objectId!]
        }
        
        func showError(){
            let a = UIAlertController(title: "Server error", message: "Sorry for the inconvenience, please try again in a moment.", preferredStyle: .Alert)
            let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
            a.addAction(okButton)
            presentViewController(a, animated: true, completion: nil)
        }
        //
        PFCloud.callFunctionInBackground(name, withParameters: parameters()) { (result, error) -> Void in
            if let error = error{
                NSLog("devSetMood with name [\(name)] error: %@]",error.description)
                showError()
            }else{
                NSLog("devSetMood ok")
            }
        }
    }
}
