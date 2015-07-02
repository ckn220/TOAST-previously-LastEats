//
//  MyLocationManager.swift
//  toast-project
//
//  Created by Diego Cruz on 3/21/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import CoreLocation

protocol MyLocationManagerDelegate{
    func myLocationManagerDidGetUserLocation(location:CLLocation)
    func myLocationManagerFailed()
}

class MyLocationManager: NSObject,CLLocationManagerDelegate {
    let manager = CLLocationManager()
    var myDelegate: MyLocationManagerDelegate?
    
    init(myDelegate:MyLocationManagerDelegate){
        super.init()
        configureLocation(myDelegate:myDelegate)
    }
    
    func configureLocation(#myDelegate:MyLocationManagerDelegate){
        manager.delegate = self
        self.myDelegate = myDelegate
        triggerLocationServices()
    }
    
    //MARK: CoreLocation methods
    func triggerLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            if manager.respondsToSelector("requestWhenInUseAuthorization") {
                manager.requestWhenInUseAuthorization()
            } else {
                startUpdatingLocation()
            }
        }
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status{
        case .AuthorizedWhenInUse:
            startUpdatingLocation()
        case .NotDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            myDelegate?.myLocationManagerFailed()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let lastLocation = locations.last as! CLLocation
        if lastLocation.timestamp.timeIntervalSinceNow > -30 {
            manager.stopUpdatingLocation()
            myDelegate?.myLocationManagerDidGetUserLocation(lastLocation)
        }
        
    }
}
