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
    
    dynamic var baseFret: Int = 0
    dynamic var soloMode: Bool = false

    var tablature: VTablature?
    var keyBindings: NSDictionary?

    private var myContext = 0

    // MARK: - Setup -
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let transformer: NSValueTransformer = VEditModeTransformer()
        NSValueTransformer.setValueTransformer(transformer, forName: "editModeTransformer")
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        baseFret = 0
        soloMode = false
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
            let focusIndex: Int = tabView!.currFocusChordIndex + 1
            let focusIndexSet: NSIndexSet = NSIndexSet(index: focusIndex)
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
        tabView!.needsDisplay = true
    }
    
    func removeChordAtIndex(index: Int) {
        tablature!.removeChordAtIndex(index)
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
    
    func replaceChordsAtIndexes(indexes: NSIndexSet, withChords chords: [VChord]) {
        tablature!.replaceChordsAtIndexes(indexes, withChords: chords)
    }
    
    func replaceSelectedChordsWithChords(chordArray: [VChord]) {
        let insertionRange: NSRange = NSMakeRange(tabView!.selectedIndexes().firstIndex, chordArray.count)
        let insertionIndexes: NSIndexSet = NSIndexSet(indexesInRange: insertionRange)
        if let undoManager = tabDoc!.undoManager as NSUndoManager? {
            let undoTarget = undoManager.prepareWithInvocationTarget(self)
            undoTarget.replaceChordsAtIndexes(insertionIndexes, withChords: tabView!.selectedChords() as! [VChord])
            undoManager.setActionName(NSLocalizedString("Replace Selected Chords", comment: "replace selection undo"))
        }
        tablature!.removeChordsAtIndexes(tabView!.selectedIndexes())
        tablature!.insertChords(chordArray, atIndexes: insertionIndexes)
        tabView!.selectIndexes(insertionIndexes)
    }
    
    func toggleBarAtIndex(index: NSNumber) {
        tablature!.toggleBarAtIndex(index.integerValue)
        tabView!.needsDisplay = true
    }
    
    func toggleMeasureBar() {
        let barIndex = Int(tabView!.currFocusChordIndex)
        if let undoManager = tabDoc!.undoManager as NSUndoManager? {
            undoManager.registerUndoWithTarget(self, selector: Selector("toggleBarAtIndex:"), object: NSNumber(integer: barIndex))
            undoManager.setActionName(NSLocalizedString("Undo Toggle Measure Bar", comment:"toggle bar undo"))
        }
        self.toggleBarAtIndex(barIndex)
    }
    
    // MARK: Note-level changes
    
    func prepareUndoForChangeFromNote(previousNote: VNote, onString whichString: Int) {
        if let undoManager = tabDoc!.undoManager as NSUndoManager? {
            let undoTarget = undoManager.prepareWithInvocationTarget(self)
            undoTarget.addNoteOnString(whichString, onFret: previousNote.fret, reverseString: false)
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
        let fretNum: Int = fretAsInt + baseFret
        if stringAsInt < tablature!.numStrings {
            if self.isInSoloMode() {
                let newChord: VChord = VChord.chordWithOneFret(fretNum, onString: stringNum, numStrings: tablature!.numStrings)
                if let undoManager = tabDoc!.undoManager as NSUndoManager? {
                    undoManager.prepareWithInvocationTarget(self).removeChordAtIndex(Int(tabView!.currFocusChordIndex) + 1)
                    undoManager.setActionName(NSLocalizedString("Add Solo Note", comment: "add solo note undo"))
                }
                tablature!.insertChord(newChord, atIndex: Int(tabView!.currFocusChordIndex))
            }
            else {
                self.prepareUndoForChangeFromNote(tabView!.focusChord()[stringNum]!, onString: stringNum)
                tablature!.insertNote(VNote.noteAtFret(fretNum), atIndex: Int(tabView!.currFocusChordIndex), onString: stringNum)
                tabView!.focusNoteString = stringNum
            }
        }
    }
    
    func deleteFocusNote() {
        let currentNote: VNote = tabView!.focusNote()
        if currentNote.hasFret() {
            self.prepareUndoForChangeFromNote(currentNote, onString: Int(tabView!.focusNoteString))
            tablature!.deleteNoteAtIndex(Int(tabView!.currFocusChordIndex), onString: Int(tabView!.focusNoteString))
        }
    }
    
    // MARK: Mode changes
    
    func incrementBaseFret() {
        let currentFret: Int = baseFret
        if currentFret < MAX_FRET {
            baseFret = currentFret + 1
        }
    }
    
    func decrementBaseFret() {
        let currentFret: Int = baseFret
        if currentFret > 0 {
            baseFret = currentFret - 1
        }
    }

    func toggleSoloMode() {
        self.willChangeValueForKey("soloMode")
        let currentMode: Bool = soloMode.boolValue
        soloMode = !currentMode
        self.didChangeValueForKey("soloMode")
        tabView!.clearSelection()
        tabView!.focusNoteString = currentMode ? 0 : 1
    }
    
    // MARK: Focus changes
    
    func focusNextChord() -> Bool {
        if Int(tabView!.currFocusChordIndex) < tablature!.countOfChords() - 1 {
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
        return soloMode.boolValue
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
            guard let view = tabView else {
                return
            }
            guard view.currFocusChordIndex > 0 else {
                return
            }
            let chordIndexToDelete: Int = Int(view.currFocusChordIndex) - 1
            if let undoManager = tabDoc!.undoManager as NSUndoManager? {
                let indexes = NSIndexSet(index: chordIndexToDelete)
                let undoTarget = undoManager.prepareWithInvocationTarget(self)
                undoTarget.insertChords(tablature!.chordsAtIndexes(indexes), atIndexes: indexes, andSelectThem: false)
                undoManager.setActionName(NSLocalizedString("Delete Chord", comment: "delete chord undo"))
                tablature!.removeChordAtIndex(chordIndexToDelete)
            }
        }
    }
    
    // MARK: KVO
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        NSLog("VTabController sees a change in %@!", keyPath!)
        guard let changeDict = change else {
            return
        }
        guard let changeKindNumber = changeDict["kind"] as? NSNumber else {
            return
        }
        guard let changeKind = NSKeyValueChange(rawValue: UInt(changeKindNumber.integerValue)) as NSKeyValueChange? else {
            return
        }
        switch changeKind {
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
                    tabView!.focusNoteString = changedNotesIndexes.firstIndex
                }
            }
            
        case .Insertion:
            guard let indexes = changeDict["indexes"] as? NSIndexSet else {
                return
            }
            let indexForFocusAdjustment: Int = Int(tabView!.currFocusChordIndex) + (self.isInSoloMode() ? 3 : 2)
            let rangeBeforeFocus: NSRange = NSMakeRange(0, indexForFocusAdjustment)
            let indexesBeforeFocus: Int = indexes.countOfIndexesInRange(rangeBeforeFocus)
            tabView!.currFocusChordIndex = tabView!.currFocusChordIndex + indexesBeforeFocus
            
        case .Removal:
            guard let indexes = changeDict["indexes"] as? NSIndexSet else {
                return
            }
            var indexForFocusAdjustment: Int = Int(tabView!.currFocusChordIndex) + (self.isInSoloMode() ? 1 : 0)
            if Int(tabView!.currFocusChordIndex) >= self.tablature!.countOfChords() {
                indexForFocusAdjustment += 1
            }
            let rangeBeforeFocus: NSRange = NSMakeRange(0, indexForFocusAdjustment)
            let indexesBeforeFocus: Int = indexes.countOfIndexesInRange(rangeBeforeFocus)
            tabView!.currFocusChordIndex = tabView!.currFocusChordIndex - indexesBeforeFocus
            
        default: break
        }
        tabView!.needsDisplay = true
    }
}
