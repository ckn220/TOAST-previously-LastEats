//
//  HashtagCell.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class HashtagCell: CustomUICollectionViewCell {
    
    @IBOutlet weak var hashtagLabel: UILabel!
    
    override func configureForItem(item:AnyObject) {
        let imHashTag = item as PFObject
        self.hashtagLabel.text = "#"+(imHashTag["name"] as? String)!
        //self.hashtagLabel.sizeToFit()
    }
}
