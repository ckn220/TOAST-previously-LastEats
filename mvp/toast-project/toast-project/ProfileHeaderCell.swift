//
//  ProfileHeaderCell.swift
//  toast-project
//
//  Created by Diego Cruz on 3/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ProfileHeaderCell: UITableViewCell {

    @IBOutlet weak var profileImageView: BackgroundImageView!
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var toastCountLabel: UILabel!
    @IBOutlet weak var friendCountLabel: UILabel!
    @IBOutlet weak var followerCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(user:PFUser){
        configure()
        configureProfileImage(user)
        configureProfileName(user)
        configureCountLabels(user)
    }
    
    private func configure(){
        
    }
    
    private func configureProfileImage(user:PFUser){
        let pictureFile = user["profilePicture"] as! PFFile
        pictureFile.getDataInBackgroundWithBlock { (result, error) -> Void in
            self.profileImageView.myImage = UIImage(data: result as NSData)
        }
    }
    
    private func configureProfileName(user:PFUser){
        profileNameLabel.text = user["name"] as! String!
    }
    
    private func configureCountLabels(user:PFUser){
        configureToastCount(user)
        configureFriendCount(user)
        configureFollowerCount(user)
    }
    
    private func configureCountLabel(label:UILabel){
        let layer = label.layer
        layer.cornerRadius = CGRectGetWidth(label.bounds)/2
        layer.borderWidth = 1
        layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    private func configureToastCount(user:PFUser){
        configureCountLabel(toastCountLabel)
        
        PFCloud.callFunctionInBackground("toastCount", withParameters: ["userId":user.objectId]) { (result, error) -> Void in
            if error == nil{
                self.toastCountLabel.text = String(format: "%02d", result as! Int)
            }else{
                NSLog("%@", error.description);
            }
        }
        
    }
    
    private func configureFriendCount(user:PFUser){
        configureCountLabel(friendCountLabel)
    }
    
    private func configureFollowerCount(user:PFUser){
        configureCountLabel(followerCountLabel)
    }

}
