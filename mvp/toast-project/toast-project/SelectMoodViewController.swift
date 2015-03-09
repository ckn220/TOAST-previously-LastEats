//
//  SelectMoodViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/25/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class SelectMoodViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var myNavBar: UIView!
    @IBOutlet weak var myBG: BackgroundImageView!
    @IBOutlet weak var moodsTableView: UITableView!
    var moods:[PFObject]!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureBG()
        clearTableViewSelection()
    }
    
    func configureBG(){
        myBG.insertImage(UIImage(named: "mainBG-blur")!, withOpacity: 0.6)
    }
    
    func clearTableViewSelection(){
        if let selectedIndexPath = moodsTableView.indexPathForSelectedRow(){
            moodsTableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
    }
    
    //MARK: - TableView datasource methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return moods.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("moodCell") as UITableViewCell
        let moodName = moods[indexPath.row]["name"] as? String
        
        cell.textLabel?.text = getCapitalString(moodName!)
        
        return cell
    }

    func getCapitalString(original:String) -> String{
        return prefix(original, 1).capitalizedString + suffix(original, countElements(original) - 1)
    }
    
    //MARK: Action methods
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }


    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "moodSelectedSegue" {
            let destination = segue.destinationViewController as ToastsViewController
            destination.myMood = moods[moodsTableView.indexPathForSelectedRow()!.row]
        }
    }
    
}
