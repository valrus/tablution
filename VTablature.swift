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

@objc public class VTablature: NSObject, SequenceType, NSPasteboardWriting, NSPasteboardReading {
    dynamic var chords: Array<VChord>
    private var measureBars: NSMutableIndexSet
    
    var numStrings: Int
    
    // https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/AdoptingCocoaDesignPatterns.html
    private var myContext = 0

    // MARK: Initializers and deinitializers
    
    init(numStrings: Int = 6, withChords chords: [VChord], withBarsAtIndexes barIndexes: NSMutableIndexSet) {
        self.numStrings = numStrings
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
    
    // MARK: KVC/KVO methods
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            NSLog("VTablature sees a change in a chord's %@!", keyPath!)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    public func insertObject(chord: VChord, inChordsAtIndex index: Int) {
        self.chords.insert(chord, atIndex: index)
        chord.addObserver(self, forKeyPath: "notes", options: NSKeyValueObservingOptions(), context: &myContext)
    }
    
    public override func insertValue(value: AnyObject, atIndex index: Int, inPropertyWithKey key: String) {
        if key == "chords" {
            if let chord = value as? VChord {
                self.insertObject(chord, inChordsAtIndex: index)
            }
        }
    }
    
    public func insertChords(chords: [VChord], atIndexes indexes: NSIndexSet) {
        var chordIndex : Int = 0
        indexes.enumerateIndexesWithOptions(NSEnumerationOptions(), usingBlock: {
            (index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            self.insertValue(chords[chordIndex], atIndex: index, inPropertyWithKey: "chords")
            chordIndex += 1
        })
    }
    
    public func objectInChordsAtIndex(index: Int) -> AnyObject {
        return self.chords[index]
    }

    public override func valueAtIndex(index: Int, inPropertyWithKey key: String) -> AnyObject? {
        if key == "notes" {
            return self.chords[index]
        }
        return nil
    }
    
    public func chordsAtIndexes(indexes: NSIndexSet) -> Array<VChord> {
        return (self.chords as NSArray).objectsAtIndexes(indexes) as! Array<VChord>
    }

    public func removeObjectFromChordsAtIndex(index: Int) {
        self.chords.removeAtIndex(index)
    }
    
    public override func removeValueAtIndex(index: Int, fromPropertyWithKey key: String) {
        if key == "notes" {
            self.removeObjectFromChordsAtIndex(index)
        }
    }
    
    public func removeChordsAtIndexes(indexes: NSIndexSet) {
        indexes.sort(>).forEach({ self.chords.removeAtIndex($0) })
    }
    
    public func replaceChordsAtIndexes(indexes: NSIndexSet, withChords chords: [VChord]) {
        self.removeChordsAtIndexes(indexes)
        let indexRange: NSRange = NSMakeRange(indexes.firstIndex, indexes.count)
        self.insertChords(chords, atIndexes:(NSIndexSet(indexesInRange: indexRange)))
    }
    
    public func replaceValuesAtIndexes(indexes: NSIndexSet, inPropertyWithKey key: String, withValue value: AnyObject) {
        if key == "chords" {
            if let chords = value as? [VChord] {
                self.replaceChordsAtIndexes(indexes, withChords: chords)
            }
        }
    }
    
    public func countOfChords() -> Int {
        return chords.count
    }
    
    public func hasBarAtIndex(index: Int) -> Bool {
        return measureBars.containsIndex(index)
    }
    
    public func noteAtIndex(index: Int, onString stringNum: Int) -> VNote? {
        if index < self.chords.count && stringNum < self.numStrings {
            return self.chords[index][stringNum]
        }
        return nil
    }
    
    public func fretAtIndex(index: Int, onString stringNum: Int) -> Int? {
        if let note = self.noteAtIndex(index, onString: stringNum) {
            return note.fret
        }
        return nil
    }
    
    func addChordFromIntArray(intArray: Array<Int>) {
        self.insertValue(VChord.chordWithIntArray(intArray), atIndex: self.chords.count, inPropertyWithKey: "chords")
    }
    
    func addChordFromString(str: String) {
        self.insertValue(VChord.chordWithStrings(self.numStrings, fromText: str)!, atIndex: self.chords.count, inPropertyWithKey: "chords")
    }
    
    func insertNote(note: VNote, atIndex index: Int, onString stringNum: Int) {
        self.chords[index].removeObserver(self, forKeyPath: "notes")
        self.willChange(NSKeyValueChange.Replacement, valuesAtIndexes: NSIndexSet(index: index), forKey: "chords")
        self.chords[index][stringNum] = note
        self.didChange(NSKeyValueChange.Replacement, valuesAtIndexes: NSIndexSet(index: index), forKey: "chords")
        self.chords[index].addObserver(self, forKeyPath: "notes", options: NSKeyValueObservingOptions(), context: &myContext)
    }
    
    func insertFret(fret: Int, atIndex index: Int, onString stringNum: Int) {
        self.insertNote(VNote(fret: fret), atIndex: index, onString: stringNum)
    }
    
    func deleteNoteAtIndex(index: Int, onString stringNum: Int) {
        self.insertNote(VNote.blankNote(), atIndex: index, onString: stringNum)
    }

    func insertChordFromText(chordText: String, atIndex index: Int) {
        if let newChord: VChord = VChord.chordWithStrings(self.numStrings, fromText: chordText) {
            self.insertValue(newChord, atIndex: index, inPropertyWithKey: "notes")
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
    
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self.chords)
    }
    
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