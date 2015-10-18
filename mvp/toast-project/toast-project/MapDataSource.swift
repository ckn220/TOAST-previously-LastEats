//
//  MapDataSource.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/17/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit
import MapKit
import Parse

protocol MapDataSourceDelegate{
    func mapDataSourceToastSelected(toast:PFObject)
    func mapDataSourceToastDeselected()
    func mapDataSourcePlaceSelected(place:PFObject)
}

class MapDataSource: NSObject,MKMapViewDelegate {

    //MARK: - Properties
    //MARK: IBOutlets
    @IBOutlet weak var mapView:MKMapView!
    //MARK: Variables
    var myDelegate:MapDataSourceDelegate?
    let pinIdentifier = "toastPinView"
    var toasts:[PFObject]?{
        didSet{
            configure()
            selectToast(0)
        }
    }
    var points = [MKPointAnnotation]()
    
    //MARK: - Configure methods
    private func configure(){
        configureMap()
    }
    
    //MARK: Toast
    private func configureMap(){
        if let toasts = toasts{
            mapView.removeAnnotations(mapView.annotations)
            points.removeAll()
            mapView.addAnnotations(points(toasts))
            showAllToasts()
        }
    }
    
    //Create points
    private func points(toasts:[PFObject]) -> [MKPointAnnotation]{
        func point(toast:PFObject) -> MKPointAnnotation?{
            if let place = toast["place"] as? PFObject,
                let location = place["location"] as? PFGeoPoint{
                let newPoint = MKPointAnnotation()
                    newPoint.coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                    newPoint.title = place["name"] as? String
                    newPoint.subtitle = place["address"] as? String
                    
                    return newPoint
            }else{
                return nil
            }
        }
        //
        for toast in toasts{
            if let newPoint = point(toast){
                points.append(newPoint)
            }
        }
        
        return points
    }
    
    //Show points
    private func showAllToasts(){
        mapView.showAnnotations(mapView.annotations, animated: false)
    }
    
    //MARK: - MKMapView delegate methods
    //MARK: ViewForAnnotation
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if(!(annotation is MKUserLocation)){
            if let pin = mapView.dequeueReusableAnnotationViewWithIdentifier(pinIdentifier){
                pin.annotation = annotation
                return pin
            }else{
                return newPinView(annotation)
            }
        }else{
            return nil
        }
    }
    
    private func newPinView(annotation:MKAnnotation) -> MKAnnotationView{
        let newPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: pinIdentifier)
        newPin.canShowCallout = true
        newPin.pinColor = .Red
        let rightButton = UIButton(type: .DetailDisclosure)
        newPin.rightCalloutAccessoryView = rightButton
        
        return newPin
    }
    
    //MARK: didSelect/didDeselect AnnotationView
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let point = view.annotation as? MKPointAnnotation,
            let index = points.indexOf(point),
            let toast = toasts?[index]{
              myDelegate?.mapDataSourceToastSelected(toast)
        }
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        myDelegate?.mapDataSourceToastDeselected()
    }
    
    //MARK: didSelect callOut
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let point = view.annotation as? MKPointAnnotation,
            let index = points.indexOf(point),
            let place = toasts?[index]["place"] as? PFObject{
            myDelegate?.mapDataSourcePlaceSelected(place)
        }
    }
    
    //MARK: - Action methods
    func selectToast(index:Int){
        if mapView.annotations.count > index{
            mapView.selectAnnotation(mapView.annotations[index], animated: true)
        }
    }
}
