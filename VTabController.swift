//
//  VTabController.swift
//  tablution
//
//  Created by Ian McCowan on 10/6/15.
//
//

import Foundation

let MAX_FRET = 22

@objc public class VTabController: NSViewController {

    @IBOutlet weak var tabView: VTabView?
    @IBOutlet weak var currentFretField: NSTextField?
    @IBOutlet weak var chordModeField: NSTextField?
    
    dynamic var baseFret: Int = 0
    dynamic var soloMode: Bool = false

    weak var tablature: VTablature?
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
        self.setupKeyBindings()
    }
    
    public override func viewDidLoad() {
        if let appDelegate: VTablutionDelegate = NSApplication.sharedApplication().delegate as? VTablutionDelegate {
            appDelegate.viewController = self
        }
    }
    
    public func setupTablature(tablature: VTablature) {
        self.tablature = tablature
        tabView!.tablature = tablature
        tablature.addObserver(self, forKeyPath:"chords", options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Old], context:&myContext)
        tablature.addObserver(self, forKeyPath:"bars", options: NSKeyValueObservingOptions(rawValue: 0), context:&myContext)
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
        if let undoManager = self.undoManager as NSUndoManager? {
            undoManager.registerUndoWithTarget(self, selector: Selector("deleteChordsAtIndexes:"), object: indexes)
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
    
    func deleteChordsAtIndexes(indexes: NSIndexSet) {
        if let undoManager = self.undoManager as NSUndoManager? {
            undoManager.prepareWithInvocationTarget(self).insertChords(tablature!.chordsAtIndexes(indexes), atIndexes: indexes, andSelectThem: true)
            undoManager.setActionName(NSLocalizedString("Delete Selection", comment: "delete selection undo"))
        }
        tablature!.removeChordsAtIndexes(indexes)
        tabView!.clearSelection()
    }

    func deleteSelectedChords() {
        let selectedIndexes: NSIndexSet = tabView!.selectedIndexes()
        deleteChordsAtIndexes(selectedIndexes)
    }
    
    func replaceChordsAtIndexes(indexes: NSIndexSet, withChords chords: [VChord]) {
        tablature!.replaceChordsAtIndexes(indexes, withChords: chords)
    }
    
    func replaceSelectedChordsWithChords(chordArray: [VChord]) {
        let insertionRange: NSRange = NSMakeRange(tabView!.selectedIndexes().firstIndex, chordArray.count)
        let insertionIndexes: NSIndexSet = NSIndexSet(indexesInRange: insertionRange)
        if let undoManager = self.undoManager as NSUndoManager? {
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
        if let undoManager = self.undoManager as NSUndoManager? {
            undoManager.registerUndoWithTarget(self, selector: Selector("toggleBarAtIndex:"), object: NSNumber(integer: barIndex))
            undoManager.setActionName(NSLocalizedString("Undo Toggle Measure Bar", comment:"toggle bar undo"))
        }
        self.toggleBarAtIndex(barIndex)
    }
    
    // MARK: Note-level changes
    
    func prepareUndoForChangeFromNote(atLocation loc: TabLocation) {
        guard let undoManager = self.undoManager as NSUndoManager? else {
            return
        }
        guard let note = tablature!.noteAtLocation(loc) else {
            return
        }
        let undoTarget = undoManager.prepareWithInvocationTarget(self)
        undoTarget.addNoteAtIndex(note, atIndex: loc.index, onString: loc.string)
        undoManager.setActionName(NSLocalizedString("Change Note", comment: "change note undo"))
    }
    
    func addOpenString(whichString: NSNumber, reverseString doReverse: Bool) {
        let stringAsInt = whichString.integerValue
        self.addNoteAtFocus(onString: stringAsInt, onFret: 0, reverseString: doReverse)
    }
    
    // Ugh. This is just here because we can't use addNote from an undoManager
    // since it involves a struct which is inaccessible from Obj-C.
    func addNoteAtIndex(note: VNote, atIndex index: Int, onString whichString: Int) {
        self.addNote(note, atLocation: TabLocation(index: index, string: whichString))
    }
    
    func addNote(note: VNote, atLocation loc: TabLocation) {
        self.prepareUndoForChangeFromNote(atLocation: loc)
        tablature!.insertNote(note, atLocation: loc)
    }
    
    func addNoteAtFocus(onString whichString: NSNumber, onFret whichFret: NSNumber, reverseString doReverse: Bool) {
        // FIXME: I don't like this doReverse stuff; rather just set the right numbers in keyBindings.plist
        let stringNum: Int = doReverse ? tablature!.numStrings - whichString.integerValue - 1 : whichString.integerValue
        let fretNum: Int = whichFret.integerValue + baseFret
        guard let focusIndex = tabView?.currFocusChordIndex else {
            return
        }
        if whichString.integerValue < tablature!.numStrings {
            if self.isInSoloMode() {
                let newChord: VChord = VChord.chordWithOneFret(fretNum, onString: stringNum, numStrings: tablature!.numStrings)
                self.insertChords([newChord], atIndexes: NSIndexSet(index: focusIndex), andSelectThem: false)
            }
            else {
                self.addNote(VNote.noteAtFret(fretNum), atLocation: TabLocation(index: focusIndex, string: stringNum))
                tabView!.focusNoteString = stringNum
            }
        }
    }
    
    func deleteFocusNote() {
        let currentNote: VNote = tabView!.focusNote()
        if currentNote.hasFret() {
            self.prepareUndoForChangeFromNote(atLocation: TabLocation(index: tabView!.currFocusChordIndex, string: tabView!.focusNoteString))
            tablature!.deleteNoteAtIndex(Int(tabView!.currFocusChordIndex), onString: Int(tabView!.focusNoteString))
        }
    }
    
    func prepareUndoForNoteMarkChange(beforeNote: VNote, markType: MarkType) {
        guard let undoManager = self.undoManager as NSUndoManager? else {
            return
        }
        guard let undoTarget = undoManager.prepareWithInvocationTarget(self) as? VTabController else {
            return
        }
        undoTarget.changeMarkForNote(beforeNote, toChar: markType == .Pre ? beforeNote.preMark.rawValue : beforeNote.postMark.rawValue)
        undoManager.setActionName(NSLocalizedString("Change Note", comment: "change note undo"))
    }
    
    func changeMarkForNote(note: VNote, toChar markChar: Character) {
        guard let markType = determineMarkType(markChar) as MarkType? else {
            // FIXME: error?
            return
        }
        if note.hasFret() {
            self.prepareUndoForNoteMarkChange(note, markType: markType)
            note.setMark(markChar)
        }
    }
    
    func changeFocusNoteMark(markCharString: String) {
        if markCharString.characters.count == 1 {
            changeMarkForNote(tabView!.focusNote(), toChar: Character(markCharString))
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
            if let undoManager = self.undoManager as NSUndoManager? {
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
