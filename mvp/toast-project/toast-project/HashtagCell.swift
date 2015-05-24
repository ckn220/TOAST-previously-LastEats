//
//  HashtagCell.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class HashtagCell: UICollectionViewCell {
    
    @IBOutlet weak var hashtagLabel: UILabel!
    
    func configure(#item:PFObject,index:Int) {
        configureLabel(item: item,index:index)
        //insertSmallShadow(self.hashtagLabel)
    }
    
    func configureLabel(#item:PFObject,index:Int){
        hashtagLabel.text = "#"+(item["name"] as? String)!
        if index%2==0{
            hashtagLabel.textAlignment = .Left
        }else{
            hashtagLabel.textAlignment = .Right
        }
    }
    
    func insertSmallShadow(view:UIView){
        let layer = view.layer
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 3.0
        layer.shadowOpacity = 1.0
        layer.shouldRasterize = true
    }
}
