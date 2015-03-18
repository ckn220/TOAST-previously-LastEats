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
    class func getReservationURL(fromName restaurantName:String,address:String,zipcode:String,completion: (String)->()){
        getOpenTableReservationURL(fromName: restaurantName,address: address,zipcode:zipcode) { (url) -> () in
            completion(url)
        }
    }
    
    private class func getOpenTableReservationURL(fromName restaurantName:String,address:String,zipcode:String,completion: (String)->()){
        let masterURL = "http://opentable.herokuapp.com/api/restaurants?"
        var myParams = BookingService.escapeBookingParameters(restaurantName,address: address)
        
        Alamofire.request(.GET, masterURL+"name="+myParams.eName).responseJSON { (imRequest, imResponse, JSON, error) in
            if error == nil{
                if let tempRestaurants = (JSON as NSDictionary)["restaurants"] as? NSArray {
                    if tempRestaurants.count > 0 {
                        
                        var restaurant:NSDictionary
                        if tempRestaurants.count > 1{
                            restaurant = BookingService.findCorrectRestaurant(fromList: tempRestaurants, withAddress: address)
                        }else{
                            restaurant = tempRestaurants[0] as NSDictionary
                        }
                        
                        let reservationURL = restaurant["mobile_reserve_url"] as String
                        completion(reservationURL)
                        
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
    
    class func findCorrectRestaurant(fromList restaurants:NSArray, withAddress address:String) -> NSDictionary{
        let addressComponents = address.componentsSeparatedByString(" ")
        let predicate = NSPredicate(format: "address CONTAINS[cd] %@",addressComponents[0])
        
        return restaurants.filteredArrayUsingPredicate(predicate!)[0] as NSDictionary
    }
}
