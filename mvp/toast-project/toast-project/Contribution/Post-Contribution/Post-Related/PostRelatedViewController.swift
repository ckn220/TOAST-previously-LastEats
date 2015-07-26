//
//  PostRelatedViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 4/5/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol PostRelatedDelegate{
    func postRelatedDidScroll(offset:CGFloat)
}

class PostRelatedViewController: UIViewController, UITableViewDataSource,UITableViewDelegate {

    @IBOutlet weak var topToastView: UIView!
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var relatedPlacesTableView: UITableView!
    
    var relatedPlaces = [PFObject]()
    var myTempToast:[String:AnyObject]!
    var myDelegate:PostRelatedDelegate?
    var topToastHidden = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure(){
        configureTableView()
        configureRestaurant()
        configureYesButton()
    }
    
    private func configureTableView(){
        relatedPlacesTableView.estimatedRowHeight = 200
        relatedPlacesTableView.rowHeight = UITableViewAutomaticDimension
        relatedPlacesTableView.registerNib(UINib(nibName: "RelatedPlacesHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "headerView")
        
        PFCloud.callFunctionInBackground("relatedPlaces", withParameters: ["moods":moodsIdArray()]) { (result, error) -> Void in
            if error == nil{
                self.relatedPlaces = result as! [PFObject]
                self.relatedPlacesTableView.reloadData()
                self.configureTableViewInset()
            }else{
                NSLog("relatedPlaces: %@",error!.description)
            }
        }
    }
    
    private func moodsIdArray()->[String]{
        if let moods = myTempToast["moods"] as? [PFObject]{
            var array=[String]()
            for mood in moods{
                array.append(mood.objectId!)
            }
            
            return array
        }else{
            return []
        }
    }
    
    private func configureTableViewInset(){
        let heightCell = CGRectGetWidth(self.view.bounds)*90/160
        let superHeight = CGRectGetHeight(self.view.bounds) - 64.0
        let diffHeight = -1 * superHeight.distanceTo(CGFloat(relatedPlaces.count) * heightCell)
        
        if diffHeight > 0{
            relatedPlacesTableView.contentInset = UIEdgeInsetsMake(0, 0, diffHeight, 0)
        }
    }
    
    private func configureRestaurant(){
        placeName.text = myTempToast["placeName"] as? String
    }
    
    private func configureYesButton(){
        let buttonLayer = yesButton.layer
        buttonLayer.cornerRadius = 4
        buttonLayer.borderWidth = 1
        buttonLayer.borderColor = UIColor.whiteColor().CGColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if relatedPlaces.count > 0{
            return 2
        }else{
            return 1
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            if topToastHidden{
                return 0
            }else{
                return 1
            }
        case 1:
            return relatedPlaces.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section{
        case 0:
            return tableView.dequeueReusableCellWithIdentifier("firstCell") as! UITableViewCell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("placeCell", forIndexPath: indexPath) as! PostRelatedPlaceCell
            let imPlace = relatedPlaces[indexPath.row]
            cell.configureCell(imPlace)
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier("headerView") as! UITableViewHeaderFooterView!
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section{
        case 0:
            return 0.1
        case 1:
            return 64
        default:
            return 0
        }
    }
    
    //MARK: - TableView delegate methods
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var offset = scrollView.contentOffset.y
        if topToastHidden{
            offset.advancedBy(405)
        }
        
        myDelegate?.postRelatedDidScroll(offset)
        updateTopToastViewAlpha(offset: offset)
        updateRelatedPlacesHeader(offset: offset)
    }
    
    private func updateTopToastViewAlpha(#offset:CGFloat){
        let newAlpha = 1 - (offset/150.0)
        topToastView.alpha = newAlpha
    }
    
    private func updateRelatedPlacesHeader(#offset:CGFloat){
        if let header = relatedPlacesTableView.headerViewForSection(1){
            let headerLabel = header.viewWithTag(101) as! UILabel
            if offset >= 404{
                headerLabel.alpha = 1
            }else{
                headerLabel.alpha = 0.5
            }
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        if !topToastHidden{
            let topHeight:CGFloat = 404.0
            let offset = scrollView.contentOffset.y
            if offset < topHeight{
                if offset > 3*topHeight/4.0 {
                    scrollView.setContentOffset(CGPointMake(0, 0), animated: true)
                }else if offset > topHeight/4.0 {
                    scrollView.setContentOffset(CGPointMake(0, topHeight), animated: true)
                }else{
                    scrollView.setContentOffset(CGPointMake(0, 0), animated: true)
                }
            }
        }
    }
    
    //MARK: - Actions methods
    @IBAction func topToastPressed(sender: AnyObject) {
        setTopToast()
    }
    
    private func setTopToast(){
        PFCloud.callFunctionInBackground("setLastTopToast", withParameters: nil) { (result, error) -> Void in
            if error == nil{
                self.changeToDone()
            }else{
                NSLog("%@",error!.description)
            }
        }
    }
    
    private func changeToDone(){
        
        UIView.animateWithDuration(0.3, delay: 0.2, options: .CurveEaseInOut, animations: { () -> Void in
            
            self.yesButton.setTitle("Done", forState: .Normal)
            let doneColor = UIColor(red:0.313, green:0.89, blue:0.76, alpha:1)
            self.yesButton.setTitleColor(doneColor, forState: .Normal)
            
            self.yesButton.layer.borderColor = UIColor.clearColor().CGColor
            
        }) { (completed) -> Void in
            self.hideTopToastView()
        }
    }
    
    private func hideTopToastView(){
        
        delay(0.8, closure: { () -> () in
            self.relatedPlacesTableView.beginUpdates()
            self.topToastHidden = true
            self.relatedPlacesTableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Top)
            self.relatedPlacesTableView.endUpdates()
        })
        
        UIView.animateWithDuration(0.2, delay: 0.8, options: .CurveEaseInOut, animations: { () -> Void in
            
            self.myDelegate?.postRelatedDidScroll(1000)
            self.updateTopToastViewAlpha(offset: 1000)
            self.updateRelatedPlacesHeader(offset: 1000)
            
        }) { (completed) -> Void in
            
        }
    }
    
    //MARK: - Misc methods
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
}
