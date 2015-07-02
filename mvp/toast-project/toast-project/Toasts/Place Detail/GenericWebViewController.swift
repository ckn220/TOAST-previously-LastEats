//
//  DeliveryWebViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/14/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

class GenericWebViewController: UIViewController,UIWebViewDelegate {
    
    @IBOutlet weak var myWebView:UIWebView?
    @IBOutlet weak var myLoadingView: UIView!
    var myURL:String?
    var tempTitle:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configure()
    }
    
    private func configure(){
        let loadingLayer = myLoadingView.layer
        loadingLayer.transform = CATransform3DMakeScale(0.95, 0.95, 1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //configure()
        myWebView?.loadRequest(NSURLRequest(URL: NSURL(string: myURL!)!))
    }
    
    //MARK: Action methods
    @IBAction func closePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - WebView delegate methods
    func webViewDidStartLoad(webView: UIWebView) {
        title = "Loading..."
        toggleLoadingView(true)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        title = tempTitle
        toggleLoadingView(false)
    }
    
    private func toggleLoadingView(visible:Bool){
        UIView.animateWithDuration(0.3, delay: 0.1, options: .CurveEaseOut, animations: { () -> Void in
            let loadingLayer = self.myLoadingView.layer
            if visible{
                loadingLayer.opacity = 1
            }else{
                loadingLayer.opacity = 0
            }
        }, completion: nil)
        
        UIView.animateWithDuration(0.07, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
            let loadingLayer = self.myLoadingView.layer
            if visible{
                loadingLayer.transform = CATransform3DMakeScale(1, 1, 1)
            }else{
                loadingLayer.transform = CATransform3DMakeScale(0.95, 0.95, 1)
            }
        }, completion: nil)
    }
}
