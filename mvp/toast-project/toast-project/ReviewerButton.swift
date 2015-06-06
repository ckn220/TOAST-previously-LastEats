//
//  ReviewerButton.swift
//  toast-project
//
//  Created by Diego Cruz on 3/20/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Haneke

class ReviewerButton: UIButton {
    
    var imageURL:String!{
        didSet{
            /*self.hnk_setImageFromURL(NSURL(string:imageURL)!, state: UIControlState.Normal, placeholder: nil, format: nil, failure: { (error) -> () in
                NSLog("conigureFriendOfFriendPicture error: %@",error!.description)
                }, success: {(image) -> () in
                    self.setImage(image.imageWithRenderingMode(.AlwaysOriginal), forState: .Normal)
            })*/
            /*let cache = Shared.imageCache
            cache.fetch(URL: NSURL(string:imageURL)!, failure: { (error) -> () in
                NSLog("imageURL didSet error: %@",error!.description)
                }, success: {(image) -> () in
                    self.setImage(image, forState: .Normal)
            })*/
        }
    }
}
