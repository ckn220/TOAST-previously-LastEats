//
//  MapSettingsFriendsTableViewController.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/18/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class MapSettingsFriendsTableViewController: UITableViewController {

    //MARK: - Properties
    //MARK: Variables
    var myDelegate:MapSettingsDelegate?
    var friends:[PFUser]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure(){
        configureFriends()
    }
    
    private func configureFriends(){
        MapSettingsCache.shared.allFriends { (friends) -> () in
            self.friends = friends
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
    }
    
    //MARK: - Tableview datasource methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let friends = friends{
            return friends.count
        }else{
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        func checkIfNeeded(cell:UITableViewCell){
            let selectedIndexPath = MapSettingsCache.shared.selectedSetting
            if selectedIndexPath.section == 2 && indexPath.row == selectedIndexPath.row{
                cell.accessoryType = .Checkmark
            }else{
                cell.accessoryType = .None
            }
        }
        //
        if let friends = friends{
            let friend = friends[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("friendCell") as! MapSettingsFriendCell
            cell.configure(friend)
            checkIfNeeded(cell)
            return cell
        }else{
            return tableView.dequeueReusableCellWithIdentifier("loadingCell")!
        }
    }
    
    //MARK: DidSelect
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        check(indexPath)
    }
    
    private func check(indexPath:NSIndexPath){
        func toggleCheck(indexPath:NSIndexPath,checked:Bool){
            if let cell = tableView.cellForRowAtIndexPath(indexPath){
                if checked{
                    cell.accessoryType = .Checkmark
                    let correctedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 2)
                    MapSettingsCache.shared.selectedSetting = correctedIndexPath
                    if let friend = friends?[indexPath.row]{
                        myDelegate?.mapSettingsFriendSelected(friend)
                    }
                }else{
                    cell.accessoryType = .None
                }
            }
        }
        //
        let selectedIndexPath = MapSettingsCache.shared.selectedSetting
        if !equalIndexPaths(indexPath, toIndexPath: selectedIndexPath){
            toggleCheck(selectedIndexPath,checked:false)
            toggleCheck(indexPath, checked: true)
        }
    }
    
    //MARK: - Misc methods
    private func equalIndexPaths(uncorrectedIndexPath:NSIndexPath,toIndexPath:NSIndexPath)->Bool{
        let correctedIndexPath = NSIndexPath(forRow:uncorrectedIndexPath.row, inSection:2)
        return correctedIndexPath.section == toIndexPath.section && correctedIndexPath.row == toIndexPath.row
    }
}
