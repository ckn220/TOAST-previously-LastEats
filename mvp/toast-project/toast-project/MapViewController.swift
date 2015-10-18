//
//  MapViewController.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/17/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class MapViewController: UIViewController,MapDataSourceDelegate,UIPopoverPresentationControllerDelegate,MapSettingsDelegate {
    //MARK: - Properties
    //MARK: IBOutlets
    @IBOutlet var dataSource: MapDataSource!{
        didSet{
            dataSource.myDelegate = self
        }
    }
    @IBOutlet weak var mapDetailView: MapDetailView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    //MARK: Variables
    var userFromProfileDetail:PFUser?
    var myDelegate:DiscoverDelegate?
    
    //MARK: - Configure methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure(){
        configureInitialLoading()
    }
    
    private func configureInitialLoading(){
        if let user = userFromProfileDetail{
            loadMap(user: user)
            settingsButton.alpha = 0
        }else{
            loadMapWithRecentToasts()
        }
    }
    
    //MARK: - Load methods
    private func loadMap(user user:PFUser){
        func titleForUser() -> String{
            let name = user["name"] as! String
            let words = name.componentsSeparatedByString(" ")
            return "\(words[0])'s Toasts"
        }
        //
        call(functionName: "mapToastsByFriend", parameter:user) { (toasts) -> () in
            self.titleLabel.text = titleForUser()
        }
    }
    
    private func loadMap(mood mood:PFObject){
        func titleForMood() -> String{
            let name = mood["name"] as! String
            return capitalString(name)
        }
        //
        call(functionName: "mapToastsByMood", parameter: mood) { (toasts) -> () in
            self.titleLabel.text = titleForMood()
        }
    }
    
    private func loadMapWithTopToasts(){
        call(functionName: "mapToastsByTopToast") { (toasts) -> () in
            self.titleLabel.text = "Top Toasts"
        }
    }
    
    private func loadMapWithRecentToasts(){
        call(functionName: "mapToastsByRecentlyAdded") { (toasts) -> () in
            self.titleLabel.text = "Recently Added"
        }
    }
    
    //MARK: Load From Parse method
    private func call(functionName name:String,parameter:PFObject?=nil,completion:(toasts:[PFObject])->()){
        
        var parameters:[String:AnyObject]? = nil
        if let parameter = parameter{
            parameters = [String:AnyObject]()
            parameters!["objectId"] = parameter.objectId!
        }
        PFCloud.callFunctionInBackground(name, withParameters: parameters) { (result, error) -> Void in
            if let error = error{
                NSLog("call error: %@",error.description)
                completion(toasts: [])
            }else{
                if let toasts = result as? [PFObject]{
                    self.dataSource.toasts = toasts
                    completion(toasts: toasts)
                }else{
                    completion(toasts:[])
                }
            }
        }
    }
    
    //MARK: - Map datasource delegate methods
    func mapDataSourceToastDeselected() {
        mapDetailView.toast = nil
    }
    
    func mapDataSourceToastSelected(toast: PFObject) {
        mapDetailView.toast = toast
    }
    
    func mapDataSourcePlaceSelected(place: PFObject) {
        goToPlaceDetail(place)
    }
    
    //MARK: - Actions methods
    private func goToPlaceDetail(place:PFObject){
        let placeDetailScene = storyboard?.instantiateViewControllerWithIdentifier("placeDetailScene") as! PlaceDetailViewController
        placeDetailScene.myPlace = place
        showViewController(placeDetailScene, sender: self)
    }
    
    private func goToToastDetail(toast:PFObject){
        let toastDetailScene = storyboard?.instantiateViewControllerWithIdentifier("reviewDetailScene") as! ReviewDetailViewController
        toastDetailScene.myToast = toast
        toastDetailScene.myPlace = toast["place"] as? PFObject
        showViewController(toastDetailScene, sender: self)
    }
    
    //MARK: IBActions
    @IBAction func mapDetailViewPressed(sender: MapDetailView){
        if let toast = sender.toast{
            goToToastDetail(toast)
        }
    }
    
    @IBAction func backButtonPressed(sender: UIButton) {
        if let myDelegate = myDelegate{
            myDelegate.discoverMenuPressed()
        }else{
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    //MARK: PrepareForSegue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "settingsSegue"{
            let destinationNav = segue.destinationViewController
            configureSeguePopover(destinationNav)
            configureSegueDestination(destinationNav)
        }
    }
    
    private func configureSeguePopover(navScene:UIViewController){
        if let popOver = navScene.popoverPresentationController{
            popOver.delegate = self
        }
    }
    
    private func configureSegueDestination(navScene:UIViewController){
        if let nav = navScene as? UINavigationController,
            let destination = nav.viewControllers[0] as? MapSettingsTableViewController{
                destination.myDelegate = self
        }
    }
    
    //MARK: - PopoverPresentationController delegate methods
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    //MARK: - MapSettings delegate methods
    func mapSettingsRecentlyAddedSelected() {
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.loadMapWithRecentToasts()
        })
    }
    
    func mapSettingsTopToastSelected() {
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.loadMapWithTopToasts()
        })
    }
    
    func mapSettingsMoodSelected(mood: PFObject) {
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.loadMap(mood: mood)
        })
    }
    
    func mapSettingsFriendSelected(friend: PFUser) {
        presentedViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.loadMap(user: friend)
        })
    }
    
    //MARK: - Misc methods
    func capitalString(original:String) -> String{
        return String(original.characters.prefix(1)).capitalizedString + String(original.characters.suffix(original.characters.count - 1))
    }
}
