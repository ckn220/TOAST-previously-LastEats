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

    @IBOutlet weak var highlightView: UIView!
    @IBOutlet weak var topLinewView: UIView!
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

    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted{
            self.highlightView.alpha = 0.3
        }else{
            self.highlightView.alpha = 0
        }
    }
    
    
    func configure(friend:PFObject,isFirstRow:Bool){
        configureTopLine(!isFirstRow)
        configurePicture(friend)
        configureName(friend)
    }
    
    private func configureTopLine(visible:Bool){
        topLinewView.hidden = !visible
    }
    
    private func configurePicture(friend:PFObject){
        initPicture()
        friendPicture.setImage(user:friend as! PFUser)
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
