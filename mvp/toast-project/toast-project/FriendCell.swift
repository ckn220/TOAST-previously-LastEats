//
//  FriendCell.swift
//  toast-project
//
//  Created by Diego Cruz on 5/7/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Haneke

class FriendCell: UITableViewCell {

    @IBOutlet weak var friendPicture: BackgroundImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(friend:PFObject){
        configurePicture(friend)
        configureName(friend)
    }
    
    private func configurePicture(friend:PFObject){
        initPicture()
        let pictureURL = friend["pictureURL"] as! String
        let cache = Shared.imageCache
        cache.fetch(URL: NSURL(string:pictureURL)!, failure: { (error) -> () in
            NSLog("configurePicture error: %@",error!.description)
            }, success: {(image) -> () in
                self.friendPicture.myImage = image
        })
    }
    
    private func initPicture(){
        let pictureLayer = friendPicture.layer
        pictureLayer.borderWidth = 1
        pictureLayer.borderColor = UIColor.whiteColor().CGColor
        pictureLayer.cornerRadius = CGRectGetWidth(pictureLayer.bounds)/2
    }
    
    private func configureName(friend:PFObject){
        friendNameLabel.text = friend["name"] as? String
    }
}
