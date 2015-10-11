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
    
    func addOpenString(whichString: Int, reverseString doReverse: Bool) {
        self.addNoteOnString(whichString, onFret: 0, reverseString: doReverse)
    }
    
    func addNoteOnString(whichString: Int, onFret whichFret: Int, reverseString doReverse: Bool) {
        var stringNum: Int = doReverse ? tablature!.numStrings - whichString - 1 : whichString
        var fretNum: Int = whichFret + Int(tabDoc!.baseFret.intValue)
        if whichString < tablature!.numStrings {
            if self.isInSoloMode() {
                var newChord: VChord = VChord.chordWithOneFret(fretNum, onString: stringNum, numStrings: tablature!.numStrings)
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
}
