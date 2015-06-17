//
//  ReviewPlaceViewController.swift
//  toast-project
//
//  Created by Diego Cruz on 2/28/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import Foundation
import Parse

class HashtagsManager: NSObject{
    
    class func hashtagsFromReview(review:String,toastID:String){
        var tempHashTags = [String]()
        var segments:[String] = review.componentsSeparatedByString(" ")
        for segment in segments{
            if isHashtag(segment){
                let hashtagName = cleanHashtag(segment)
                if !contains(tempHashTags, hashtagName){
                    tempHashTags.append(hashtagName)
                }
            }
        }
        
        PFCloud.callFunctionInBackground("createHashtagsIfNew", withParameters: ["items":tempHashTags,"toastId":toastID]) { (result, error) -> Void in
            if error != nil{
                NSLog("%@",error.description)
            }
        }
    }
    
    class func cleanHashtag(rawHashtag:String) -> String{
        return replaceStrings([".",",","#",":",";"], withString: "", from: rawHashtag)
    }
    
    private class func distinct<T: Equatable>(source: [T]) -> [T] {
        var unique = [T]()
        for item in source {
            if !contains(unique, item) {
                unique.append(item)
            }
        }
        return unique
    }
    
    private class func isHashtag(string:String)->Bool{
        if findIndex(from: string, of: "#") == 0{
            return true
        }else{
            return false
        }
    }
    
    private class func findIndex(from source:String,of target: String) -> Int
    {
        var range = source.rangeOfString(target)
        if let range = range {
            return distance(source.startIndex, range.startIndex)
        } else {
            return -1
        }
    }
    
    private class func replaceStrings(strings:[String],withString: String,from source: String) -> String
    {
        var result:String = source
        for s in strings{
            result = result.stringByReplacingOccurrencesOfString(s, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
        }
        return result
    }
    
    private class func getHashtag(name:String,hashtags:[PFObject])->PFObject{
        let matchedHastags = hashtags.filter {($0["name"] as! String) == name}
        if matchedHastags.count > 0{
            return matchedHastags[0]
        }else{
            return createHashtag(name)
        }
    }
    
    private class func createHashtag(name:String)->PFObject{
        var newHashtag = PFObject(className: "Hashtag")
        newHashtag["name"] = name
        newHashtag["toastsCount"] = 0
        newHashtag.saveInBackgroundWithBlock(nil)
        
        return newHashtag
    }

}
