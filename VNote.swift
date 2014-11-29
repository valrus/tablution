//
//  VNote.swift
//  tablution
//
//  Created by Ian McCowan on 10/25/14.
//
//

import Foundation

public class VNote: NSObject {
    dynamic var fret:Int
    var attrs:Dictionary<String, String>
    
    class func NO_FRET() -> Int {
        return -1
    }

    init(fret:Int) {
        self.fret = fret
        self.attrs = [:]
    }
    
    class func noteAtFret(theFret:Int) -> VNote {
        return VNote(fret: theFret)
    }
    
    class func blankNote() -> VNote {
        return VNote(fret: VNote.NO_FRET())
    }

    func stringValue() -> String {
        return "\(self.fret)"
    }

    func stringValueOrDash() -> String {
        if (self.fret == VNote.NO_FRET()) {
            return "-"
        }
        else {
            return self.stringValue()
        }
    }

    public override func isEqual(other:AnyObject?) -> Bool {
        if let otherNote = other as? VNote {
            return otherNote.fret == self.fret
        }
        else {
            return false
        }
    }

    func hasFret() -> Bool {
        return (self.fret != VNote.NO_FRET())
    }

}
