//
//  VEditModeTransformer.swift
//  tablution
//
//  Created by Ian McCowan on 10/11/15.
//
//

import Foundation

@objc public class VEditModeTransformer: NSValueTransformer {
    public override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }

    public override class func allowsReverseTransformation() -> Bool {
        return true
    }

    public override func transformedValue(value: AnyObject?) -> AnyObject? {
        if let boolNumber = value as? NSNumber {
            return boolNumber.boolValue ? "Solo Mode" : "Chord Mode"
        }
        else if let bool = value as? Bool {
            return bool
        }
    }

    public override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        if let strValue = value as? String {
            return (strValue == "Solo Mode")
        }
    }

}