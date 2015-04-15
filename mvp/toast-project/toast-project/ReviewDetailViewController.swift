//
//  ReviewDetailViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 3/20/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ReviewDetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    var myToast:PFObject?
    var titleString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitle()
    }
    
    private func configureTitle(){
        if titleString != nil{
            titleLabel.text = "Toasts for "+titleString!
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        (self.view as! BackgroundImageView).insertImage(UIImage(named: "discoverBG")!, withOpacity: 0.65)
    }

    //MARK: - Action methods
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "reviewTableViewSegue"{
            let destination = segue.destinationViewController as! ReviewDetailTableViewController
            destination.myToast = myToast
        }
    }
}
