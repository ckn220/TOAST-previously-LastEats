//
//  SearchPlaceViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/27/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire

protocol SearchPlaceDelegate {
    func searchPlaceIdSelected(placeTemp:(placeId:String,name:String))
    func searchPlaceCancelled()
}

class SearchPlaceViewController: UIViewController,UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate {

    @IBOutlet weak var nameSearchBar: UISearchBar!
    @IBOutlet weak var resultsTableView:UITableView!
    var results:[AnyObject] = []
    var tempText = ""
    var placeID = ""
    let foursquareClientId = "2EDPPGSKXYRS3TIW4TIDKRXEGBNMIVMCC5HF4FAEZEHISGI4"
    let foursquareClientSecret = "H2GC5EERWD3RHBLMSGVEY55TI5JPA5HXZD4MRLO4XILVJ4HB"
    
    var selectedPlace:NSDictionary?
    var myDelegate:SearchPlaceDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureTableView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureNameSearchBar()
    }
    
    private func configureNameSearchBar(){
        self.nameSearchBar.layer.transform = CATransform3DMakeTranslation(0, -44, 0)
    }
    
    override func viewDidAppear(animated:Bool){
        super.viewDidAppear(animated)
        showSearchBar()
    }
    
    //MARK: - Configuration methods
    func configureTableView(){
        resultsTableView.contentInset = UIEdgeInsetsMake(0,0,0,0)
    }
    
    func showSearchBar(){
        nameSearchBar.alpha = 1
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .CurveEaseOut, animations: { () -> Void in
            self.nameSearchBar.layer.transform = CATransform3DMakeTranslation(0, 0, 0)
            
        }) { (completion) -> Void in
            self.nameSearchBar.becomeFirstResponder()
            return
        }
    }
    
    func hideSearchBar(){
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .CurveEaseOut, animations: { () -> Void in
                self.nameSearchBar.layer.transform = CATransform3DMakeTranslation(0, -44, 0)
                
                }) { (completion) -> Void in
                    self.nameSearchBar.alpha = 0
                    self.nameSearchBar.text = ""
            }
        }
        nameSearchBar.resignFirstResponder()
        CATransaction.commit()
    }
    
    //MARK: - SearchBar delegate methods
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if selectedPlace == nil{
            myDelegate?.searchPlaceCancelled()
        }else{

            let name = self.selectedPlace!["name"] as! String
            self.myDelegate?.searchPlaceIdSelected((self.placeID, name))
            hideSearchBar()
            removeSuggestions()
            
            delay(0.2, closure: { () -> () in
                let name = self.selectedPlace!["name"] as! String
                self.myDelegate?.searchPlaceIdSelected((self.placeID, name))
            })
        }
        
        
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        tempText = searchText
        placeID = ""
        
        if (tempText.isEmpty == false) {
            if tempText.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")).utf16.count >= 3 {
                
                var llKey = "ll="
                var llValue = ""
                
                /*if let userLocation = PFUser.currentUser()!["lastLocation"] as? PFGeoPoint {
                    llValue = "\(userLocation.latitude),\(userLocation.longitude)"
                }else{*/
                    llKey = "near="
                    llValue = "New,York,City,NY"
                //}
                
                let foursquareRequestString = "https://api.foursquare.com/v2/venues/suggestCompletion?"+llKey+llValue+"&client_id="+foursquareClientId+"&client_secret="+foursquareClientSecret+"&v=20150207&locale=en&m=foursquare&categoryId=4d4b7105d754a06374d81259&limit=5&query="
                
                if let inputText = tempText.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()){
                    
                    Alamofire.request(.GET, foursquareRequestString + inputText)
                        .responseJSON { (response) in
                            
                            if response.result.error == nil {
                                if let result = response.result.value as? NSDictionary {
                                    if ((result["meta"] as! NSDictionary)["code"] as! Int) == 200 {
                                        let myResults = (result["response"] as! NSDictionary)["minivenues"] as? [AnyObject]
                                        
                                        if myResults?.count > 0{
                                            self.resultsTableView.beginUpdates()
                                            self.results = myResults!
                                            self.resultsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                                            self.resultsTableView.endUpdates()
                                        }else{
                                            self.removeSuggestions()
                                        }
                                        
                                    }
                                    else{
                                        self.removeSuggestions()
                                    }
                                }else{
                                    self.removeSuggestions()
                                }
                            }else{
                                NSLog("%@",response.result.error!.description)
                                self.removeSuggestions()
                            }
                    }
                }
                
            }
        }else{
            removeSuggestions()
        }
    }
    
    //MARK: - TableView datasource methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("resultCell")!
        let myItem = results[indexPath.row] as! NSDictionary
        cell.textLabel?.text = myItem["name"] as? String
        if let location = myItem["location"] as? NSDictionary{
            cell.detailTextLabel?.text = location["address"] as? String
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        selectedPlace = results[indexPath.row] as? NSDictionary
        placeID = selectedPlace!["id"] as! String
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            let name = self.selectedPlace!["name"] as! String
            self.myDelegate?.searchPlaceIdSelected((self.placeID, name))
        }
        hideSearchBar()
        removeSuggestions()
        CATransaction.commit()
    }
    
    func removeSuggestions(){
        if self.results.count > 0{
            self.resultsTableView.beginUpdates()
            self.results.removeAll(keepCapacity: false)
            self.resultsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            self.resultsTableView.endUpdates()
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
