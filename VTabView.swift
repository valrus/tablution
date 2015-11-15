//
//  VTabView.swift
//  tablution
//
//  Created by Ian McCowan on 11/1/15.
//
//

import Foundation

let STRING_SPACE: CGFloat = 14.0
let LINE_SPACE: CGFloat = 24.0
let LEFT_MARGIN: CGFloat = 16.0
let RIGHT_MARGIN: CGFloat = 16.0
let TOP_MARGIN: CGFloat = 16.0
let LINE_WIDTH: CGFloat = 2.0
let CHORD_SPACE: CGFloat = 24.0

@objc public class VTabView: NSView {
    @IBOutlet weak var tabController: VTabController?
    var selectionManager: TLSelectionManager?
    var lastFocusChordIndex: Int = 0
    var currFocusChordIndex: Int = 0
    var focusNoteString: Int = 0
    var mouseDownEvent: NSEvent?
    var tablature: VTablature?
    public override var acceptsFirstResponder: Bool {
        get { return true }
    }
    public override var flipped: Bool {
        get { return true }
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        guard let selectionManager = TLSelectionManager() as TLSelectionManager? else {
            fatalError("Couldn't initialize selection manager")
        }
        selectionManager.delegate = self
        selectionManager.selectIndexes(NSIndexSet(), byExtendingSelection: false)
        self.selectionManager = selectionManager
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func awakeFromNib() {
        tabController!.nextResponder = self.nextResponder
        self.nextResponder = tabController
        currFocusChordIndex = 0
        focusNoteString = 0
        needsDisplay = true
    }
    
    private func drawOneLineOfStringsAtHeight(stringHeight: CGFloat, withSpaceFor lineLength: Int) -> CGFloat {
        var startPoint: NSPoint
        var endPoint: NSPoint
        var stringNum: Int
        var newStringHeight: CGFloat = stringHeight
        NSBezierPath.setDefaultLineWidth(LINE_WIDTH)
        NSColor.lightGrayColor().setStroke()
        for stringNum = 0; stringNum < tablature!.numStrings && stringHeight < self.bounds.size.height; stringNum++ {
            startPoint = NSMakePoint(LEFT_MARGIN, newStringHeight)
            endPoint = NSMakePoint(LEFT_MARGIN + (CGFloat(lineLength) * CHORD_SPACE), newStringHeight)
            NSBezierPath.strokeLineFromPoint(startPoint, toPoint: endPoint)
            newStringHeight += STRING_SPACE
        }
        return stringHeight
    }

    func drawFocusRectForChordAtPoint(origin: NSPoint, inColor strokeColor: NSColor) {
        var size: NSSize
        var rectRadius: CGFloat
        var newOrigin: NSPoint = origin
        if tabController!.isInSoloMode() {
            size = NSMakeSize(1.0, self.lineHeight())
            newOrigin = NSMakePoint(origin.x - 1.0, origin.y)
            rectRadius = 1.0
        }
        else {
            size = NSMakeSize(CHORD_SPACE, self.lineHeight())
            rectRadius = 3.0
        }
        let focusRect: NSRect = NSRect(origin: newOrigin, size: size)
        let focusPath: NSBezierPath = NSBezierPath(roundedRect: focusRect, xRadius: rectRadius, yRadius: rectRadius)
        strokeColor.colorWithAlphaComponent(0.5).setStroke()
        focusPath.stroke()
    }

    func drawChord(chord: VChord, withCornerAt topLeft: NSPoint, normalStyle tabAttrs: [String : AnyObject], focusedStyle focusNoteAttrs: [String : AnyObject]) {
        var topLeftForDrawing = topLeft
        for note in chord.notes {
            let focused: Bool = (note === self.focusNote())
            let attrsToUse: [String : AnyObject] = focused ? focusNoteAttrs : tabAttrs
            let text: String = note.hasFret() ? note.stringValue() : "•"
            if note.hasFret() || focused {
                text.drawAtPoint(NSMakePoint(topLeftForDrawing.x + CHORD_SPACE / 3, topLeftForDrawing.y), withAttributes: attrsToUse)
            }
            topLeftForDrawing.y += STRING_SPACE
        }
    }
    
    func drawSelectionForChordRange(chordRange: NSRange, withTopLeftAt topLeft: NSPoint, usingColor selectionColor: NSColor) {
        let thisRangeSelection: NSIndexSet = selectionManager!.selectedIndexes.indexesInRange(chordRange, options: NSEnumerationOptions(),
            passingTest: {(idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in return true })
        let thisRowRange: NSRange = NSMakeRange(thisRangeSelection.firstIndex - chordRange.location,
            thisRangeSelection.lastIndex - thisRangeSelection.firstIndex + 1)
        let selectRect: NSRect = NSRect(
            origin: NSMakePoint(topLeft.x + CGFloat(thisRowRange.location) * CHORD_SPACE, topLeft.y),
            size: NSMakeSize(CGFloat(thisRowRange.length) * CHORD_SPACE, self.lineHeight())
        )
        let selectionPath: NSBezierPath = NSBezierPath(roundedRect: selectRect, xRadius: 3.0, yRadius: 3.0)
        selectionColor.colorWithAlphaComponent(0.3).setFill()
        selectionPath.fill()
    }
    
    func drawMeasureBarAfterChordAtPoint(topLeft: NSPoint) {
        NSBezierPath.setDefaultLineWidth(LINE_WIDTH)
        NSColor.blackColor().setStroke()
        let startPoint: NSPoint = NSMakePoint(topLeft.x + CHORD_SPACE, topLeft.y)
        let endPoint: NSPoint = NSMakePoint(topLeft.x + CHORD_SPACE, topLeft.y + self.lineHeight())
        NSBezierPath.strokeLineFromPoint(startPoint, toPoint: endPoint)
    }
    
    func drawOneLineOfTabAtHeight(tabHeight: CGFloat, fromChordNumber firstChord: Int, numberOfChords numChords: Int) {
        var currentCoords: NSPoint = NSMakePoint(LEFT_MARGIN, tabHeight)
        var chordNum: Int = firstChord
        let tabAttrs: [String : AnyObject] = [:]
        var focusNoteAttrs: [String : AnyObject] = tabAttrs
        focusNoteAttrs[NSForegroundColorAttributeName] = NSColor.redColor()
        focusNoteAttrs[NSStrokeWidthAttributeName] = NSNumber(float: -6.0)
        let selectionColor: NSColor = NSColor.blueColor()
        if self.hasSelection() {
            selectionColor.set()
            self.drawSelectionForChordRange(NSMakeRange(firstChord, numChords), withTopLeftAt: currentCoords, usingColor: selectionColor)
        }
        for chordNum = firstChord; chordNum < firstChord + numChords; ++chordNum {
            let chord: VChord = tablature!.objectInChordsAtIndex(chordNum) as! VChord
            self.drawChord(chord, withCornerAt: currentCoords, normalStyle: tabAttrs, focusedStyle: focusNoteAttrs)
            if tablature!.hasBarAtIndex(chordNum) {
                self.drawMeasureBarAfterChordAtPoint(currentCoords)
            }
            currentCoords.y = tabHeight
            if chordNum == self.currFocusChordIndex {
                self.drawFocusRectForChordAtPoint(currentCoords, inColor: selectionColor)
            }
            currentCoords.x += CHORD_SPACE
        }
        if self.currFocusChordIndex == tablature!.countOfChords() {
            self.drawFocusRectForChordAtPoint(currentCoords, inColor: selectionColor)
        }
    }
    
    func drawTabWithGraphicsContext(theContext: NSGraphicsContext) {
        var stringHeight: CGFloat = TOP_MARGIN
        var tabHeight: CGFloat = TOP_MARGIN
        var chordsAccommodated: Int = 0
        var lineLength: Int = 0
        let chordsPerLine: Int = Int(self.chordsPerLine())
        repeat {
            if chordsAccommodated + chordsPerLine > tablature!.countOfChords() {
                lineLength = tablature!.countOfChords() - chordsAccommodated
            }
            else {
                lineLength = chordsPerLine
            }
            tabHeight = stringHeight - NSFont.userFontOfSize(12.0)!.xHeight
            stringHeight = self.drawOneLineOfStringsAtHeight(stringHeight, withSpaceFor: lineLength) + LINE_SPACE
            self.drawOneLineOfTabAtHeight(tabHeight, fromChordNumber: chordsAccommodated, numberOfChords: lineLength)
            chordsAccommodated += lineLength
        } while chordsAccommodated < tablature!.countOfChords() && stringHeight + self.lineHeight() <= self.bounds.size.height
    }
    
    public override func drawRect(dirtyRect: NSRect) {
        let startGraphicsContext: NSGraphicsContext = NSGraphicsContext.currentContext()!
        startGraphicsContext.saveGraphicsState()
        NSColor.whiteColor().setFill()
        NSRectFill(dirtyRect)
        self.drawTabWithGraphicsContext(startGraphicsContext)
        startGraphicsContext.restoreGraphicsState()
    }
    
    func chordsPerLine() -> CGFloat {
        return (self.bounds.size.width - LEFT_MARGIN - RIGHT_MARGIN) / CHORD_SPACE
    }
    
    func lineHeight() -> CGFloat {
        return (CGFloat(tablature!.numStrings) - 0.5) * (STRING_SPACE + LINE_WIDTH)
    }
    
    func chordAtPoint(thePoint: NSPoint) -> VChord? {
        if let chordIndex: Int = self.chordIndexAtPoint(thePoint) {
            if (tablature!.countOfChords() > chordIndex) {
                return tablature!.objectInChordsAtIndex(chordIndex) as? VChord
            }
        }
        return nil
    }
    
    func chordIndexAtPoint(thePoint: NSPoint) -> Int? {
        let x: CGFloat = sandwich(lower: LEFT_MARGIN, num: thePoint.x, upper: self.chordsPerLine() * CHORD_SPACE) - LEFT_MARGIN
        let y: CGFloat = sandwich(lower: TOP_MARGIN, num: thePoint.y, upper: self.bounds.size.height) - TOP_MARGIN
        let skipLines: CGFloat = (y / (self.lineHeight() + LINE_SPACE))
        if (y % skipLines) > self.lineHeight() {
            return nil
        }
        else {
            let skipChords: Int = Int(x / CHORD_SPACE)
            let chordIndex: Int = Int(skipLines * self.chordsPerLine()) + skipChords
            NSLog("Chord index: %lu", chordIndex)
            return chordIndex
        }
    }
    
    func noteAtPoint(thePoint: NSPoint) -> VNote? {
        if let theChord = self.chordAtPoint(thePoint) as VChord? {
            return theChord[self.stringAtPoint(thePoint)]
        }
        else {
            return nil
        }
    }
    
    func stringAtPoint(thePoint: NSPoint) -> Int {
        var y: CGFloat = thePoint.y - TOP_MARGIN
        y -= (y / (self.lineHeight() + LINE_SPACE)) * (self.lineHeight() + LINE_SPACE)
        let whichString: Int = min(Int(y / STRING_SPACE), tablature!.numStrings - 1)
        NSLog("Clicked string: %lu, y = %f", whichString, y)
        return whichString
    }
    
    func hasSelection() -> Bool {
        if let selection: TLSelectionManager = selectionManager as TLSelectionManager? {
            return selection.selectedIndexes.count > 0
        }
        return false
    }
    
    func selectedIndexes() -> NSIndexSet {
        if let selection: TLSelectionManager = selectionManager as TLSelectionManager? {
            return selection.selectedIndexes
        }
        return NSIndexSet()
    }
    
    func selectedChords() -> [AnyObject] {
        if self.selectedIndexes().count > 0 {
            return tablature!.chordsAtIndexes(self.selectedIndexes())
        }
        else {
            return []
        }
    }
    
    func selectIndexes(indexes: NSIndexSet) {
        selectionManager!.selectIndexes(indexes, byExtendingSelection: false)
    }
    
    func clearSelection() {
        selectionManager!.selectIndexes(NSIndexSet(), byExtendingSelection: false)
    }
    
    // MARK: - Focus handling -
    
    // MARK: Accessors
    
    func focusChord() -> VChord {
        return tablature!.objectInChordsAtIndex(currFocusChordIndex) as! VChord
    }
    
    func focusNote() -> VNote {
        if tabController!.isInSoloMode() {
            return VNote.noteAtFret(VNote.NO_FRET())
        }
        else {
            return self.focusChord()[focusNoteString]!
        }
    }
    
    // MARK: Mutators
    
    func focusNextChord() {
        currFocusChordIndex++
        self.clearSelection()
    }
    
    func focusPrevChord() {
        currFocusChordIndex--
        self.clearSelection()
    }
    
    func focusUpString() {
        focusNoteString--
    }
    
    func focusDownString() {
        focusNoteString++
    }
    
    func reFocusAtPoint(thePoint: NSPoint) {
        var currFocusChordIndex = self.chordIndexAtPoint(thePoint)!
        if currFocusChordIndex >= tablature!.countOfChords() {
            currFocusChordIndex = tablature!.countOfChords() - 1
        }
        focusNoteString = self.stringAtPoint(thePoint)
        self.needsDisplay = true
    }
    
    // MARK: - Input handling -
    
    func handleBoundKey(keyString: String) {
        guard let actionParts = tabController!.keyBindings!.objectForKey(keyString) as? NSArray else {
            return
        }
        let selectorString: String = actionParts.objectAtIndex(0) as! String
        let editSelector: Selector = NSSelectorFromString(selectorString)
        switch actionParts.count {
        case 1:
            tabController!.performSelector(editSelector)
        case 2:
            if selectorString == "addOpenString:" {
                tabController!.addOpenString(actionParts.objectAtIndex(1) as! NSNumber, reverseString: true)
            }
            else {
                tabController!.performSelector(editSelector, withObject: actionParts.objectAtIndex(1))
            }
        case 3:
            if selectorString == "addNoteOnString:onFret:" {
                tabController!.addNoteOnString(actionParts.objectAtIndex(1) as! NSNumber, onFret: actionParts.objectAtIndex(2) as! NSNumber, reverseString: true)
            }
            else {
                tabController!.performSelector(editSelector, withObject: actionParts.objectAtIndex(1), withObject: actionParts.objectAtIndex(2))
            }
        default:
            return
        }
    }
    
    public override func keyDown(theEvent: NSEvent) {
        if tabController!.keyBindings!.objectForKey(theEvent.characters!) != nil {
            self.handleBoundKey(theEvent.characters!)
        }
        else {
            self.interpretKeyEvents(NSArray(object: theEvent) as! [NSEvent])
        }
        self.needsDisplay = true
    }
    
    public override func mouseDown(theEvent: NSEvent) {
        lastFocusChordIndex = currFocusChordIndex
        self.mouseDownEvent = theEvent
        selectionManager!.mouseDown(theEvent, userInfo: nil)
        self.reFocusAtPoint(self.convertPoint(theEvent.locationInWindow, fromView: nil))
    }
    
    public override func mouseDragged(theEvent: NSEvent) {
        selectionManager!.mouseDragged(theEvent, userInfo: nil)
        self.reFocusAtPoint(self.convertPoint(theEvent.locationInWindow, fromView: nil))
    }
    
    public override func mouseUp(theEvent: NSEvent) {
        selectionManager!.mouseUp(theEvent)
        if selectionManager!.selectedIndexes.count == 1 && selectionManager!.selectedIndexes.firstIndex != lastFocusChordIndex {
            self.clearSelection()
        }
        self.reFocusAtPoint(self.convertPoint(theEvent.locationInWindow, fromView: nil))
    }
    
    // MARK: - TLSelectionManager delegate methods -
    
    public func indexUnderPoint(windowPoint: NSPoint, withSelectionManager manager: TLSelectionManager!, userInfo: UnsafeMutablePointer<Void>) -> Int? {
        return self.chordIndexAtPoint(self.convertPoint(windowPoint, fromView: nil))
    }
    
    public override func indexesInBox(windowRect: NSRect, withSelectionManager manager: TLSelectionManager!, userInfo: UnsafeMutablePointer<Void>) -> NSIndexSet? {
        let viewRect: NSRect = self.convertRect(windowRect, fromView: nil)
        let topLeft: NSPoint = viewRect.origin
        let topRight: NSPoint = NSMakePoint(topLeft.x + viewRect.size.width, viewRect.origin.y)
        let bottomLeft: NSPoint = NSMakePoint(viewRect.origin.x, topLeft.y + viewRect.size.height)
        let bottomRight: NSPoint = NSMakePoint(topLeft.x + viewRect.size.width, topLeft.y + viewRect.size.height)
        let mouseDownPoint: NSPoint = self.convertPoint(self.mouseDownEvent!.locationInWindow, fromView: nil)
        var startIndex: Int
        var endIndex: Int
        if NSEqualPoints(mouseDownPoint, topLeft) || NSEqualPoints(mouseDownPoint, bottomRight) {
            startIndex = max(self.chordIndexAtPoint(topLeft)!, 0)
            endIndex = min(self.chordIndexAtPoint(bottomRight)!, tablature!.countOfChords() - 1)
        }
        else {
            startIndex = max(self.chordIndexAtPoint(topRight)!, 0)
            endIndex = min(self.chordIndexAtPoint(bottomLeft)!, tablature!.countOfChords() - 1)
        }
        return NSIndexSet(indexesInRange: NSMakeRange(min(startIndex, endIndex), labs(endIndex - startIndex) + 1))
    }
    
    func shouldResetExistingSelection() -> Bool {
        return true
    }
    
    public override func selectionManagerDidChangeSelection(manager: TLSelectionManager) {
        self.needsDisplay = true
    }
}