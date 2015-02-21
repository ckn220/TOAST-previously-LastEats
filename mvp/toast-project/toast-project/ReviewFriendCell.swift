//
//  ReviewFriendCell.swift
//  toast-project
//
//  Created by Diego Cruz on 2/8/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ReviewFriendCell: CustomUICollectionViewCell {
    
    @IBOutlet weak var favoriteButton:UIButton!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var friendPictureView: UIImageView!
    
    override func configureForItem(item:AnyObject) {
        
        let myUser = (item as PFObject)["user"] as PFObject
        myUser.fetchIfNeededInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                
            }else{
                NSLog("%@", error.description)
            }
            let pictureFile = (result as PFObject)["profilePicture"] as PFFile
            pictureFile.getDataInBackgroundWithBlock { (data, error) -> Void in
                if error == nil{
                    self.friendPictureView.image = UIImage(data: data)
                    self.friendPictureView.layer.cornerRadius = CGRectGetWidth(self.friendPictureView.bounds)/2
                }else{
                    NSLog("%@", error.description)
                }
                
                let firstName = (myUser["name"] as String).componentsSeparatedByString(" ")[0]
                self.friendNameLabel.text = firstName
            }
        }
        
        
    }
}
