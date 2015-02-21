//
//  Contribute1TableViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 1/30/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse
import Alamofire

class Contribute1TableViewController: UITableViewController,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UITextFieldDelegate,UITextViewDelegate,CLLocationManagerDelegate {
    
    var user:PFUser?
    let reviewPlaceholder = "What's the special sauce"
    
    var moods:[PFObject]?
    var selectedMoods:[PFObject]?
    var newToast: PFObject?
    
    var tempText: String?
    var autocompleteList: [AnyObject]?
    var placeID: String?
    let googleKey = "AIzaSyB86S1daGkVn5nHKdWgY1-Q6vHhyKz68FQ"
    let foursquareClientId = "2EDPPGSKXYRS3TIW4TIDKRXEGBNMIVMCC5HF4FAEZEHISGI4"
    let foursquareClientSecret = "H2GC5EERWD3RHBLMSGVEY55TI5JPA5HXZD4MRLO4XILVJ4HB"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moods = []
        selectedMoods = []
        autocompleteList = []
        
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        user = PFUser.currentUser()
        let query = PFQuery(className: "Mood")
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if error == nil{
                self.moods = result as? [PFObject]
                self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
            }else{
                NSLog("%@", error.description)
            }
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: TableView datasource methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if autocompleteList?.count > 0{
            return 4
        }else{
            return 3
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 && autocompleteList?.count > 0{
            return autocompleteList!.count
        }else{
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell
        
        switch indexPath.section {
        case 0:
                cell = tableView.dequeueReusableCellWithIdentifier("placeCell") as UITableViewCell
        case 1:
            if autocompleteList?.count > 0{
                cell = tableView.dequeueReusableCellWithIdentifier("autocompleteCell") as UITableViewCell
                
                let myItem = autocompleteList![indexPath.row] as NSDictionary
                cell.textLabel?.text = myItem["name"] as? String
                if let location = myItem["location"] as? NSDictionary{
                    cell.detailTextLabel?.text = location["address"] as? String
                }
            }else{
                cell = tableView.dequeueReusableCellWithIdentifier("moodsCell") as UITableViewCell
                let moodsCollection = cell.viewWithTag(201) as UICollectionView
                moodsCollection.dataSource = self
                moodsCollection.delegate = self
                moodsCollection.reloadData()
            }
            
        case 2:
            if autocompleteList?.count > 0{
                cell = tableView.dequeueReusableCellWithIdentifier("moodsCell") as UITableViewCell
                let moodsCollection = cell.viewWithTag(201) as UICollectionView
                moodsCollection.dataSource = self
                moodsCollection.delegate = self
                moodsCollection.reloadData()
            }else{
                cell = tableView.dequeueReusableCellWithIdentifier("reviewCell") as UITableViewCell
            }
        case 3:
            cell = tableView.dequeueReusableCellWithIdentifier("reviewCell") as UITableViewCell
        default:
            cell = UITableViewCell()
        }
        
        return cell
    }
    
    //MARK: TableView delegate methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        var cell: UITableViewCell
        
        switch indexPath.section {
        case 0:
            cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as UITableViewCell!
            (cell.viewWithTag(201) as UITextField).becomeFirstResponder()
        case 1:
            if autocompleteList?.count > 0{
                let firstCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as UITableViewCell!
                let myPlaceTextField = firstCell.viewWithTag(201) as UITextField
                
                cell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
                myPlaceTextField.text = (cell.viewWithTag(101) as UILabel).text
                myPlaceTextField.resignFirstResponder()
                tempText = myPlaceTextField.text
                
                placeID = autocompleteList![indexPath.row]["id"] as? String
                autocompleteList?.removeAll(keepCapacity: false)
                self.tableView.deleteSections(NSIndexSet(index: 1), withRowAnimation: .Top)
                
            }
        case 2:
            if autocompleteList?.count == 0{
                cell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
                (cell.viewWithTag(201) as UITextField).becomeFirstResponder()
            }
        case 3:
            cell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
            (cell.viewWithTag(201) as UITextField).becomeFirstResponder()
            
        default:
            cell = UITableViewCell()
        
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section==1 && autocompleteList?.count > 1{
            return 0.1
        }else{
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }
    
    //MARK: CollectionView datasource methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return moods!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("moodCell", forIndexPath: indexPath) as UICollectionViewCell
        
        let currentQuality = moods?[indexPath.row]
        let currentLabel = cell.viewWithTag(101) as UILabel
        currentLabel.text = currentQuality?["name"] as? String
        if contains(selectedMoods!,currentQuality!) {
            currentLabel.textColor = UIColor.blueColor()
        }else{
            currentLabel.textColor = UIColor.blackColor()
        }
        
        return cell
    }

    //MARK: CollectionView delegate methods
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.frame.width/2, 44)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let selectedCell = collectionView.cellForItemAtIndexPath(indexPath)
        let selectedMood = moods![indexPath.row]
        let myLabel = selectedCell?.viewWithTag(101)! as UILabel
        
        if contains(selectedMoods!,selectedMood) {
            selectedMoods?.removeAtIndex(indexPath.row)
            myLabel.textColor = UIColor.blackColor()
        }else{
            myLabel.textColor = UIColor.blueColor()
            selectedMoods?.append(selectedMood)
        }
   
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
 
        //Toast creation
        if self.newToast == nil {
            newToast = PFObject(className: "Toast")
            newToast?["user"]=PFUser.currentUser()
        }
        var reviewSection = 2
        if autocompleteList?.count > 0{
            reviewSection = 3
        }
        let reviewCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: reviewSection)) as UITableViewCell!
        let review = (reviewCell.viewWithTag(201) as UITextView).text
        if review != reviewPlaceholder {
            newToast?["review"] = review
        }else{
            newToast?["review"] = ""
        }

        //Moods association
        let moodsRelation = self.newToast!.relationForKey("moods")
        for q:PFObject in self.selectedMoods!{
            moodsRelation.addObject(q)
        }
        
        let destination = segue.destinationViewController as Contribute2TableViewController
        destination.myToast = newToast
        destination.myPlaceID = placeID
        destination.myPlaceName = tempText
    }
    
    
    //MARK: Action methods
    @IBAction func cancelPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func editingPlaceName(sender: UITextField) {
        
        tempText = sender.text
        placeID = ""
        
        if (tempText?.isEmpty == false) {
        if tempText?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")).utf16Count >= 3 {
            
            var llKey = "ll="
            var llValue = ""
            
            if let userLocation = user?["lastLocation"] as? PFGeoPoint {
                llValue = "\(userLocation.latitude),\(userLocation.longitude)"
            }else{
                llKey = "near="
                llValue = "New,York"
            }

            //let googleRequestString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?key="+googleKey+"&types=establishment&sensor=true&input="
            
            let foursquareRequestString = "https://api.foursquare.com/v2/venues/suggestCompletion?"+llKey+llValue+"&client_id="+foursquareClientId+"&client_secret="+foursquareClientSecret+"&v=20150207&m=foursquare&categoryId=4d4b7105d754a06374d81259&limit=5&query="
            
            if let inputText = tempText?.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()){
                
                Alamofire.request(.GET, foursquareRequestString + inputText)
                    .responseJSON { (imRequest, imResponse, JSON, error) in
                        
                        if error == nil {
                            if let result = JSON as? NSDictionary {
                                if ((result["meta"] as NSDictionary)["code"] as Int) == 200 {
                                    let myResults = (result["response"] as NSDictionary)["minivenues"] as? [AnyObject]
                                    
                                    if myResults?.count > 0{
                                        if self.autocompleteList?.count > 0{
                                            self.tableView.beginUpdates()
                                            self.autocompleteList = myResults
                                            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
                                            self.tableView.endUpdates()
                                        }else{
                                            self.tableView.beginUpdates()
                                            self.autocompleteList = myResults
                                            self.tableView.insertSections(NSIndexSet(index: 1), withRowAnimation: .None)
                                            self.tableView.endUpdates()
                                        }
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
    
    func removeSuggestions(){
        if self.autocompleteList?.count > 0{
            self.tableView.beginUpdates()
            self.autocompleteList?.removeAll(keepCapacity: false)
            self.tableView.deleteSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
            self.tableView.endUpdates()
        }
        
    }
    
    //MARK: Place Textfield delegate methods
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: Review textview delegate methods
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        
        if textView.text == reviewPlaceholder {
            textView.text = ""
            textView.textColor = UIColor.blackColor()
        }
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        
        if textView.text == "" {
            textView.text = reviewPlaceholder
            textView.textColor = UIColor.lightGrayColor()
        }
    }
}
