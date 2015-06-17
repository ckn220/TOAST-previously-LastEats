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

class BackgroundImageView: UIView {

    var myOpaqueLayer:CALayer!
    var myImageView:UIImageView!
    var myOpacity:CGFloat = 0.0
    
    //MARK: - setImage methods
    func setImage(name:String,opacity:Float = 0.0){
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
            self.delay(0.2, closure: { () -> () in
                UIView.transitionWithView(self.myImageView, duration: 0.4, options: .TransitionCrossDissolve, animations: { () -> Void in
                    let imgPath = NSBundle.mainBundle().pathForResource(self.correctedName(name,scale: UIScreen.mainScreen().scale), ofType: "jpg")
                    self.myImageView.hnk_setImageFromFile(imgPath!, failure: { (error) -> () in
                        NSLog("setImageName error: %@",error!.description)
                        self.setImage("default", opacity: opacity)
                        }, success: nil)
                    self.myOpaqueLayer.opacity = opacity
                    }, completion: nil)
            })            
        }
    }
    
    func setImage(URL url:String,opacity:Float = 0.0,completion:(()->Void)? = nil){
        myImageView.hnk_setImageFromURL(NSURL(string:url)!, failure: { (error) -> () in
            NSLog("setImageURL error: %@",error!.description)
            }, success: {(image)-> () in
                self.myImageView.image = image
                completion?()
        })
        myOpaqueLayer.opacity = opacity
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
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        myInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        myInit()
        layoutSubviews()
    }
    
    private func myInit(){
        myImageViewInit()
        myOpaqueLayerInit()
        self.layoutIfNeeded()
    }
    
    private func myImageViewInit(){
        myImageView = UIImageView()
        myImageView.contentMode = UIViewContentMode.ScaleAspectFill
        myImageView.opaque = true
        self.insertSubview(myImageView, atIndex: 0)
    }
    
    private func myOpaqueLayerInit(){
        myOpaqueLayer = CALayer()
        myOpaqueLayer.backgroundColor = UIColor(red: 45.0/255, green: 58.0/255, blue: 62.0/255, alpha: 1.0).CGColor
        self.layer.insertSublayer(myOpaqueLayer, atIndex: 1)
    }
    
    override func layoutSubviews() {
        myImageView.frame = self.bounds
        myOpaqueLayer.frame = self.bounds
    }
    //MARK: -
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
