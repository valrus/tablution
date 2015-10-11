//
//  VTabController.swift
//  tablution
//
//  Created by Ian McCowan on 10/6/15.
//
//

import Foundation

let MAX_FRET = 22

@objc public class VTabController: NSViewController, NSApplicationDelegate {

    @IBOutlet weak var tabView: VTabView?
    @IBOutlet weak var currentFretField: NSTextField?
    @IBOutlet weak var chordModeField: NSTextField?
    @IBOutlet var tabDoc: VTabDocument?

    var tablature: VTablature?
    var keyBindings: NSDictionary?

    private var myContext = 0

    // MARK: - Setup -

    func setupKeyBindings() {
        if let plistPath: String = NSBundle.mainBundle().pathForResource("keyBindings", ofType: "plist") {
            keyBindings = NSDictionary(contentsOfFile: plistPath)
            if (keyBindings == nil) {
                NSLog("Edit chars dictionary contains an error!")
            }
        }
        else {
            NSLog("Edit chars dictionary not found!")
        }
    }
    
    public override func awakeFromNib() {
        tabView!.tablature = tabDoc!.tablature
        self.tablature = tabDoc!.tablature
        self.setupKeyBindings()
        tablature!.addObserver(self, forKeyPath:"chords", options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Old], context:&myContext)
        tablature!.addObserver(self, forKeyPath:"bars", options: NSKeyValueObservingOptions(rawValue: 0), context:&myContext)
    }

    // MARK: - Editing selectors -
    // MARK: Chord-level changes
    
    func insertBlankChord() {
        let oneBlankChord: [VChord] = [VChord.chordWithIntArray([Int](count: tablature!.numStrings, repeatedValue: VNote.NO_FRET()))]
        if tabView!.hasSelection() {
            self.replaceSelectedChordsWithChords(oneBlankChord)
        }
        else {
            let focusIndex: UInt = tabView!.focusChordIndexForMode() + 1
            let focusIndexSet: NSIndexSet = NSIndexSet(index: Int(focusIndex))
            self.insertChords(oneBlankChord, atIndexes: focusIndexSet, andSelectThem: false)
        }
    }
    
    func insertChords(chordArray: [VChord], atIndexes indexes: NSIndexSet, andSelectThem doSelect: Bool) {
        if let undoManager = tabDoc!.undoManager as NSUndoManager? {
            undoManager.registerUndoWithTarget(tablature!, selector: Selector("removeChordsAtIndexes"), object: indexes)
            undoManager.setActionName(NSLocalizedString("Insert Chords", comment: "insert chords undo"))
        }
        tablature!.insertChords(chordArray, atIndexes: indexes)
        if doSelect {
            tabView!.selectIndexes(indexes)
        }
    }
    
    func removeChordAtIndex(index: Int) {
        tablature!.removeObjectFromChordsAtIndex(index)
    }

    func deleteSelectedChords() {
        let selectedIndexes: NSIndexSet = tabView!.selectedIndexes()
        if let undoManager = tabDoc!.undoManager as NSUndoManager? {
            undoManager.prepareWithInvocationTarget(self).insertChords(tablature!.chordsAtIndexes(selectedIndexes), atIndexes: selectedIndexes, andSelectThem: true)
            undoManager.setActionName(NSLocalizedString("Delete Selection", comment: "delete selection undo"))
        }
        tablature!.removeChordsAtIndexes(selectedIndexes)
        tabView!.clearSelection()
    }
    
    func replaceSelectedChordsWithChords(chordArray: [VChord]) {
        let insertionRange: NSRange = NSMakeRange(tabView!.selectedIndexes().firstIndex, chordArray.count)
        if let undoManager = tabDoc!.undoManager as NSUndoManager? {
            if let undoTarget = undoManager.prepareWithInvocationTarget(tablature!) as? VTablature {
                undoTarget.replaceChordsAtIndexes(NSIndexSet(indexesInRange: insertionRange), withChords: tabView!.selectedChords() as! [VChord])
            }
            undoManager.setActionName(NSLocalizedString("Replace Selected Chords", comment: "replace selection undo"))
        }
        tablature!.removeChordsAtIndexes(tabView!.selectedIndexes())
        let insertionIndexes: NSIndexSet = NSIndexSet(indexesInRange: insertionRange)
        tablature!.insertChords(chordArray, atIndexes: insertionIndexes)
        tabView!.selectIndexes(insertionIndexes)
    }
    
    func toggleMeasureBar() {
        if let undoManager = tabDoc!.undoManager as NSUndoManager? {
            if let undoTarget = undoManager.prepareWithInvocationTarget(tablature!) as? VTablature {
                undoTarget.toggleBarAtIndex(Int(tabView!.focusChordIndexForMode()))
            }
            undoManager.setActionName(NSLocalizedString("Undo Toggle Measure Bar", comment:"toggle bar undo"))
        }
        tablature!.toggleBarAtIndex(Int(tabView!.focusChordIndexForMode()))
    }
    
    // MARK: Note-level changes
    
    func prepareUndoForChangeFromNote(previousNote: VNote, onString whichString: Int) {
        if let undoManager = tabDoc!.undoManager as NSUndoManager? {
            if let undoTarget = undoManager.prepareWithInvocationTarget(tablature!) as? VTablature {
                undoTarget.insertNote(previousNote, atIndex: Int(tabView!.focusChordIndexForMode()), onString: whichString)
            }
            undoManager.setActionName(NSLocalizedString("Change Note", comment: "change note undo"))
        }
    }
    
    func addOpenString(whichString: NSNumber, reverseString doReverse: Bool) {
        let stringAsInt = whichString.integerValue
        self.addNoteOnString(stringAsInt, onFret: 0, reverseString: doReverse)
    }
    
    func addNoteOnString(whichString: NSNumber, onFret whichFret: NSNumber, reverseString doReverse: Bool) {
        let stringAsInt = whichString.integerValue
        let fretAsInt = whichFret.integerValue
        let stringNum: Int = doReverse ? tablature!.numStrings - stringAsInt - 1 : stringAsInt
        let fretNum: Int = fretAsInt + Int(tabDoc!.baseFret.intValue)
        if stringAsInt < tablature!.numStrings {
            if self.isInSoloMode() {
                let newChord: VChord = VChord.chordWithOneFret(fretNum, onString: stringNum, numStrings: tablature!.numStrings)
                if let undoManager = tabDoc!.undoManager as NSUndoManager? {
                    undoManager.prepareWithInvocationTarget(self).removeChordAtIndex(Int(tabView!.focusChordIndexForMode()) + 1)
                    undoManager.setActionName(NSLocalizedString("Add Solo Note", comment: "add solo note undo"))
                }
                tablature!.insertObject(newChord, inChordsAtIndex: Int(tabView!.focusChordIndexForMode()) + 1)
            }
            else {
                self.prepareUndoForChangeFromNote(tabView!.focusChord()[stringNum]!, onString: stringNum)
                tablature!.insertNote(VNote.noteAtFret(fretNum), atIndex: Int(tabView!.focusChordIndexForMode()), onString: stringNum)
                tabView!.focusNoteString = UInt(stringNum)
            }
        }
    }
    
    func deleteFocusNote() {
        let currentNote: VNote = tabView!.focusNote()
        if currentNote.hasFret() {
            self.prepareUndoForChangeFromNote(currentNote, onString: Int(tabView!.focusNoteString))
            tablature!.deleteNoteAtIndex(Int(tabView!.focusChordIndexForMode()), onString: Int(tabView!.focusNoteString))
        }
    }
    
    // MARK: Mode changes
    
    func incrementBaseFret() {
        let currentFret: Int = Int(tabDoc!.baseFret.intValue)
        if currentFret < MAX_FRET {
            tabDoc!.baseFret = NSNumber(int: currentFret + 1)
        }
    }
    
    func decrementBaseFret() {
        let currentFret: Int = Int(tabDoc!.baseFret.intValue)
        if currentFret > 0 {
            let newFret: Int32 = Int32(currentFret - 1)
            tabDoc!.baseFret = NSNumber(int: newFret)
        }
    }

    func toggleSoloMode() {
        let currentMode: Bool = tabDoc!.soloMode.boolValue
        tabDoc!.soloMode = NSNumber(bool: !currentMode)
        tabView!.clearSelection()
        tabView!.focusNoteString = currentMode ? 0 : 1
    }
    
    // MARK: Focus changes
    
    func focusNextChord() -> Bool {
        if Int(tabView!.focusChordIndexForMode()) < tablature!.countOfChords() - 1 {
            tabView!.focusNextChord()
            return true
        }
        return false
    }
    
    func focusPrevChord() -> Bool {
        if tabView!.currFocusChordIndex > 0 {
            tabView!.focusPrevChord()
            return true
        }
        return false
    }
    
    func focusUpString() -> Bool {
        if tabView!.focusNoteString > 0 {
            tabView!.focusUpString()
            return true
        }
        return false
    }
    
    func focusDownString() -> Bool {
        if Int(tabView!.focusNoteString) < tablature!.numStrings - 1 {
            tabView!.focusDownString()
            return true
        }
        return false
    }
    
    // MARK: Information
    
    func isInSoloMode() -> Bool {
        return tabDoc!.soloMode.boolValue
    }

    // MARK: - AppKit overrides -
    
    // MARK: inputManager
    
    @IBAction override public func moveRight(sender: AnyObject?) {
        self.focusNextChord()
    }
    
    @IBAction override public func moveLeft(sender: AnyObject?) {
        self.focusPrevChord()
    }
    
    @IBAction override public func moveUp(sender: AnyObject?) {
        self.focusUpString()
    }
    
    @IBAction override public func moveDown(sender: AnyObject?) {
        self.focusDownString()
    }
    
    @IBAction override public func deleteForward(sender: AnyObject?) {
        self.deleteFocusNote()
    }
    
    @IBAction override public func deleteBackward(sender: AnyObject?) {
        if tabView!.hasSelection() {
            self.deleteSelectedChords()
        }
        else {
            if tabView!.currFocusChordIndex > 0 {
                if let undoManager = tabDoc!.undoManager as NSUndoManager? {
                    if let undoTarget = undoManager.prepareWithInvocationTarget(tablature!) as? VTablature {
                        undoTarget.insertObject(tablature!.objectInChordsAtIndex(Int(tabView!.focusChordIndexForMode())) as! VChord, inChordsAtIndex: Int(tabView!.focusChordIndexForMode()))
                    }
                    undoManager.setActionName(NSLocalizedString("Delete Chord", comment: "delete chord undo"))
                    tablature!.removeObjectFromChordsAtIndex(Int(tabView!.focusChordIndexForMode()))
                }
            }
        }
    }
    
    // MARK: KVO
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        NSLog("VTabController sees a change in %@!", keyPath!)
        guard let changeDict = change else {
            return
        }
        guard let changeKindNumber = changeDict["kind"] as? NSKeyValueChange else {
            return
        }
        switch changeKindNumber {
        case .Replacement:
            guard let oldChordArray = changeDict[NSKeyValueChangeOldKey] else {
                return
            }
            guard let newChordArray = changeDict[NSKeyValueChangeNewKey] else {
                return
            }
            if oldChordArray.count == 1 && newChordArray.count == 1 {
                let oldChord: VChord = oldChordArray[0] as! VChord
                let newChord: VChord = newChordArray[0] as! VChord
                let changedNotesIndexes: NSIndexSet = newChord.indexesOfChangedNotesFrom(oldChord)!
                if changedNotesIndexes.count == 1 {
                    tabView!.focusNoteString = UInt(changedNotesIndexes.firstIndex)
                }
            }
            
        case .Insertion:
            guard let indexes = changeDict["indexes"] as? NSIndexSet else {
                return
            }
            let indexForFocusAdjustment: Int = Int(tabView!.focusChordIndexForMode()) + (self.isInSoloMode() ? 3 : 2)
            let rangeBeforeFocus: NSRange = NSMakeRange(0, indexForFocusAdjustment)
            let indexesBeforeFocus: Int = indexes.countOfIndexesInRange(rangeBeforeFocus)
            tabView!.currFocusChordIndex = UInt(tabView!.currFocusChordIndex) + UInt(indexesBeforeFocus)
            
        case .Removal:
            guard let indexes = changeDict["indexes"] as? NSIndexSet else {
                return
            }
            var indexForFocusAdjustment: Int = Int(tabView!.focusChordIndexForMode()) + (self.isInSoloMode() ? 1 : 0)
            if Int(tabView!.focusChordIndexForMode()) >= self.tablature!.countOfChords() {
                indexForFocusAdjustment += 1
            }
            let rangeBeforeFocus: NSRange = NSMakeRange(0, indexForFocusAdjustment)
            let indexesBeforeFocus: Int = indexes.countOfIndexesInRange(rangeBeforeFocus)
            tabView!.currFocusChordIndex = UInt(tabView!.currFocusChordIndex) - UInt(indexesBeforeFocus)
            
        default: break
        }
        tabView!.needsDisplay = true
    }
}
