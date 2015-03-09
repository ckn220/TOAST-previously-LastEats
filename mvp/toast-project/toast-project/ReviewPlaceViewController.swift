//
//  ReviewPlaceViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/28/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol ReviewPlaceDelegate {
    func reviewPlaceDoneEditing(#review:String?)
}

class ReviewPlaceViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {

    var hashtags:[PFObject] = []
    var selectedHashtags:[PFObject] = []
    var myDelegate:ReviewPlaceDelegate?
    @IBOutlet weak var reviewTextView: UITextView!
    @IBOutlet weak var hashtagsCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reviewTextView.becomeFirstResponder()
    }
    
    //MARK - CollectionView methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashtags.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("hashtagCell", forIndexPath: indexPath) as UICollectionViewCell
        let currentHashtag = hashtags[indexPath.row]
        (cell.viewWithTag(101) as UILabel).text = "#" + (currentHashtag["name"] as String)
        if contains(selectedHashtags, currentHashtag){
            cell.alpha = 0.3
        }else{
            cell.alpha = 1
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let selectedCell = collectionView.cellForItemAtIndexPath(collectionView.indexPathsForSelectedItems()[0] as NSIndexPath) as UICollectionViewCell!
        reviewTextView.text = reviewTextView.text + " " + (selectedCell.viewWithTag(101) as UILabel).text!
        selectedCell.alpha = 0.3
        
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }

    //MARK: - Misc methods
    @IBAction func donePressed(sender: UIButton) {
        if reviewTextView.text.isEmpty {
            myDelegate?.reviewPlaceDoneEditing(review: nil)
        }else{
           myDelegate?.reviewPlaceDoneEditing(review: reviewTextView.text)
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        reviewTextView.resignFirstResponder()
        CATransaction.commit()
        
        
    }

}
