//
//  ToastsViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire

class ToastsViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,PlaceCellDelegate {
    
    var myMood:PFObject?
    var myHashtag:PFObject?
    var myCategory: PFObject?
    var myPlaces:[PFObject]?
    var myFriend:PFObject?
    var currentReviewsTableView:UITableView?
    
    @IBOutlet weak var myBlurBG: UIVisualEffectView!
    @IBOutlet weak var myBG: BackgroundImageView!
    @IBOutlet weak var toastsCollectionView: UICollectionView!
    @IBOutlet weak var moodTitleLabel: UILabel!
    @IBOutlet weak var placeTitleLabel: UILabel!
    @IBOutlet weak var placeCloseButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        configurePlaces()
    }
    
    func configure(){
        myPlaces = []
        toastsCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    func configurePlaces(){
        let placesQuery = PFQuery(className: "Place")
        placesQuery.includeKey("category")
        if myCategory != nil {
            completeQuery(placesQuery, withCategory: myCategory!)
        }else{
            let toastsQuery = PFQuery(className: "Toast")
            if myMood != nil {
                completeQuery(toastsQuery, withMood: myMood!)
            }else if myHashtag != nil{
                completeQuery(toastsQuery, withHashtag: myHashtag!)
            }else{
                completeQuery(toastsQuery, withFriend: myFriend!)
            }
            placesQuery.whereKey("toasts", matchesQuery: toastsQuery)
        }
        
        placesQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                NSLog("Places: %d", result.count)
                self.myPlaces = result as? [PFObject]
                self.toastsCollectionView.reloadData()
            }else{
                NSLog("%@",error.description)
            }
        }
        
        moodTitleLabel.text = getCapitalString(moodTitleLabel.text!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        myBG.insertImage(UIImage(named: "discoverBG")!, withOpacity: 0.65)
    }
    
    func completeQuery(query:PFQuery,withHashtag hashtag: PFObject){
        query.whereKey("hashtags", equalTo: hashtag)
        moodTitleLabel.text = "#" + (myHashtag!["name"] as String)
    }
    
    func completeQuery(query:PFQuery,withMood mood: PFObject){
        query.whereKey("moods", equalTo: mood)
        moodTitleLabel.text = myMood!["name"] as? String
    }
    
    func completeQuery(query:PFQuery,withCategory category: PFObject){
        query.whereKey("category", equalTo: category)
        moodTitleLabel.text = myCategory!["name"] as? String
    }
    
    func completeQuery(query:PFQuery,withFriend friend: PFObject){
        query.whereKey("user", equalTo:friend)
        moodTitleLabel.text = (friend["name"] as String).componentsSeparatedByString(" ")[0] + " likes"
    }
    
    
    //MARK: - CollectionView datasource methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return myPlaces!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("placeCell", forIndexPath: indexPath) as PlaceCell
            cell.myPlace = myPlaces![indexPath.row]
            cell.myDelegate = self
        
            return cell
    }
    
    //MARK: CollectionView delegate methods
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSizeMake(260*CGRectGetWidth(collectionView.bounds)/320, CGRectGetHeight(collectionView.bounds))
        
    }
    
    //MARK: - Action methods
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "placeDetailSegue" {
            let destination = segue.destinationViewController as PlaceDetailViewController
            
            let selectedIndexPath = toastsCollectionView.indexPathsForSelectedItems()[0] as NSIndexPath
            let selectedPlace = myPlaces?[selectedIndexPath.row]
            let selectedCell = toastsCollectionView.cellForItemAtIndexPath(selectedIndexPath) as PlaceCell
            destination.myPlacePicture = selectedCell.myBackgroundView.myImage
            destination.myPlace = selectedPlace
            destination.placeHashtags = selectedCell.hashtagDataSource?.hashtags
            toastsCollectionView.deselectItemAtIndexPath(selectedIndexPath, animated: false)
        }
    }
    
    @IBAction func closeReviewsPressed(sender: AnyObject) {
        if let table = currentReviewsTableView{
            table.setContentOffset(CGPointMake(0, 0), animated: true)
        }
    }
    
    //MARK: - PlaceCell delegate methods
    func placeCellDidScroll(#tableView: UITableView,place: PFObject) {
        currentReviewsTableView = tableView
        let alphaChange = tableView.contentOffset.y/50
        let placeAlphaChange = tableView.contentOffset.y/150
        let newAlpha = min(1,0 + alphaChange)
        let newPlaceAlpha = min(1,0 + placeAlphaChange)
        myBlurBG.alpha = newAlpha
        
        placeTitleLabel.text = getCapitalString(place["name"] as String!)
        placeTitleLabel.alpha = newPlaceAlpha
        placeCloseButton.alpha = newPlaceAlpha
        
        moodTitleLabel.alpha = max(0,1 - newAlpha)
        //changeBrothersAlpha(place: place, alpha: moodTitleLabel.alpha)
        
        if newAlpha >= 1{
            toastsCollectionView.scrollEnabled = false
        }else{
            toastsCollectionView.scrollEnabled = true
        }
    }
    
    func placeCellDidPressed(#place:PFObject) {
        let selectedIndex = find(myPlaces!,place)!
        toastsCollectionView.selectItemAtIndexPath(NSIndexPath(forRow: selectedIndex, inSection: 0), animated: false, scrollPosition: .None)
        self.performSegueWithIdentifier("placeDetailSegue", sender: self)
    }
    
    func placeCellReviewDidPressed(#toast: PFObject,place: PFObject) {
        let destination = self.storyboard?.instantiateViewControllerWithIdentifier("reviewDetailScene") as ReviewDetailViewController
        destination.myToast = toast
        destination.titleString = place["name"] as String!
        self.showViewController(destination, sender: self)
    }
    
    //MARK: - Misc methods
    func getCapitalString(original:String) -> String{
        return prefix(original, 1).capitalizedString + suffix(original, countElements(original) - 1)
    }
}
