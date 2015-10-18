//
//  ContributeViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/26/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire
import Foundation

class ContributeViewController: UIViewController, iCarouselDataSource, iCarouselDelegate,ToastCarouselViewDelegate,SearchPlaceDelegate {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var myNavBar: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var myCarousel:iCarousel!
    @IBOutlet weak var searchNameContainerView: UIView!
    @IBOutlet weak var goToReviewButton: UIButton!
    @IBOutlet weak var changeNameButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var reviewView: ToastReviewView!
    @IBOutlet weak var reviewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    var isStatusBarHidden = true
    var tempToast = [String:AnyObject]()
    var tempReview:String?
    
    var placeFromActivity:PFObject?
    
    var itemsCount = 2
    let myViews = NSBundle.mainBundle().loadNibNamed("CarouselViews", owner: nil, options: nil)
    var newToast:PFObject?
    let foursquareClientId = "2EDPPGSKXYRS3TIW4TIDKRXEGBNMIVMCC5HF4FAEZEHISGI4"
    let foursquareClientSecret = "H2GC5EERWD3RHBLMSGVEY55TI5JPA5HXZD4MRLO4XILVJ4HB"
    var searchNameController: SearchPlaceViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        myCarousel.type = .Cylinder
        myCarousel.scrollEnabled = false
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        reviewView.myDelegate = self
        
        if placeFromActivity != nil{
            searchNameContainerView.alpha = 0
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reviewTopConstraint.constant = (CGRectGetHeight(self.view.bounds)+20)
        if let place = placeFromActivity{
            let placeId = place["foursquarePlaceId"] as! String
            let name = place["name"] as! String
            searchPlaceIdSelected((placeId: placeId, name: name))
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    private func toggleNavBar(isVisible isVisible:Bool){
        UIView.animateWithDuration(0.15, animations: { () -> Void in
            if isVisible{
                self.titleLabel.alpha = 1
                self.changeNameButton.alpha = 1
                self.submitButton.alpha = 0
            }else{
                self.titleLabel.alpha = 0
                self.changeNameButton.alpha = 0
            }
        })
    }
    
    private func toggleSubmitButton(isVisible isVisible:Bool){
        
        if isVisible && self.submitButton.alpha == 0{
            UIView.animateKeyframesWithDuration(0.3, delay: 0, options: .CalculationModeLinear, animations: { () -> Void in
                
                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5, animations: { () -> Void in
                    self.submitButton.alpha = 1
                    self.changeNameButton.alpha = 0
                    self.submitButton.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1)
                })
                UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: { () -> Void in
                    self.submitButton.layer.transform = CATransform3DMakeScale(1, 1, 1)
                })
                
            }, completion: nil)
        }else if !isVisible && self.submitButton.alpha == 1{
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                self.submitButton.alpha = 0
                self.changeNameButton.alpha = 1
            })
        }        
    }
    
    //MARK: - iCarousel datasource methods
    func numberOfItemsInCarousel(carousel: iCarousel!) -> Int {
        return itemsCount
    }
    
    func carousel(carousel: iCarousel!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
        let imView = myViews[index] as! ToastCarouselView
        imView.myDelegate = self
        imView.setViewValues(index: index)
        imView.frame = CGRectMake(0, 0, 320, itemHeight(forIndex:index))
        
        switch index {
        case 1:
            configureMoodsView(imView as! ToastMoodsView)
        default:
            break
        }
        imView.layoutIfNeeded()
        
        return imView
    }
    
    private func itemHeight(forIndex index:Int) -> CGFloat{
        if index == 2{
            return CGRectGetHeight(myCarousel.bounds)
        }else{
            return 290
        }
    }
    
    func carousel(carousel: iCarousel!, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        switch option{
        case .Arc:
            if itemsCount > 2{
                return 3.14159265359*0.7
            }else{
                return 3.14159265359*0.7*2/3
            }
        case .Spacing:
            return 1.15
        case .Wrap:
            return 0
        case .ShowBackfaces:
            return 0
        case .FadeMin:
            return -0.1
        case .FadeMax:
            return 0.1
        case .FadeRange:
            return 1
        default:
            return value
        }
    }
    
    func configureMoodsView(view:ToastMoodsView){
        PFQuery(className: "Mood").findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil {
                view.insertMoods(result!)
            }else{
                NSLog("%@", error!.description)
            }
        }
    }
    
    //MARK: - ToastCarouselView delegate methods
    func toastCarouselView(indexSelected index: Int, value: AnyObject?) {
        switch index{
        case 0:
            toastNameSelected()
        case 1:
            toastMoodsSelected(value as! [PFObject]!)
        default:
            return
        }
    }
    
    func toastCarouselViewGetTempToast() -> [String : AnyObject] {
        return tempToast
    }
    
    func toastCarouselViewMoodsSelected(moods:[PFObject]) {
        tempToast["moods"] = moods
        
        toggleGoToReview(moods.count > 0)
        toggleReviewItem(moods.count > 0)
    }
    
    private func toggleGoToReview(isVisible:Bool){
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            if isVisible{
                self.goToReviewButton.alpha = 1
            }else{
                self.goToReviewButton.alpha = 0
            }
        })
    }
    
    private func toggleReviewItem(isVisible:Bool){
        if isVisible && itemsCount == 2{
            itemsCount = 3
            myCarousel.insertItemAtIndex(2, animated: true)
        }else if !isVisible && itemsCount == 3{
            if myCarousel.itemViewAtIndex(2) != nil{
                //let reviewView = myCarousel.itemViewAtIndex(2) as! ToastReviewView
                reviewView.toggleFocus(false)
            }
            itemsCount = 2
            myCarousel.removeItemAtIndex(2, animated: true)
        }
    }
    
    func toastNameSelected(){
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("searchPlaceScene") as! SearchPlaceViewController
        destination.myDelegate = self
        self.showDetailViewController(destination, sender: nil)
    }
    
    func toastMoodsSelected(selectedMoods:[AnyObject]){
        tempToast["moods"] = selectedMoods
        scrollToIndex(2,delay:0.1)
    }
    
    func carouselCurrentItemIndexDidChange(carousel: iCarousel!) {
        currentItemChanged(carousel.currentItemIndex)
    }
    
    private func currentItemChanged(index:Int){
        
        if myCarousel.numberOfItems == 3{
            //let reviewView = myCarousel.itemViewAtIndex(2) as! ToastReviewView
            reviewView.toggleFocus(index == 2)
            if index == 2{
                toggleReviewVisibility(0)
                reviewView.moods = tempToast["moods"] as! [PFObject]
            }else{
                toggleReviewVisibility(1)
                restartMoods()
                restartReview()
            }
        }
        
        if index == 0{
            toggleNavBar(isVisible: false)
            toggleReviewItem(false)
            toggleGoToReview(false)
            searchNameContainerView.alpha = 1
            searchNameController.showSearchBar()
        }else{
            toggleNavBar(isVisible: true)
        }
        
        toggleCloseButton(isClose: index != 2)
    }
    
    private func toggleCloseButton(isClose isClose:Bool){
        var closeIcon = "backIcon"
        if isClose{
            closeIcon = "closeIcon"
        }
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.closeButton.setImage(UIImage(named: closeIcon), forState: .Normal)
        })
    }
    
    private func toggleReviewVisibility(hidden:CGFloat){
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.reviewTopConstraint.constant = CGRectGetHeight(self.myCarousel.bounds).advancedBy(20) * hidden
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func restartMoods(){
        if myCarousel.itemViewAtIndex(1) != nil{
            let moodsView = myCarousel.itemViewAtIndex(1) as! ToastMoodsView
            moodsView.restartMoods()
        }
    }
    
    private func restartReview(){
        let reviewTextView = reviewView.reviewTextView
        reviewTextView.text = ""
        reviewView.textViewDidChange(reviewTextView)
        reviewView.togglePlaceHolder(0)
    }
    
    func toastCarouselViewReviewEditing(text: String) {
        if text.utf16.count > 0{
            toggleSubmitButton(isVisible: true)
        }else{
            toggleSubmitButton(isVisible: false)
        }
    }
    
    //MARK: SearchPlace delegate methods
    func searchPlaceIdSelected(placeTemp: (placeId: String, name: String)) {
        tempToast["placeId"] = placeTemp.placeId
        tempToast["placeName"] = placeTemp.name
        titleLabel.text = placeTemp.name
        
       let nameView = myCarousel.itemViewAtIndex(0) as! ToastNameView
        nameView.nameLabel.text = placeTemp.name
        
        UIView.animateKeyframesWithDuration(0.3, delay: 0, options: .CalculationModeLinear, animations: { () -> Void in
            
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5, animations: { () -> Void in
                nameView.nameLabel.alpha = 1
                nameView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1)
            })
            
            UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: { () -> Void in
                nameView.nameLabel.alpha = 1
                nameView.layer.transform = CATransform3DMakeScale(1, 1, 1)
                
            })
        }, completion: nil)
        
        isStatusBarHidden = false
        hideSearchNameView(delay: 0)
        scrollToIndex(1,delay:0.6)
    }
    
    func searchPlaceCancelled() {
        //hideSearchNameView(delay: 0)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func hideSearchNameView(delay delay:NSTimeInterval){
        UIView.animateWithDuration(0.15, delay: delay, options: .CurveLinear, animations: { () -> Void in
            self.searchNameContainerView.alpha = 0
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }
    
    //MARK: ReviewPlace delegate methods
    func reviewPlaceDoneEditing(review review: String?,hashtags:[PFObject]) {
        //let reviewView = myCarousel.itemViewAtIndex(2) as! ToastReviewView
        if let reviewValue = review {
            tempToast["review"] = reviewValue
            reviewView.reviewTextView.text = review
            reviewView.reviewTextView.alpha = 1
        }else{
            reviewView.reviewTextView.text = "Edit text"
            reviewView.reviewTextView.alpha = 0.5
        }
        reviewView.reviewTextView.textColor = UIColor.whiteColor()
        reviewView.reviewTextView.font = UIFont(name: "Avenir-Roman", size: 17)
        
        if hashtags.count > 0{
            tempToast["hashtags"] = hashtags
        }
    }
    
    //MARK: - Misc methods
    func scrollToIndex(index: Int,delay: NSTimeInterval){
        callSelectorAsync(Selector("goTo:"), object: index, delay: delay)
    }
    
    func goTo(timer:NSTimer){
        myCarousel.scrollToItemAtIndex(timer.userInfo as! Int, duration: 0.4)
    }
    
    func callSelectorAsync(selector: Selector, object: AnyObject?, delay: NSTimeInterval) -> NSTimer {
        
        let timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: selector, userInfo: object, repeats: false)
        return timer
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true//isStatusBarHidden
    }
    
    @IBAction func closePressed(sender: UIButton) {
        if myCarousel.currentItemIndex == 2{
            dismissReview({ () -> Void in
                self.myCarousel.scrollToItemAtIndex(1, animated: true)
            })
        }else{
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
    //MARK: - Submit methods
    @IBAction func submitPressed(sender: AnyObject) {
        toggleLoading(true)
        let reviewTextView = reviewView.reviewTextView
        tempToast["review"] = reviewTextView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let tempDic = submitDic(tempToast)
        PFCloud.callFunctionInBackground("submitToast", withParameters: tempDic) { (result, error) -> Void in
            if error == nil{
                self.loadingEnded()
                self.toastSubmitted()
            }else{
                self.showErrorAlert()
            }
        }
    }
    
    private func toggleLoading(visible:Bool){
        if visible{
            submitButton.alpha = 0
            reviewView.reviewTextView.resignFirstResponder()
            reviewView.reviewTextView.editable = false
            
            loadingView.alpha = 1
        }else{
            submitButton.alpha = 1
            reviewView.reviewTextView.becomeFirstResponder()
            reviewView.reviewTextView.editable = true
            
            loadingView.alpha = 0
        }
    }
    
    private func loadingEnded(){
        loadingView.alpha=0
    }
    
    private func submitDic(tempReview:[String:AnyObject]) -> [String:String]{
        var dic = [String:String]()
        dic["review"]=(tempReview["review"] as! String)
        dic["placeFoursquareId"]=(tempReview["placeId"] as! String)
        var moodsString=""
        let moods = tempReview["moods"] as! [PFObject]
        for mood in moods{
            let moodName = mood["name"] as! String
            moodsString = moodsString+moodName+", "
        }
        dic["moodsNames"] = moodsString
        
        return dic
    }
    
    private func toastSubmitted(){
        dismissReview { () -> Void in
            let post = self.storyboard?.instantiateViewControllerWithIdentifier("postContributeScene") as! PostContributeViewController!
            post.transitioningDelegate = post
            post.tempToast = self.tempToast
            self.showDetailViewController(post, sender: self)
        }
    }
    
    private func dismissReview(completion:(()-> Void)?){
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            completion?()
        }
        reviewView.reviewTextView.resignFirstResponder()
        CATransaction.commit()
    }
    
    private func showErrorAlert(){
        let a = UIAlertController(title: "Connection Error", message: "There has been an error retrieving the venue information. Please try again in a moment.", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default) { (action) -> Void in
            self.toggleLoading(false)
        }
        a.addAction(okButton)
        self.showDetailViewController(a, sender: nil)
    }
    
    @IBAction func goToReviewPressed(sender: UIButton) {
        toggleGoToReview(false)
        scrollToIndex(2, delay: 0.1)
    }
    
    @IBAction func changeNamePressed(sender: UIButton) {
        scrollToIndex(0, delay: 0.0)
        currentItemChanged(0)
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "searchNameSegue"{
            return placeFromActivity == nil
        }else{
            return true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "searchNameSegue"{
            searchNameController = segue.destinationViewController as! SearchPlaceViewController
            searchNameController.myDelegate = self
        }
    }

    func keyboardWillShow(sender: NSNotification) {
        if let userInfo = sender.userInfo {
            if let keyboardHeight = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size.height {
                if myCarousel.itemViewAtIndex(2) != nil {
                    //let reviewView = myCarousel.itemViewAtIndex(2) as! ToastReviewView
                    reviewView.keyboargHeight = keyboardHeight
                }
                
            }
        }
    }

}
