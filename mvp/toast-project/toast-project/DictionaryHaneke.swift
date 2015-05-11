//
//  DictionaryHaneke.swift
//  toast-project
//
//  Created by Diego Cruz on 5/10/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import Foundation
import Haneke

extension NSDictionary : DataConvertible, DataRepresentable {
    
    public typealias Result = NSDictionary
    
    public class func convertFromData(data:NSData) -> Result? {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDictionary
    }
    
    public func asData() -> NSData! {
        return NSKeyedArchiver.archivedDataWithRootObject(self)
    }
    
}
