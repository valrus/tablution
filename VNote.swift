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
    var preMark:PreNoteMark = .None
    var postMark:PostNoteMark = .None
    
    class func NO_FRET() -> Int {
        return -1
    }

    init(fret:Int) {
        self.fret = fret
    }
    
    class func noteAtFret(theFret:Int) -> VNote {
        return VNote(fret: theFret)
    }
    
    class func blankNote() -> VNote {
        return VNote(fret: VNote.NO_FRET())
    }

    func stringValue() -> String {
        // FIXME: This is probably not the way to do this.
        // Drawing-wise, the fret number shouldn't move when you add a mark,
        // but there's no easy way to avoid it doing this.
        let pre = self.preMark == .None ? "" : "\(self.preMark.rawValue)"
        let post = self.postMark == .None ? "" : "\(self.postMark.rawValue)"
        return "\(pre)\(self.fret)\(post)"
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
    
    func setMark(markChar: Character) {
        if let mark = PreNoteMark(rawValue: markChar) {
            if self.preMark == mark {
                self.preMark = .None
            }
            else {
                self.preMark = mark
            }
        }
        else if let mark = PostNoteMark(rawValue: markChar) {
            if self.postMark == mark {
                self.postMark = .None
            }
            else {
                self.postMark = mark
            }
        }
    }
}
