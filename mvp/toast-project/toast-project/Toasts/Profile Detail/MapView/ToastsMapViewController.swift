//
//  ToastsMapViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 7/3/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import MapKit

class ToastsMapViewController: UIViewController,MKMapViewDelegate {

    @IBOutlet weak var toastView: ToastDetailMapView!
    @IBOutlet weak var mapView: MKMapView!
    var toasts:[PFObject]?
    var myUser:PFUser!
    var topToast:PFObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myUser.fetchIfNeededInBackgroundWithBlock { (user, error) -> Void in
            if let error = error{
                NSLog("ToastsMapViewController error: ", error.description)
            }else{
                self.myUser = user as! PFUser
                self.toastView.myUser = self.myUser
                self.configurePoints()
            }
        }
    }
    
    private func configurePoints(){
        if let toasts = toasts where toasts.count > 0{
            mapView.addAnnotations(pointsFromToasts())
            mapView.showAnnotations(mapView.annotations, animated: true)
            mapView.camera.altitude *= 1.5
            mapView.selectAnnotation(mapView.annotations[0] as! MKPointAnnotation, animated: true)
        }
    }
    
    private func pointsFromToasts() -> [MKPointAnnotation]{
        var points = [MKPointAnnotation]()
        for toast in toasts!{
            if let place = toast["place"] as? PFObject,let location = place["location"] as? PFGeoPoint{
                let newPoint = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                let newAnnotation = ToastPointAnnotation()
                newAnnotation.toast = toast
                newAnnotation.coordinate = newPoint
                newAnnotation.title = place["name"] as! String
                if let address = place["address"] as? String{
                    newAnnotation.subtitle = address
                }
                points.append(newAnnotation)
            }
        }
        return points
    }
    
    //MARK: - MapView delegate methods
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var pinView : MKPinAnnotationView
        if let reusablePin = mapView.dequeueReusableAnnotationViewWithIdentifier("toastPin") as? MKPinAnnotationView{
            reusablePin.annotation = annotation
            pinView = reusablePin
        }else{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "toastPin")
            pinView.canShowCallout = true
            pinView.rightCalloutAccessoryView = rightButton()
        }
        
        return pinView
    }
    
    private func rightButton() -> UIView{
        let button = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIView
        return button
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        toggleToastViewVisibility(true)
        updateToastView(view)
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        delay(0.1, closure: { () -> () in
            self.toggleToastViewVisibility(mapView.selectedAnnotations != nil)
        })
    }
    
    private func toggleToastViewVisibility(visible:Bool){
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            if visible{
                self.toastView.alpha = 1
            }else{
                self.toastView.alpha = 0
            }
        })
    }
    
    private func updateToastView(pin:MKAnnotationView){
        let selectedToast = toast(pin)
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.toastView.configure(selectedToast)
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        goToPlace(view)
    }
    
    private func goToPlace(pin:MKAnnotationView){
        let selectedPlace = place(pin)
        let placeScene = storyboard?.instantiateViewControllerWithIdentifier("placeDetailScene") as! PlaceDetailViewController
        placeScene.myPlace = selectedPlace
        navigationController?.showViewController(placeScene, sender: self)
    }
    
    private func place(pin:MKAnnotationView) -> PFObject{
        let selectedToast = toast(pin)
        return selectedToast["place"] as! PFObject
    }
    
    private func toast(pin:MKAnnotationView) -> PFObject{
        let point = pin.annotation as! ToastPointAnnotation
        return point.toast
    }
    
    //MARK: - Actions methods
    @IBAction func backPressed(sender: UIButton) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func reviewSelected(sender: UITapGestureRecognizer) {
        let selectedAnnotation = mapView.selectedAnnotations[0] as! ToastPointAnnotation
        goToReviewDetail(selectedAnnotation.toast)
    }
    
    private func goToReviewDetail(toast:PFObject){
        let reviewScene = storyboard?.instantiateViewControllerWithIdentifier("reviewDetailScene") as! ReviewDetailViewController
        reviewScene.myToast = toast
        reviewScene.isTopToast = isTopToast(toast)
        
        let place = toast["place"] as! PFObject
        reviewScene.titleString = place["name"] as? String
        navigationController?.showViewController(reviewScene, sender: self)
    }
    
    private func isTopToast(toast:PFObject) -> Bool{
        if let topToast = myUser["topToast"] as? PFObject{
            return topToast.objectId! == toast.objectId!
        }else{
            return false
        }
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
