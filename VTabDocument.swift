//
//  VTabDocument.swift
//  tablution
//
//  Created by Ian McCowan on 10/11/15.
//
//

import Foundation

@objc public class VTabDocument: NSDocument {
    
    var tablature: VTablature?
    @IBOutlet weak var controller: VTabController?
    @IBOutlet weak var tabView: VTabView?

    override public var windowNibName: String? {
        get {
            return "TabDocument"
        }
    }

    override init() {
        if tablature == nil {
            tablature = VTablature(numStrings: 6)
            tablature!.addChordFromString("-1 -1 -1 -1 -1 -1")
        }
        super.init()
    }

    override public func windowControllerDidLoadNib(aController: NSWindowController) {
    }

    override public func dataOfType(typeName: String) throws -> NSData {
        var tabText: String = ""
        NSLog("Saving doc of type: %@", typeName)
        if let tab = tablature {
            if typeName.isEqual("com.valrusware.tablature") {
                tabText = tab.toSerialString()
            }
            else if typeName.isEqual("public.plain-text") {
                tabText = tab.toHumanReadableString()
            }
            else {
                throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
            }
        }
        guard let data = tabText.dataUsingEncoding(NSUTF8StringEncoding) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        return data
    }

    override public func readFromData(data: NSData, ofType typeName: String) throws {
        if let tabText: String = String(data: data, encoding: NSUTF8StringEncoding) {
            self.tablature = VTablature.tablatureFromText(tabText)
        }
        else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
    }

    @IBAction func copy(sender: AnyObject) {
        guard let selectedChords = tabView!.selectedChords() as? [VChord] else {
            return
        }
        guard selectedChords.count != 0 else {
            return
        }
        let pasteboard: NSPasteboard = NSPasteboard.generalPasteboard()
        pasteboard.clearContents()
        let tabWithSelection: VTablature = VTablature.tablatureWithChords(selectedChords)
        pasteboard.writeObjects([tabWithSelection])
    }

    @IBAction func paste(sender: AnyObject) {
        let pasteboard: NSPasteboard = NSPasteboard.generalPasteboard()
        if pasteboard.canReadObjectForClasses([VTablature.self], options: Dictionary()) {
            guard let objectsToPaste = pasteboard.readObjectsForClasses([VTablature.self], options: Dictionary()) as? [VTablature] else {
                return
            }
            let tabToPaste: VTablature = objectsToPaste[0]
            if tabView!.hasSelection() {
                controller!.replaceSelectedChordsWithChords(tabToPaste.chords)
            }
            else {
                let indexRange: NSRange = NSMakeRange(Int(tabView!.currFocusChordIndex), tabToPaste.countOfChords())
                controller!.insertChords(tabToPaste.chords, atIndexes: NSIndexSet(indexesInRange: indexRange), andSelectThem: true)
            }
        }
    }

    @IBAction func cut(sender: AnyObject) {
        self.copy(sender)
        controller!.deleteSelectedChords()
    }
}