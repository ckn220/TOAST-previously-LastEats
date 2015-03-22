//
//  DiscoverCell.swift
//  toast-project
//
//  Created by Diego Cruz on 3/21/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol DiscoverCellDelegate{
    func discoverCellSelected(#index:Int)
}

class DiscoverCell: UIView {

    @IBOutlet weak var myBGView:UIView!
    @IBOutlet weak var myLabel:UILabel!
    var isCurrent:Bool = false{
        didSet{
            toogleCurrent()
        }
    }
    var idleColor:UIColor?
    var myDelegate:DiscoverCellDelegate?
    var index:Int=0
    
    func configureItem(item:PFObject,isMood:Bool,myDelegate:DiscoverCellDelegate,index:Int){
        self.myDelegate = myDelegate
        self.index = index
        configureLabel(item:item)
        configureBackground(isMood:isMood)
    }
    
    private func configureLabel(#item:PFObject){
        myLabel.text = getCapitalString(item["name"] as String!)
    }
    
    private func configureBackground(#isMood:Bool){
        if isMood{
            idleColor = UIColor(white:1,alpha:0.3)
        }else{
            idleColor = UIColor(hue:0.556, saturation:0.674, brightness:1, alpha:1)
        }
        myBGView.backgroundColor = idleColor
        
        configureCorners()
    }
    
    private func commitIdleColor(){
        myBGView.backgroundColor = idleColor
    }
    
    private func configureCorners(){
        let bgLayer = myBGView.layer
        bgLayer.cornerRadius = 2
    }
    
    func toogleCurrent(){
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.toogleCurrentBG()
            self.toogleCurrentLabel()
        })
    }
    
    func toogleCurrentLabel(){
        if isCurrent{
            myLabel.font = UIFont(name: "Avenir-Heavy", size: 19)
            myLabel.alpha = 1
        }else{
            myLabel.font = UIFont(name: "Avenir-Roman", size: 19)
            myLabel.alpha = 0.8
        }
    }
    
    func toogleCurrentBG(){
        if isCurrent{
            myBGView.alpha = 1
        }else{
            myBGView.alpha = 0
        }
    }

    //MARK: - Misc methods
    func getCapitalString(original:String) -> String{
        return prefix(original, 1).capitalizedString + suffix(original, countElements(original) - 1)
    }
    
    //MARK: - Touch events methods
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        var hue,saturation,brightness,colorAlpha:CGFloat
        hue=0
        saturation=0
        brightness=0
        colorAlpha=0
        
        myBGView.backgroundColor?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &colorAlpha)
        myBGView.backgroundColor = UIColor(hue: hue, saturation: saturation, brightness: brightness-0.2, alpha: colorAlpha)
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        UIView.animateWithDuration(0.01, delay: 0.1, options: .CurveLinear, animations: { () -> Void in
            self.myBGView.backgroundColor = self.idleColor
        }, completion: nil)
        myDelegate?.discoverCellSelected(index:index)
    }
}
