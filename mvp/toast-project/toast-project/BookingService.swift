//
//  DeliveryService.swift
//  toast-project
//
//  Created by Diego Cruz on 2/14/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Alamofire

class BookingService: NSObject {
    class func getReservationURL(fromName restaurantName:String,address:String,completion: (String)->()){
        getOpenTableReservationURL(fromName: restaurantName,address: address) { (url) -> () in
            completion(url)
        }
    }
    
    private class func getOpenTableReservationURL(fromName restaurantName:String,address:String,completion: (String)->()){
        let masterURL = "http://opentable.herokuapp.com/api/restaurants?"
        var myParams = BookingService.escapeBookingParameters(restaurantName,address: address)
        
        Alamofire.request(.GET, masterURL+"name="+myParams.eName+"&address="+myParams.eAddress).responseJSON { (imRequest, imResponse, JSON, error) in
            if error == nil{
                if let restaurants = (JSON as NSDictionary)["restaurants"] as? NSArray {
                    if restaurants.count > 0 {
                        let firstRestaurant = restaurants[0] as NSDictionary
                        completion(firstRestaurant["mobile_reserve_url"] as String)
                    }else{
                        completion("")
                    }
                    
                }else{
                    completion("")
                }
                
            }else{
                NSLog("%@",error!.description)
                completion("")
            }
        }
    }
    
    class func escapeBookingParameters(name:String,address:String) -> (eName:String,eAddress:String){
        let escapedName = name.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let escapedAddress = address.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        
        return (escapedName!,escapedAddress!)
    }
}
