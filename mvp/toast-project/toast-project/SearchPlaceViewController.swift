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
}

class SearchPlaceViewController: UIViewController,UISearchResultsUpdating,UISearchBarDelegate, UISearchControllerDelegate,UITableViewDataSource,UITableViewDelegate {

    @IBOutlet weak var resultsTableView:UITableView!
    var mySearchController:UISearchController?
    var results:[AnyObject] = []
    var tempText = ""
    var placeID = ""
    let foursquareClientId = "2EDPPGSKXYRS3TIW4TIDKRXEGBNMIVMCC5HF4FAEZEHISGI4"
    let foursquareClientSecret = "H2GC5EERWD3RHBLMSGVEY55TI5JPA5HXZD4MRLO4XILVJ4HB"
    
    var myDelegate:SearchPlaceDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureTableView()
        configureSearchController()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated:Bool){
        super.viewWillAppear(animated)
        showSearchBar()
    }
    
    //MARK: - Configuration methods
    func configureTableView(){
        resultsTableView.contentInset = UIEdgeInsetsMake(0,0,0,0)
    }
    
    func configureSearchController(){
        mySearchController = UISearchController(searchResultsController: nil)
        mySearchController?.dimsBackgroundDuringPresentation = false
        mySearchController?.delegate = self
        mySearchController?.searchResultsUpdater = self
        mySearchController?.searchBar.delegate = self
    }
    
    func showSearchBar(){
        let mySearchBar = mySearchController!.searchBar
        mySearchBar.frame = CGRectMake(0,-44,CGRectGetWidth(self.view.frame),44)
        self.view.addSubview(mySearchBar)
        
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .CurveEaseOut, animations: { () -> Void in
            mySearchBar.layer.transform = CATransform3DMakeTranslation(0, 44, 0)
            
        }) { (completion) -> Void in
            
        }
    }
    
    //MARK: - SearchBar delegate methods
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        //dismissSearch()
    }
    
    //MARK:  SearchController delegate methods
    func didDismissSearchController(searchController: UISearchController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: SearchResultsUpdating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        tempText = searchController.searchBar.text
        placeID = ""
        
        if (tempText.isEmpty == false) {
            if tempText.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")).utf16Count >= 3 {
                
                var llKey = "ll="
                var llValue = ""
                
                if let userLocation = PFUser.currentUser()["lastLocation"] as? PFGeoPoint {
                    llValue = "\(userLocation.latitude),\(userLocation.longitude)"
                }else{
                    llKey = "near="
                    llValue = "New,York"
                }
                
                //let googleRequestString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?key="+googleKey+"&types=establishment&sensor=true&input="
                
                let foursquareRequestString = "https://api.foursquare.com/v2/venues/suggestCompletion?"+llKey+llValue+"&client_id="+foursquareClientId+"&client_secret="+foursquareClientSecret+"&v=20150207&locale=en&m=foursquare&categoryId=4d4b7105d754a06374d81259&limit=5&query="
                
                if let inputText = tempText.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()){
                    
                    Alamofire.request(.GET, foursquareRequestString + inputText)
                        .responseJSON { (imRequest, imResponse, JSON, error) in
                            
                            if error == nil {
                                if let result = JSON as? NSDictionary {
                                    if ((result["meta"] as NSDictionary)["code"] as Int) == 200 {
                                        let myResults = (result["response"] as NSDictionary)["minivenues"] as? [AnyObject]
                                        
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
        let cell = tableView.dequeueReusableCellWithIdentifier("resultCell") as UITableViewCell
        let myItem = results[indexPath.row] as NSDictionary
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
        
        let selectedResult = results[indexPath.row] as NSDictionary
        placeID = selectedResult["id"] as String
        let name = selectedResult["name"] as String
        myDelegate?.searchPlaceIdSelected((placeID, name))
        dismissSearch()
    }
    
    func removeSuggestions(){
        if self.results.count > 0{
            self.resultsTableView.beginUpdates()
            self.results.removeAll(keepCapacity: false)
            self.resultsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            self.resultsTableView.endUpdates()
        }
        
    }
    
    //MARK: - Misc methods
    func dismissSearch(){
        mySearchController?.active = false
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
