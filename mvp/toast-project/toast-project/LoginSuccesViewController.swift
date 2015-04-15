//
//  LoginSuccesViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 1/23/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class LoginSuccesViewController: UIViewController {

    @IBOutlet weak var loadingPictureView: UIActivityIndicatorView!
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var profilePicView: UIImageView!
    var isFB:Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if isFB == true {
            self.view.backgroundColor = UIColor(red: 0.229, green: 0.466, blue: 0.815, alpha: 1)
        }
        else{
            self.view.backgroundColor = UIColor(red: 0.699, green: 0.797, blue: 0.85, alpha: 1)
        }
        
        if PFUser.currentUser() != nil {
            
            if let name = PFUser.currentUser()["name"] as? String{
                
                profileNameLabel.text = "Welcome, " + name
                
            }
            
            
            
            if PFUser.currentUser()["profilePicture"] != nil {
                let userImageFile = PFUser.currentUser()["profilePicture"] as! PFFile
                userImageFile.getDataInBackgroundWithBlock {
                    (imageData: NSData!, error: NSError!) -> Void in
                    if error == nil {
                        let image = UIImage(data:imageData)
                        self.profilePicView.image = image
                    }
                }
            }else {
                
                loadingPictureView.alpha = 0
                
            }
    
            
        }
        
    }

    @IBAction func closePressed(sender: AnyObject) {
        PFUser.logOut()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
