//
//  DeliveryWebViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/14/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class GenericWebViewController: UIViewController {
    
    @IBOutlet weak var myWebView:UIWebView?
    var myURL:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        myWebView?.loadRequest(NSURLRequest(URL: NSURL(string: myURL!)!))
    }
    
    //MARK: Action methods
    @IBAction func closePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
