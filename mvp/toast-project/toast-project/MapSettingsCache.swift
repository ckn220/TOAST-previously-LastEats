//
//  MapSettingsCache.swift
//  toast-project
//
//  Created by Diego Alberto Cruz Castillo on 10/18/15.
//  Copyright © 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class MapSettingsCache: NSObject {
    //MARK: - Properties
    //Shared
    static let shared = MapSettingsCache()
    //Variables
    var moods:[PFObject]?
    var friends:[PFUser]?
    //
    var selectedSetting = NSIndexPath(forRow: 0, inSection: 0)
    
    //MARK: - get methods
    func allMoods(completion:(moods:[PFObject])->()){
        func moodsFromParse(completion:(moods:[PFObject])->()){
            let moodsQuery = PFQuery(className: "Mood")
            moodsQuery.orderByAscending("name")
            moodsQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
                if let error = error{
                    NSLog("moodsFromParse error: %@",error.description)
                }else{
                    if let moods = result{
                        self.moods = moods
                        completion(moods: moods)
                    }else{
                        completion(moods: [])
                    }
                }
            }
        }
        //
        if let moods = moods{
            completion(moods: moods)
        }else{
            moodsFromParse(completion)
        }
    }
    
    func allFriends(completion:(friends:[PFUser])->()){
        func friendsFromParse(completion:(friends:[PFUser])->()){
            if let friendsQuery = PFUser.currentUser()?.relationForKey("friends").query(){
                friendsQuery.findObjectsInBackgroundWithBlock({ (result, error) -> Void in
                    if let error = error{
                        NSLog("friendsFromParse error: %@",error.description)
                    }else{
                        if let friends = result as? [PFUser]{
                            self.friends = friends
                            completion(friends: friends)
                        }else{
                            completion(friends: [])
                        }
                    }
                })
            }else{
                completion(friends: [])
            }
        }
        //
        if let friends = friends{
            completion(friends: friends)
        }else{
            friendsFromParse(completion)
        }
    }
    
    //MARK: - reset methods
    func resetSelectedSetting(){
        selectedSetting = NSIndexPath(forRow: 0, inSection: 0)
    }
}
