//
//  ToastTableViewCell.swift
//  toast-project
//
//  Created by Diego Cruz on 1/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class ToastTableViewCell: UITableViewCell {

    @IBOutlet weak var hashtagsLabel: UILabel!
    @IBOutlet weak var qualitiesLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
