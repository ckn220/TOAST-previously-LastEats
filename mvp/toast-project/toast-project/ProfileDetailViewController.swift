//
//  ProfileDetailViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 3/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ProfileDetailViewController: UIViewController {

    @IBOutlet weak var myTableView: UITableView!
    
    @IBOutlet weak var userPictureView: BackgroundImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var toastCountLabel: UILabel!
    @IBOutlet weak var friendsCountLabel: UILabel!
    @IBOutlet weak var followersCountLabel: UILabel!
    
    var myUser:PFUser!
    var profileDataSource:ProfileToastsDataSource!{
        didSet{
            myTableView.dataSource = profileDataSource
            myTableView.delegate = profileDataSource
            myTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure(){
        myTableView.contentInset = UIEdgeInsetsMake(-40, 0, -30, 0);
        configureUserHeader()
        loadTopToast()
    }
    
    private func loadTopToast(){
        if let topToast = myUser["topToast"] as? PFObject{
            topToast.fetchIfNeededInBackgroundWithBlock { (result, error) -> Void in
                if error == nil{
                    self.configureToasts(topToast: result)
                }else{
                    NSLog("%@",error.description)
                    self.configureToasts(topToast: nil)
                }
            }
        }else{
            self.configureToasts(topToast: nil)
        }
        
    }
    
    private func configureToasts(#topToast:PFObject?){
        let query = PFQuery(className: "Toast")
        query.includeKey("place")
        query.whereKey("user", equalTo: myUser)
        query.orderByDescending("createdAt")
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.profileDataSource = ProfileToastsDataSource(toasts: result as! [PFObject],user:self.myUser,topToast:topToast)
            }else{
                NSLog("%@",error.description)
            }
        }
    }
    
    private func configureUserHeader(){
        configureProfileImage(myUser)
        configureProfileName(myUser)
        configureCountLabels(myUser)
    }
    
    private func configureProfileImage(user:PFUser){
        let pictureFile = user["profilePicture"] as! PFFile
        pictureFile.getDataInBackgroundWithBlock { (result, error) -> Void in
            self.userPictureView.myImage = UIImage(data: result as NSData)
        }
    }
    
    private func configureProfileName(user:PFUser){
        userNameLabel.text = user["name"] as! String!
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
                self.toastCountLabel.text = String(format: "%2d", result as! Int)
            }else{
                NSLog("%@", error.description);
            }
        }
        
    }
    
    private func configureFriendCount(user:PFUser){
        configureCountLabel(friendsCountLabel)
    }
    
    private func configureFollowerCount(user:PFUser){
        configureCountLabel(followersCountLabel)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Action methods
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
}
