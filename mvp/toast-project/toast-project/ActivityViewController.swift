//
//  ActivityViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 7/19/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import UIKit
import Parse

class ActivityViewController: UIViewController,ActivityFeedDelegate {
    var myDelegate:DiscoverDelegate?
    
    @IBAction func backPressed(sender: UIButton) {
        myDelegate?.discoverMenuPressed()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "activityTableViewSegue"{
            let destination = segue.destinationViewController as! ActivityTableViewController
            destination.myDelegate = self
        }
    }
    
    //MARK: - Activity feed delegate methods
    func activityFeedUserSelected(user: PFUser) {
        let profileScene = storyboard?.instantiateViewControllerWithIdentifier("profileDetailScene") as! ProfileDetailViewController
        profileScene.myUser = user
        showViewController(profileScene, sender: self)
    }
    
    func activityFeedPlaceSelected(toast: PFObject) {
        let reviewScene = storyboard?.instantiateViewControllerWithIdentifier("reviewDetailScene") as! ReviewDetailViewController
        reviewScene.myToast = toast
        showViewController(reviewScene, sender: self)
    }
    
    func activityFeedPlaceReviewsSelected(place: PFObject,title:String) {
        let toastCarouselScene = storyboard?.instantiateViewControllerWithIdentifier("toastsScene") as! ToastsViewController
        toastCarouselScene.myPlaces = [place]
        toastCarouselScene.externalTitle = title
        showViewController(toastCarouselScene, sender: nil)
    }
    
    func activityFeedPlaceLikesSelected(activity:PFObject) {
        let friendsScene = storyboard?.instantiateViewControllerWithIdentifier("friendsListScene") as! FriendsListViewController
        friendsScene.myActivity = activity
        showViewController(friendsScene, sender: nil)
    }
    
    func activityFeedAddToastSelected(place: PFObject) {
        let contributeScene = storyboard?.instantiateViewControllerWithIdentifier("contributeScene") as! ContributeViewController
        contributeScene.fromActivity = true
        contributeScene.fromActivityPlaceFoursquareId = place["foursquarePlaceId"] as? String
        contributeScene.fromActivityPlaceName = place["name"] as? String
        showDetailViewController(contributeScene, sender: nil)
    }
}
