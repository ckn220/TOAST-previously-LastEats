//
//  ReviewsTableViewDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 3/18/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import Parse

protocol ReviewDataSourceDelegate {
    func reviewDataSourceDidScroll(contentOffset contentOffset: CGPoint)
    func reviewDataSourceDidEndScrolling(contentOffset contentOffset: CGPoint)
    func reviewDataSourcePlaceDidPressed()
    func reviewDataSourceReviewDidPressed(toast toast:PFObject,parentHeader: UIView)
    func reviewDataSourceReviewerDidPress(user user:PFUser, friend:PFUser?)
    func reviewDataSourceHashtagPressed(name:String)
}

class ReviewsTableViewDataSource: NSObject,UITableViewDataSource,UITableViewDelegate,ReviewCellDelegate,ReviewCellHeaderSource
{
    var myDelegate: ReviewDataSourceDelegate?
    var toasts:[PFObject] = []
    var reviewTableView:UITableView!
    
    init(toasts:[PFObject],delegate:ReviewDataSourceDelegate){
        super.init()
        self.toasts = toasts
        self.myDelegate = delegate
    }
    
    //MARK: - Tableview datasource methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if reviewTableView == nil{
            reviewTableView = tableView
        }
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toasts.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCellWithIdentifier("headerCell")!
            return cell
        }else{
            
            var cellIdentifier:String
            if toasts.count > 1{
                cellIdentifier = "reviewCell"
            }else{
                cellIdentifier = "singleReviewCell"
            }

            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ReviewCell
            let currentToast = toasts[indexPath.row-1]
            cell.configure(currentToast,index:indexPath.row-1,lastIndex: toasts.count-1)
            cell.myDelegate = self
            cell.myHeaderSource = self
            
            return cell
        }
    }
    
    func reviewOffest(tableView tableView:UITableView) -> CGFloat{
        let aspect:Double = 538.0/364.0
        let cellWidth = CGRectGetWidth(tableView.frame)
        return cellWidth/CGFloat(aspect)
    }
    
    //MARK: - Tableview delegate methods
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        //adjustSingleReviewButtons(scrollView.contentOffset.y)
        myDelegate?.reviewDataSourceDidScroll(contentOffset: scrollView.contentOffset)
    }
    
    private func adjustSingleReviewButtons(offsetY:CGFloat){
        if toasts.count == 1{
            let maxOffset = reviewOffest(tableView: reviewTableView)*2/3
            let singleCell = reviewTableView.cellForRowAtIndexPath((NSIndexPath(forRow: 1, inSection: 0))) as! ReviewCell
            let newAlpha = 1 - (( maxOffset - offsetY)/100)
            singleCell.heartButton.alpha = newAlpha
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        myDelegate?.reviewDataSourceDidEndScrolling(contentOffset: scrollView.contentOffset)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.row{
        case 0:
            myDelegate?.reviewDataSourcePlaceDidPressed()
        default:
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! ReviewCell
            let parentHeader = cell.headerView
            
            myDelegate?.reviewDataSourceReviewDidPressed(toast:toasts[indexPath.row - 1], parentHeader: parentHeader)
        }
    }
    
    //MARK: - ReviewCell delegate methods
    func reviewCellReviewerPressed(index: Int,ffriend:PFUser?) {
        let selectedUser = toasts[index]["user"] as! PFUser
        myDelegate?.reviewDataSourceReviewerDidPress(user: selectedUser,friend:ffriend)
    }
    
    func reviewCellHashtagPressed(name: String) {
        myDelegate?.reviewDataSourceHashtagPressed(name)
    }
    
    //MARK: - ReviewCell headersource methods
    func dequeueFriendHeader() -> ReviewHeaderCell {
        return reviewTableView.dequeueReusableCellWithIdentifier("friendHeaderCell") as! ReviewHeaderCell
    }
    
    func dequeueFriendOfFriendHeader() -> ReviewHeaderCell {
        return reviewTableView.dequeueReusableCellWithIdentifier("friendOfFriendHeaderCell") as! ReviewHeaderCell
    }
}
