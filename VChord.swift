//
//  VChord.swift
//  tablution
//
//  Created by Ian McCowan on 10/25/14.
//
//

import Foundation

public class VChord: NSObject, SequenceType {
    dynamic private var notes: Array<VNote>
    var attrs: Dictionary<String, String>

    init(notes: Array<VNote>) {
        self.notes = notes
        self.attrs = [:]
    }

    class func chordWithIntArray(fretNumArray: Array<Int>) -> VChord {
        var noteArray: Array<VNote> = fretNumArray.map({ VNote(fret: $0) })
        return VChord(notes: noteArray)
    }

    // was chordWithStrings:withFret:onString:
    class func chordWithOneFret(fret: Int,
                                onString string: Int,
                                numStrings: Int) -> VChord {
        return VChord(notes: Array(map(1...numStrings) { VNote(fret: $0 == string ? fret : VNote.NO_FRET()) }))
    }
    
    class func chordWithStrings(numStrings: Int, fromText text: String) -> VChord? {
        NSLog("Loading chord from string: %@", text)
        var fretStringsArray: Array<String> = split(text, { $0 == " " })
        if fretStringsArray.count >= numStrings {
            var fretNumsArray:Array<Int> = Array(fretStringsArray[0..<numStrings]).map({
                (fretStr: String) -> Int in
                if let fret = fretStr.toInt() {
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
            NSLog("%@", self.notes[index])
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
        return " ".join(self.notes.map({ $0.stringValue() }))
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
    
    public func generate() -> GeneratorOf<VNote> {
        var nextIndex = 0
        
        return GeneratorOf<VNote> {
            if (nextIndex >= self.numStrings()) {
                return nil
            }
            return self[nextIndex++]
        }
    }
}