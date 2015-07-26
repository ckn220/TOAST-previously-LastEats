//
//  PostRelatedPlaceCell.swift
//  toast-project
//
//  Created by Diego Cruz on 4/5/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire

class PostRelatedPlaceCell: UITableViewCell {

    @IBOutlet weak var hashtagsCollectionView: UICollectionView!
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var placeImageView: BackgroundImageView!
    
    var hashtagDataSource:HashtagCollectionViewDataSource!{
        didSet{
            hashtagsCollectionView.dataSource = hashtagDataSource
            hashtagsCollectionView.delegate = hashtagDataSource
            hashtagsCollectionView.reloadData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //MARK: - Configure cell methods
    func configureCell(place:PFObject){
        configurePlaceImage(place)
        configurePlaceName(place)
        configureHashtags(place)
    }
    
    private func configurePlaceImage(place:PFObject){
        let photos = place["photos"] as! NSArray
        if photos.count > 0{
            let imageURL = photos[0] as! String
            placeImageView.setImage(URL: imageURL)
        }
    }
    
    private func configurePlaceName(place:PFObject){
        placeNameLabel.text = place["name"] as! String!
        insertShadow(placeNameLabel)
    }
    
    private func configureHashtags(place:PFObject){
        
        PFCloud.callFunctionInBackground("placeTopHashtags", withParameters: ["placeId":place.objectId!,"limit":10]) { (result, error) -> Void in
            if error == nil{
                self.hashtagDataSource = HashtagCollectionViewDataSource(hashtags: result as! [PFObject], myDelegate: nil)
            }else{
                NSLog("%@", error!.description)
            }
        }
    }
    
    //MARK: - Misc methods
    private func insertShadow(view:UIView){
        
        let layer = view.layer
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 8.0
        layer.shadowOpacity = 0.9
        layer.shouldRasterize = true
    }

}
