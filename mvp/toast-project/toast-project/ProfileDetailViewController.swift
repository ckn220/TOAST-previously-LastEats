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
        configureToasts()
    }
    
    private func configure(){
        myTableView.contentInset = UIEdgeInsetsMake(-40, 0, -30, 0);
    }
    
    private func configureToasts(){
        let query = PFQuery(className: "Toast")
        query.includeKey("place")
        query.whereKey("user", equalTo: myUser)
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.profileDataSource = ProfileToastsDataSource(toasts: result as! [PFObject],user:self.myUser)
            }else{
                NSLog("%@",error.description)
            }
        }
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
