//
//  Discover1ViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class Discover1ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    
    
    var moods:[PFObject]?

    @IBOutlet weak var moodsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moods = []
        moodsTableView.estimatedRowHeight = 50
        moodsTableView.rowHeight = UITableViewAutomaticDimension
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let moodsQuery = PFQuery(className: "Mood")
        moodsQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.moods = result as? [PFObject]
                self.moodsTableView.reloadData()
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    

    //MARK: Tableview methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return moods!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        if indexPath.row == 0{
            cell = tableView.dequeueReusableCellWithIdentifier("moodsHeaderCell") as MoodsHeaderTableViewCell
            (cell as MoodsHeaderTableViewCell).friendsLikeCollectionView.reloadData()
        }else{
            cell = tableView.dequeueReusableCellWithIdentifier("moodCell") as UITableViewCell
            let currentMood = moods![indexPath.row]
            cell.textLabel?.text = (currentMood["name"] as? String)?.uppercaseString
        }
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("hungryCell") as UITableViewCell

        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    //MARK: Scrollview delegate methods
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var headerCell:MoodsHeaderTableViewCell? = moodsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? MoodsHeaderTableViewCell
        
        if headerCell != nil{
            let friendsLikeCollection = headerCell!.friendsLikeCollectionView
            let scrollY = scrollView.contentOffset.y
            
            friendsLikeCollection.alpha = 1 - scrollY/80
        }
        
    }
    
    //MARK: Collectionview methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("friendsLikeCell", forIndexPath: indexPath) as FriendsLikeCollectionViewCell
        cell.friendPictureView.layer.cornerRadius = 70/2
        cell.friendCountView.layer.cornerRadius = 28/2
        
        return cell
    }
    
    
    //MARK: Action methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "moodDetailSegue"{
            let selectedIndexPath = moodsTableView.indexPathForSelectedRow()
            let selectedMood = moods![selectedIndexPath!.row]
            
            let destination = segue.destinationViewController as ToastsViewController
            destination.myMood = selectedMood
        }
        
    }
}
