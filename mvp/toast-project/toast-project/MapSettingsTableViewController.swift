//
//  MapSettingsTableViewController.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/18/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

protocol MapSettingsDelegate{
    func mapSettingsRecentlyAddedSelected()
    func mapSettingsTopToastSelected()
    func mapSettingsMoodSelected(mood:PFObject)
    func mapSettingsFriendSelected(friend:PFUser)
}

class MapSettingsTableViewController: UITableViewController {

    //MARK: - Properties
    //MARK: Variables
    var moods:[PFObject]?
    var myDelegate:MapSettingsDelegate?
    
    //MARK: - Configure methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure(){
        configureMoods()
    }
    
    private func configureMoods(){
        MapSettingsCache.shared.allMoods { (moods) -> () in
            self.moods = moods
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        }
    }
    
    //MARK: - TableView datasource methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 3
        }else{
            if let moods = moods{
                return moods.count
            }else{
                return 1
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        func checkIfNeeded(cell:UITableViewCell){
            if !equalFriendsIndexPath(indexPath){
                let selectedIndexPath = MapSettingsCache.shared.selectedSetting
                if equalIndexPaths(indexPath, toIndexPath: selectedIndexPath){
                    cell.accessoryType = .Checkmark
                }else{
                    cell.accessoryType = .None
                }
            }
        }
        //
        if indexPath.section == 0{
            var cell = tableView.dequeueReusableCellWithIdentifier("singleTitleCell")!
            switch indexPath.row{
            case 0:
                cell.textLabel?.text = "Recently Added"
            case 1:
                cell.textLabel?.text = "Top Toast"
            case 2:
                cell = tableView.dequeueReusableCellWithIdentifier("friendsCell")!
            default:
                break
            }
            checkIfNeeded(cell)
            return cell
        }else{
            if let moods = moods{
                let mood = moods[indexPath.row]
                let cell = tableView.dequeueReusableCellWithIdentifier("singleTitleCell")!
                cell.textLabel?.text = capitalString(mood["name"] as? String)
                checkIfNeeded(cell)
                return cell
            }else{
                let cell = tableView.dequeueReusableCellWithIdentifier("loadingCell")!
                return cell
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return nil
        }else{
            return "Moods"
        }
    }
    
    //MARK: - didSelect methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0{
            switch indexPath.row{
            case 0:
                myDelegate?.mapSettingsRecentlyAddedSelected()
            case 1:
                myDelegate?.mapSettingsTopToastSelected()
            default:
                break
            }
            check(indexPath)
        }else{
            if let moods = moods{
                check(indexPath)
                let mood = moods[indexPath.row]
                myDelegate?.mapSettingsMoodSelected(mood)
            }
        }
    }
    
    private func check(indexPath:NSIndexPath){
        func toggleCheck(indexPath:NSIndexPath,checked:Bool){
            if let cell = tableView.cellForRowAtIndexPath(indexPath){
                if checked{
                    cell.accessoryType = .Checkmark
                    MapSettingsCache.shared.selectedSetting = indexPath
                }else{
                    cell.accessoryType = .None
                }
            }
        }
        //
        let selectedIndexPath = MapSettingsCache.shared.selectedSetting
        if !equalFriendsIndexPath(indexPath) && !equalIndexPaths(indexPath, toIndexPath: selectedIndexPath){
            toggleCheck(selectedIndexPath,checked:false)
            toggleCheck(indexPath, checked: true)
        }
    }
    
    //MARK: - Action methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "friendsSegue"{
            let destination = segue.destinationViewController as! MapSettingsFriendsTableViewController
            destination.myDelegate = myDelegate
        }
    }
    
    //MARK: - Misc methods
    private func equalIndexPaths(indexPath:NSIndexPath,toIndexPath:NSIndexPath)->Bool{
        return indexPath.section == toIndexPath.section && indexPath.row == toIndexPath.row
    }
    
    private func equalFriendsIndexPath(indexPath:NSIndexPath)-> Bool{
        let friendsIndexPath = NSIndexPath(forRow: 2, inSection: 0)
        return equalIndexPaths(indexPath, toIndexPath: friendsIndexPath)
    }
    
    func capitalString(original:String?) -> String?{
        if let original = original{
            return String(original.characters.prefix(1)).capitalizedString + String(original.characters.suffix(original.characters.count - 1))
        }else{
            return nil
        }
    }
}
