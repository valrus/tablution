//
//  VTablature.swift
//  tablution
//
//  Created by Ian McCowan on 11/29/14.
//
//

import AppKit
import Foundation

let HUMAN_READABLE_WIDTH = 80
let VTABLATURE_DATA_UTI = "com.valrusware.tablature"

public struct TabLocation {
    var index = 0
    var string = 0
}

@objc public class VTablature: NSObject, SequenceType, NSPasteboardWriting, NSPasteboardReading {
    dynamic var chords: Array<VChord>
    private var measureBars: NSMutableIndexSet
    
    var numStrings: Int
    var stringLabels: [String]
    
    // https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/AdoptingCocoaDesignPatterns.html
    private var myContext = 0

    // MARK: Initializers and deinitializers
    
    init(numStrings: Int = 6, withChords chords: [VChord], withBarsAtIndexes barIndexes: NSMutableIndexSet) {
        self.numStrings = numStrings
        self.stringLabels = ["E", "A", "D", "G", "B", "e"]
        self.chords = chords
        self.measureBars = barIndexes
    }
    
    public convenience init(numStrings: Int) {
        self.init(numStrings: numStrings, withChords:[], withBarsAtIndexes:NSMutableIndexSet())
    }
    
    deinit {
        for chord in self.chords {
            chord.removeObserver(self, forKeyPath: "notes")
        }
    }
    
    func addFeaturesFromTextArray(textArray: Array<String>, atIndex index: Int)
    {
        for featureText in textArray {
            if featureText == "|" {
                self.toggleBarAtIndex(index)
            }
        }
    }

    convenience init(fromText tabText: String) {
        var numStrings: Int = 0
        let chordTextArray: Array<String> = tabText.characters.split(isSeparator: { $0 == "\n" }).map { String($0) }
        var chords: Array<VChord> = []
        let barIndexes: NSMutableIndexSet = NSMutableIndexSet()
        for chordText in chordTextArray {
            if chordText.isEmpty {
                break
            }
            var fretStringsArray = chordText.characters.split(isSeparator: { $0 == " " }).map { String($0) }
            if numStrings == 0 {
                // initialize a new tab with the number of strings seen
                numStrings = fretStringsArray.count
            }
            if fretStringsArray.count >= numStrings {
                let stringArray: [String] = Array(fretStringsArray[0..<numStrings])
                let featureArray = Array(fretStringsArray[numStrings..<fretStringsArray.count])
                if featureArray.contains("|") {
                    barIndexes.addIndex(chords.count)
                }
                chords.append(VChord.chordWithIntArray(stringArray.map({
                    (fretStr: String) -> Int in
                    if let fretNum = Int(fretStr) {
                        return fretNum
                    } else {
                        return -1
                    }
                })))
            }
        }
        self.init(numStrings: numStrings, withChords: chords, withBarsAtIndexes: barIndexes)
    }
    
    // MARK: Class functions for initialization
    
    public class func tablatureFromText(tabText: String) -> VTablature {
        return VTablature(fromText: tabText)
    }
    
    class func tablatureWithChords(chordArray: Array<VChord>) -> VTablature {
        if chordArray.isEmpty {
            return VTablature(numStrings: 6)
        }
        else {
            let newTablature = VTablature(numStrings: chordArray[0].numStrings())
            let insertionIndexSet = NSIndexSet(indexesInRange: NSRange(location:0,
                                                                       length: chordArray.count))
            newTablature.insertChords(chordArray, atIndexes:insertionIndexSet)
            return newTablature
        }
    }
    
    // MARK: - Accessors -
    
    public func objectInChordsAtIndex(index: Int) -> AnyObject {
        return self.chords[index]
    }

    public func chordsAtIndexes(indexes: NSIndexSet) -> Array<VChord> {
        return (self.chords as NSArray).objectsAtIndexes(indexes) as! Array<VChord>
    }
    
    public func countOfChords() -> Int {
        return chords.count
    }
    
    public func hasBarAtIndex(index: Int) -> Bool {
        return measureBars.containsIndex(index)
    }
    
    public func noteAtLocation(loc: TabLocation) -> VNote? {
        if loc.index < self.chords.count && loc.string < self.numStrings {
            return self.chords[loc.index][loc.string]
        }
        return nil
    }
    
    public func fretAtIndex(index: Int, onString stringNum: Int) -> Int? {
        if let note = self.noteAtLocation(TabLocation(index: index, string: stringNum)) {
            return note.fret
        }
        return nil
    }
    
    // String conversions
    
    class func getNoteTextForString(fretText: String) -> String {
        // A note with a string marked should look like "-2-" or "-13"
        // depending on the length of the fret number. Prepend a hyphen
        // and then append enough more to make the total length 3.
        return "-".stringByAppendingString(fretText.stringByPaddingToLength(2, withString: "-", startingAtIndex: 0))
    }
    
    class func getNoteTextForValue(fretNum: Int) -> String {
        return self.getNoteTextForString(fretNum >= 0 ? String(format: "%lu", fretNum) : "-")
    }
    
    func toSerialString() -> String {
        return Array(self.chords.enumerate()).map({
            String(format: "%@%@\n", (self.hasBarAtIndex($0) ? " |" : ""), $1.asText())
        }).joinWithSeparator("")
    }
    
    func toHumanReadableString() -> String {
        var tabString = String()
        var oneLineString = String()
        var chordIndex = 0
        var startingIndexForThisRow = 0
        var stringIndex = 0
        while chordIndex < self.chords.count && stringIndex < self.numStrings {
            let nextPiece: String = VTablature.getNoteTextForValue(self.fretAtIndex(chordIndex, onString: stringIndex)!)
            if (oneLineString.characters.count + nextPiece.characters.count < HUMAN_READABLE_WIDTH ) {
                oneLineString += nextPiece
                chordIndex += 1
            }
            else {
                oneLineString += "\n"
                tabString += oneLineString
                if stringIndex + 1 < self.numStrings {
                    // go to next string, "carriage return" for chord index
                    stringIndex += 1
                    chordIndex = startingIndexForThisRow
                }
                else if chordIndex < self.chords.count {
                    // next line of tab
                    tabString += "\n"
                    startingIndexForThisRow = chordIndex
                    stringIndex = 0
                }
            }
        }
        return tabString
    }
    
    // Iteration
    
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self.chords)
    }
    
    
    // MARK: - Mutators -
    
    // MARK: KVC/KVO and "base" mutators
    
    override public class func automaticallyNotifiesObserversForKey(key: String) -> Bool {
        return false
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            NSLog("VTablature sees a change in a chord's %@!", keyPath!)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    public func insertChord(chord: VChord, atIndex index: Int) {
        self.willChange(NSKeyValueChange.Insertion, valuesAtIndexes: NSIndexSet(index: index), forKey: "chords")
        self.chords.insert(chord, atIndex: index)
        self.didChange(NSKeyValueChange.Insertion, valuesAtIndexes: NSIndexSet(index: index), forKey: "chords")
        chord.addObserver(self, forKeyPath: "notes", options: NSKeyValueObservingOptions(), context: &myContext)
    }
    
    public func insertChords(chords: [VChord], atIndexes indexes: NSIndexSet, andNotify notify: Bool = true) {
        var chordIndex : Int = 0
        if notify {
            self.willChange(NSKeyValueChange.Insertion, valuesAtIndexes: indexes, forKey: "chords")
        }
        indexes.enumerateIndexesWithOptions(NSEnumerationOptions(), usingBlock: {
            (index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            self.chords.insert(chords[chordIndex], atIndex: index)
            chords[chordIndex].addObserver(self, forKeyPath: "notes", options: NSKeyValueObservingOptions(), context: &self.myContext)
            chordIndex += 1
        })
        if notify {
            self.didChange(NSKeyValueChange.Insertion, valuesAtIndexes: indexes, forKey: "chords")
        }
    }
    
    public func removeChordAtIndex(index: Int) {
        self.willChange(NSKeyValueChange.Removal, valuesAtIndexes: NSIndexSet(index: index), forKey: "chords")
        self.chords[index].removeObserver(self, forKeyPath: "notes")
        self.chords.removeAtIndex(index)
        self.didChange(NSKeyValueChange.Removal, valuesAtIndexes: NSIndexSet(index: index), forKey: "chords")
    }
    
    public func removeChordsAtIndexes(indexes: NSIndexSet, andNotify notify: Bool = true) {
        if notify {
            self.willChange(NSKeyValueChange.Removal, valuesAtIndexes: indexes, forKey: "chords")
        }
        indexes.sort(>).forEach({
            self.chords[$0].removeObserver(self, forKeyPath: "notes")
            self.chords.removeAtIndex($0)
        })
        if notify {
            self.didChange(NSKeyValueChange.Removal, valuesAtIndexes: indexes, forKey: "chords")
        }
    }
    
    public func replaceChordsAtIndexes(indexes: NSIndexSet, withChords chords: [VChord]) {
        self.willChange(NSKeyValueChange.Replacement, valuesAtIndexes: indexes, forKey: "chords")
        self.removeChordsAtIndexes(indexes, andNotify: false)
        let indexRange: NSRange = NSMakeRange(indexes.firstIndex, indexes.count)
        self.insertChords(chords, atIndexes:(NSIndexSet(indexesInRange: indexRange)), andNotify: false)
        self.didChange(NSKeyValueChange.Replacement, valuesAtIndexes: indexes, forKey: "chords")
    }
    
    func insertNote(note: VNote, atLocation loc: TabLocation) {
        self.chords[loc.index].removeObserver(self, forKeyPath: "notes")
        self.willChange(NSKeyValueChange.Replacement, valuesAtIndexes: NSIndexSet(index: loc.index), forKey: "chords")
        self.chords[loc.index][loc.string] = note
        self.didChange(NSKeyValueChange.Replacement, valuesAtIndexes: NSIndexSet(index: loc.index), forKey: "chords")
        self.chords[loc.index].addObserver(self, forKeyPath: "notes", options: NSKeyValueObservingOptions(), context: &myContext)
    }
    
    // MARK: Auxiliary mutators
    
    func addChordFromIntArray(intArray: Array<Int>) {
        self.insertChord(VChord.chordWithIntArray(intArray), atIndex: self.chords.count)
    }
    
    func addChordFromString(str: String) {
        self.insertChord(VChord.chordWithStrings(self.numStrings, fromText: str)!, atIndex: self.chords.count)
    }
    
    func insertFret(fret: Int, atIndex index: Int, onString stringNum: Int) {
        self.insertNote(VNote(fret: fret), atLocation: TabLocation(index: index, string: stringNum))
    }
    
    func deleteNoteAtIndex(index: Int, onString stringNum: Int) {
        self.insertNote(VNote.blankNote(), atLocation: TabLocation(index: index, string: stringNum))
    }

    func insertChordFromText(chordText: String, atIndex index: Int) {
        if let newChord: VChord = VChord.chordWithStrings(self.numStrings, fromText: chordText) {
            self.insertChord(newChord, atIndex: index)
        }
    }
    
    func extend() {
        self.addChordFromIntArray([Int](count: self.numStrings, repeatedValue: VNote.NO_FRET()))
    }
    
    func toggleBarAtIndex(index: Int) {
        self.willChangeValueForKey("measureBars")
        if self.measureBars.containsIndex(index) {
            measureBars.removeIndex(index)
        } else {
            measureBars.addIndex(index)
        }
        self.didChangeValueForKey("measureBars")
    }
    
    // MARK: - Pasteboard -
    
    public func writableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
        return [VTABLATURE_DATA_UTI]
    }
    
    public func writingOptionsForType(type: String, pasteboard: NSPasteboard) -> NSPasteboardWritingOptions {
        return NSPasteboardWritingOptions()
    }
    
    public func pasteboardPropertyListForType(type: String) -> AnyObject? {
        if type == VTABLATURE_DATA_UTI {
            return self.toSerialString()
        }
        return nil
    }

    public class func readableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
        return [VTABLATURE_DATA_UTI]
    }
    
    public class func readingOptionsForType(type: String, pasteboard: NSPasteboard) -> NSPasteboardReadingOptions {
        if type == VTABLATURE_DATA_UTI {
            return NSPasteboardReadingOptions.AsString
        }
        return NSPasteboardReadingOptions()
    }
    
    convenience required public init?(pasteboardPropertyList propertyList: AnyObject, ofType type: String) {
        if type != VTABLATURE_DATA_UTI {
            return nil
        }
        guard let tabText = propertyList as? String else {
            return nil
        }
        
        self.init(fromText: tabText)
    }
    
    public func encodeWithCoder(encoder: NSCoder) {
        encoder.encodeObject(self.chords, forKey:"chords")
    }
}