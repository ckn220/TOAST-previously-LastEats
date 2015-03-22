//
//  DiscoverDataSource.swift
//  toast-project
//
//  Created by Diego Cruz on 3/21/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol DiscoverDataSourceDelegate{
    func moodsDataSourceItemSelected(#index:Int)
    func neighborhoodsDataSourceItemSelected(#index:Int)
}

class DiscoverDataSource: NSObject,iCarouselDataSource,iCarouselDelegate,DiscoverCellDelegate{
    var myItems:[PFObject] = []
    var myDelegate:DiscoverDataSourceDelegate?
    var isMood:Bool = true
    
    init(items:[PFObject],myDelegate:DiscoverDataSourceDelegate,isMood:Bool){
        super.init()
        self.myItems=items
        self.myDelegate=myDelegate
        self.isMood = isMood
    }
    
    func numberOfItemsInCarousel(carousel: iCarousel!) -> Int {
        return myItems.count
    }
    
    func carousel(carousel: iCarousel!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
        
        var cell:DiscoverCell
        if view == nil {
            cell = NSBundle.mainBundle().loadNibNamed("DiscoverCell", owner: nil, options: nil)[0] as DiscoverCell
            cell.frame = CGRectMake(0, 0, 167, 44)
        }else{
            cell = view as DiscoverCell
        }
        cell.configureItem(myItems[index], isMood: isMood,myDelegate:self,index:index)
        cell.isCurrent = carousel.currentItemIndex == index
        return cell
    }
    
    func carousel(carousel: iCarousel!, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        switch option{
        case .Arc:
            return value * 0.3
        case .Spacing:
            return value * 1.1
        case .Wrap:
            return 1
        case .ShowBackfaces:
            return 0
        case .FadeMin:
            return -1
        case .FadeMax:
            return 1
        case .FadeRange:
            return 4
        default:
            return value
        }
    }
    
    func carouselCurrentItemIndexDidChange(carousel: iCarousel!) {
        let currentItem = carousel.currentItemView as DiscoverCell
        for item in carousel.visibleItemViews as [DiscoverCell]{
            item.isCurrent = item.isEqual(currentItem)
        }
    }
    
    //MARK: - DiscoverCell delegate methods
    func discoverCellSelected(#index: Int) {
        if isMood{
            myDelegate?.moodsDataSourceItemSelected(index: index)
        }else{
            myDelegate?.neighborhoodsDataSourceItemSelected(index: index)
        }
    }
}
