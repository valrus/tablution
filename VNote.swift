//
//  VNote.swift
//  tablution
//
//  Created by Ian McCowan on 10/25/14.
//
//

import Foundation

@objc
public class VNote {

    var fret:Int
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

    func isEqual(otherNote:VNote) -> Bool {
        return (self.fret == otherNote.fret)
    }

    func hasFret() -> Bool {
        return (self.fret != VNote.NO_FRET())
    }

}
