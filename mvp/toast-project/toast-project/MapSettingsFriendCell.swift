//
//  MapSettingsFriendCell.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/18/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class MapSettingsFriendCell: UITableViewCell {

    @IBOutlet weak var profilePictureView:UserProfileImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(user:PFUser){
        configurePicture(user)
        configureName(user)
    }
    
    private func configurePicture(user:PFUser){
        profilePictureView.myImageView.image = nil
        profilePictureView.setImage(user: user)
    }
    
    private func configureName(user:PFUser){
        nameLabel.text = user["name"] as? String
    }

}
