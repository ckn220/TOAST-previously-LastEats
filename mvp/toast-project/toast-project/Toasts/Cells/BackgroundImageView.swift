//
//  BackgroundImageView.swift
//  toast-project
//
//  Created by Diego Cruz on 2/12/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import AVFoundation
import Haneke
import Parse
import Alamofire

class BackgroundImageView: UIControl {

    //MARK: - Properties
    var myOpaqueView:UIView!
    var myImageView:UIImageView!
    var myOpacity:CGFloat = 0.0
    let cache = Cache<UIImage>(name: "fbProfilePictures")
    
    //MARK: - setImage from file methods
    func setImage(fileName name:String,opacity:CGFloat = 0.0){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            self.delay(0.2, closure: { () -> () in
                UIView.transitionWithView(self.myImageView, duration: 0.4, options: .TransitionCrossDissolve, animations: { () -> Void in
                    let imgPath = NSBundle.mainBundle().pathForResource(self.correctedName(name,scale: UIScreen.mainScreen().scale), ofType: "jpg")
                    self.myImageView.hnk_setImageFromFile(imgPath!,format:Format<UIImage>(name: "original"), failure: { (error) -> () in
                        NSLog("setImageName error: %@",error!.description)
                        self.setImage(fileName: "default", opacity: opacity)
                        }, success: nil)
                    self.myOpaqueView.alpha = opacity
                    }, completion: nil)
            })            
        }
    }
    
    //MARK: - setImage from URL methods
    func setImage(URL url:String,opacity:CGFloat = 0.0,completion:(()->Void)? = nil){
        myImageView.hnk_setImageFromURL(NSURL(string:url)!,format:Format<UIImage>(name: "original"), failure: { (error) -> () in
            NSLog("setImageURL error: %@",error!.description)
            }, success: {(image)-> () in
                self.myImageView.image = image
                completion?()
        })
        myOpaqueView.alpha = opacity
    }
    
    //MARK: - setImage from PFUser methods
    func setImage(user user:PFUser,completion:(()->())? = nil){
        func setImageAndComplete(facebookId facebookId:String,image:UIImage?){
            if let image = image{
                self.cache.set(value: image, key: facebookId)
            }
            self.myImageView.image = image
            completion?()
        }
        
        if let facebookId = user["facebookId"] as? String{
            cache.fetch(key: facebookId).onSuccess({ (image) -> () in
                setImageAndComplete(facebookId: facebookId,image: image)
            }).onFailure({ (error) -> () in
                self.pictureFromFBGraph(facebookId, completion: { (image) -> () in
                    setImageAndComplete(facebookId: facebookId,image: image)
                })
            })
        }
    }
    
    private func pictureFromFBGraph(facebookId:String,completion:(image:UIImage?)->()){
        let pictureURL = "https://graph.facebook.com/\(facebookId)/picture?type=large&redirect=false"
        Alamofire.request(.GET, pictureURL).responseJSON(completionHandler: { (response) -> Void in
            let result = response.result
            if let error = result.error{
                NSLog("setImage error: %@", error.description)
            }else{
                let json = result.value as! [String:AnyObject]
                if let data = json["data"] as? [String:AnyObject],
                    let url = data["url"] as? String{
                    self.profilePicture(url, completion: { (image) -> () in
                        completion(image: image)
                    })
                }else{
                    completion(image: nil)
                }
            }
        })
    }
    
    private func profilePicture(url:String,completion:(image:UIImage?)->()){
        Alamofire.request(.GET, url).responseData { (response) -> Void in
            let result = response.result
            if let error = result.error{
                NSLog("profilePicture error: %@",error.description)
            }else{
                if let data = result.value,
                    let image = UIImage(data: data){
                        completion(image: image)
                }else{
                    completion(image:nil)
                }
            }
        }
    }
    
    private func correctedName(name:String,scale:CGFloat) -> String{
        switch scale{
        case 2.0:
            return name+"@2x"
        case 3.0:
            return name+"@3x"
        default:
            return name
        }
    }
    
    //MARK: - Init methods
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        myInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        myInit()
    }
    
    private func myInit(){
        myImageViewInit()
        myOpaqueViewInit()
    }
    
    //MARK: myImageView
    private func myImageViewInit(){
        myImageView = UIImageView()
        myImageView.translatesAutoresizingMaskIntoConstraints = false
        myImageView.contentMode = UIViewContentMode.ScaleAspectFill
        myImageView.opaque = true
        myImageView.clipsToBounds = true
        self.insertSubview(myImageView, atIndex: 0)
        setMyImageViewConstraints()
    }
    
    private func setMyImageViewConstraints(){
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[image]|", options: [], metrics: nil, views: ["image":myImageView])
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[image]|", options: [], metrics: nil, views: ["image":myImageView])
        addConstraints(hConstraints)
        addConstraints(vConstraints)
    }
    
    //MARK: myOpaqueView
    private func myOpaqueViewInit(){
        myOpaqueView = UIView()
        myOpaqueView.translatesAutoresizingMaskIntoConstraints = false
        myOpaqueView.backgroundColor = UIColor(red: 45.0/255, green: 58.0/255, blue: 62.0/255, alpha: 1.0)
        myOpaqueView.alpha = 0
        self.insertSubview(myOpaqueView, atIndex: 1)
        setMyOpaqueViewConstraints()
    }
    
    private func setMyOpaqueViewConstraints(){
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[opaque]|", options: [], metrics: nil, views: ["opaque":myOpaqueView])
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[opaque]|", options: [], metrics: nil, views: ["opaque":myOpaqueView])
        addConstraints(hConstraints)
        addConstraints(vConstraints)
    }
    
    //MARK: - Touch methods
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        sendActionsForControlEvents(.TouchUpInside)
    }
    
    //MARK: - Misc methods
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
