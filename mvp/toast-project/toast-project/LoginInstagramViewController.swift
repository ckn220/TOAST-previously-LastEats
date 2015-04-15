//
//  LoginInstagramViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 1/24/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit

protocol LoginInstagramDelegate {
    
    func loginInstagramDidClose(#token: String)

}

class LoginInstagramViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var myWebView: UIWebView!
    var myToken: String?
    var myScope: IKLoginScope?
    var myDelegate: LoginInstagramDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        myScope = IKLoginScope.Relationships | IKLoginScope.Comments | IKLoginScope.Likes
        
        myToken = ""
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let configuration = InstagramEngine.sharedEngineConfiguration()
        let scopeString = InstagramEngine.stringForScope(myScope!)
        
        let stringURL : String = "\(configuration[kInstagramKitAuthorizationUrlConfigurationKey]!)?client_id=\(configuration[kInstagramKitAppClientIdConfigurationKey]!)&redirect_uri=\(configuration[kInstagramKitAppRedirectUrlConfigurationKey]!)&response_type=token&scope=" + scopeString
        let myURL = NSURL(string: stringURL)
        
        myWebView.loadRequest(NSURLRequest(URL: myURL!))
        
        NSLog("%@", stringURL)
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        var cookie:NSHTTPCookie
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        
        if let cookies = storage.cookies {
            
            for cookie in cookies {
                
                if cookie.domain.rangeOfString("instagram.com")?.isEmpty == false {
                    
                    storage.deleteCookie(cookie as! NSHTTPCookie)
                }
                
            }
            
            NSUserDefaults.standardUserDefaults().synchronize()
            
        }
        
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let URLString = request.URL!.absoluteString;
        
        if (URLString?.hasPrefix(InstagramEngine.sharedEngine().appRedirectURL) == true){
            
            let delimiter = "access_token="
            let components = URLString?.componentsSeparatedByString(delimiter)
            
            if components?.count > 1 {
                myToken = components?.last
                NSLog("ACCESS TOKEN = %@",myToken!)
                
                InstagramEngine.sharedEngine().accessToken = myToken!
                myDelegate?.loginInstagramDidClose(token: myToken!)
            }
            
            return false
            
        }
        
        return true
        
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        //UIAlertView(title: "Connection Error", message: error.description, delegate: self, cancelButtonTitle: "OK").show()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closePressed(sender: AnyObject) {
        
        myDelegate?.loginInstagramDidClose(token: myToken!)
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
