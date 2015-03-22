//
//  ReviewsTableViewDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 3/18/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import Parse

protocol ReviewDataSourceDelegate {
    func reviewDataSourceDidScroll(#contentOffset: CGPoint)
    func reviewDataSourceDidEndScrolling(#contentOffset: CGPoint)
    func reviewDataSourcePlaceDidPressed()
    func reviewDataSourceReviewDidPressed(#toast:PFObject)
}

class ReviewsTableViewDataSource: NSObject,UITableViewDataSource,UITableViewDelegate
{
    var myDelegate: ReviewDataSourceDelegate?
    var toasts:[PFObject] = []
    
    init(toasts:[PFObject],delegate:ReviewDataSourceDelegate){
        super.init()
        self.toasts = toasts
        self.myDelegate = delegate
    }
    
    //MARK: - Tableview datasource methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toasts.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCellWithIdentifier("headerCell") as UITableViewCell
            return cell
        }else{
            let cell = tableView.dequeueReusableCellWithIdentifier("reviewCell") as ReviewCell
            let user = toasts[indexPath.row-1]["user"] as PFUser
            let review = toasts[indexPath.row-1]["review"] as String
            cell.configure(isLastItem: indexPath.row == (toasts.count))
            cell.setUserInfo(user)
            cell.setReview(review)
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.row{
        case 0:
            return reviewOffest(tableView: tableView)
        default:
            return 144
        }
    }
    
    func reviewOffest(#tableView:UITableView) -> CGFloat{
        let aspect:Double = 538.0/364.0
        let cellWidth = CGRectGetWidth(tableView.frame)
        return cellWidth/CGFloat(aspect)
    }
    
    //MARK: - Tableview delegate methods
    func scrollViewDidScroll(scrollView: UIScrollView) {
        myDelegate?.reviewDataSourceDidScroll(contentOffset: scrollView.contentOffset)
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
            myDelegate?.reviewDataSourceReviewDidPressed(toast:toasts[indexPath.row - 1])
        }
    }
}
