//
//  VChord.swift
//  tablution
//
//  Created by Ian McCowan on 10/25/14.
//
//

import Foundation

public class VChord: NSObject, SequenceType {
    dynamic var notes: Array<VNote>
    var attrs: Dictionary<String, String>

    init(notes: Array<VNote>) {
        self.notes = notes
        self.attrs = [:]
    }

    class func chordWithIntArray(fretNumArray: Array<Int>) -> VChord {
        let noteArray: Array<VNote> = fretNumArray.map({ VNote(fret: $0) })
        return VChord(notes: noteArray)
    }

    // was chordWithStrings:withFret:onString:
    class func chordWithOneFret(fret: Int,
                                onString string: Int,
                                numStrings: Int) -> VChord {
        return VChord(notes: Array((0..<numStrings).map { VNote(fret: $0 == string ? fret : VNote.NO_FRET()) }))
    }
    
    class func chordWithStrings(numStrings: Int, fromText text: String) -> VChord? {
        NSLog("Loading chord from string: %@", text)
        var fretStringsArray: Array<String> = text.characters.split(isSeparator: { $0 == " " }).map { String($0) }
        if fretStringsArray.count >= numStrings {
            let fretNumsArray:Array<Int> = Array(fretStringsArray[0..<numStrings]).map({
                (fretStr: String) -> Int in
                if let fret = Int(fretStr) {
                    return fret
                } else {
                    return VNote.NO_FRET()
                }
            })
            return VChord.chordWithIntArray(fretNumsArray)
        }
        return nil
    }
    
    subscript(index: Int) -> VNote? {
        get {
            return self.notes[index] as VNote
        }
        set(newValue) {
            self.notes[index] = newValue!
        }
    }
    
    func fretOnString(index: Int) -> Int {
        return self[index]!.fret
    }
    
    func asText() -> String {
        return self.notes.map({ $0.stringValue() }).joinWithSeparator(" ")
    }
    
    func numStrings() -> Int {
        return self.notes.count
    }

    func indexesOfChangedNotesFrom(otherChord: VChord) -> NSIndexSet? {
        if otherChord.numStrings() == self.numStrings() {
            let stringIndexSet: NSIndexSet = NSIndexSet(indexesInRange: NSRange(location: 0,
                                                                                length: self.numStrings()))
            return stringIndexSet.indexesPassingTest({
                (index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
                return self.fretOnString(index) != otherChord.fretOnString(index)
            })
        } else {
            return nil
        }
    }
    
    public func generate() -> AnyGenerator<VNote> {
        var nextIndex = 0
        
        return anyGenerator {
            if (nextIndex >= self.numStrings()) {
                return nil
            }
            return self[nextIndex++]
        }
    }
}