//
//  VEditModeTransformer.swift
//  tablution
//
//  Created by Ian McCowan on 10/11/15.
//
//

import Foundation

@objc(VEditModeTransformer) public class VEditModeTransformer: NSValueTransformer {
    public override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }

    public override class func allowsReverseTransformation() -> Bool {
        return true
    }

    public override func transformedValue(value: AnyObject?) -> AnyObject? {
        guard let unwrappedValue = value as? NSNumber else {
            return value
        }
        let isSoloMode = unwrappedValue.boolValue
        if isSoloMode {
            return "Solo Mode"
        }
        else {
            return "Chord Mode"
        }
    }

    public override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        if let strValue = value as? String {
            return (strValue == "Solo Mode")
        }
        return nil
    }

}