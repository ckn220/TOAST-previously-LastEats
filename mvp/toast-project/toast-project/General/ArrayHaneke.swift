//
//  array.swift
//  toast-project
//
//  Created by Diego Cruz on 5/2/15.
//  Copyright (c) 2015 Diego Cruz. All rights reserved.
//

import Foundation
import Haneke

extension NSArray : DataConvertible, DataRepresentable {
    
    public typealias Result = NSArray
    
    public class func convertFromData(data:NSData) -> Result? {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSArray
    }
    
    public func asData() -> NSData! {
        return NSKeyedArchiver.archivedDataWithRootObject(self)
    }
    
}
