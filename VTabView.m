#import "VTabView.h"
#import "VTabController.h"
#import "VTablature.h"
#import "VNote.h"
#import "TLSelectionManager.h"

#define STRING_SPACE 14.0
#define LINE_SPACE 24.0
#define LEFT_MARGIN 16.0
#define RIGHT_MARGIN 16.0
#define TOP_MARGIN 16.0
#define LINE_WIDTH 2
#define CHORD_SPACE 24.0

@interface VTabView (Private)

// drawing submethods
- (void)drawStringsWithGraphicsContext:(NSGraphicsContext *)theContext;
- (void)drawTabWithGraphicsContext:(NSGraphicsContext *)theContext;
- (void)drawFocusRectAtPoint:(NSPoint)origin
                      ofSize:(NSSize)size
                     inColor:(NSColor *)strokeColor;

// drawing helper functions
- (NSUInteger)lineHeight;
- (NSUInteger)chordsPerLine;

// internal information
- (NSInteger)chordIndexAtPoint:(NSPoint)thePoint;
- (NSInteger)stringAtPoint:(NSPoint)thePoint;

@end

@implementation VTabView

@synthesize tablature;
@synthesize selectionManager;
@synthesize focusChordIndex;
@synthesize focusNoteString;

#pragma mark -
#pragma mark Drawing Functions

- (CGFloat)drawOneLineOfStringsAtHeight:(CGFloat)stringHeight
                           withSpaceFor:(NSUInteger)lineLength
{
    NSPoint startPoint;
    NSPoint endPoint;
    NSUInteger stringNum;
    [NSBezierPath setDefaultLineWidth:LINE_WIDTH];
    [[NSColor lightGrayColor] setStroke];
    for (stringNum = 0;
         stringNum < [tablature numStrings] && stringHeight < [self bounds].size.height;
         stringNum++) {
        // draw the strings
        startPoint = NSMakePoint(LEFT_MARGIN,
                                 stringHeight);
        endPoint = NSMakePoint(LEFT_MARGIN + (lineLength * CHORD_SPACE), 
                               stringHeight);
        [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
        stringHeight += STRING_SPACE;
    }
    return stringHeight;
}

- (void)drawFocusRectForChordAtPoint:(NSPoint)origin
                             inColor:(NSColor *)strokeColor
{
    NSSize size;
    CGFloat rectRadius;
    if ([tabController isInSoloMode]) {
        size = NSMakeSize(1.0, [self lineHeight]);
        origin = NSMakePoint(origin.x + CHORD_SPACE - 1.0, origin.y);
        rectRadius = 1.0;
    }
    else {
        size = NSMakeSize(CHORD_SPACE, [self lineHeight]);
        rectRadius = 3.0;
    }
    NSRect focusRect = {origin, size};
    NSBezierPath *focusPath = [NSBezierPath bezierPathWithRoundedRect:focusRect
                                                              xRadius:rectRadius
                                                              yRadius:rectRadius];
    [[strokeColor colorWithAlphaComponent:0.5] setStroke];
    [focusPath stroke];
}

- (void)drawOneLineOfTabAtHeight:(CGFloat)tabHeight
                 fromChordNumber:(NSUInteger)firstChord
                  numberOfChords:(NSUInteger)numChords
{
    NSUInteger x = LEFT_MARGIN;
    NSUInteger y = tabHeight;
    NSUInteger chordNum = firstChord;
    NSDictionary *tabAttrs = [NSDictionary dictionary];
    NSMutableDictionary *focusNoteAttrs = [NSMutableDictionary dictionaryWithDictionary:tabAttrs];
//    NSFontManager *fontManager = [NSFontManager sharedFontManager];
//    NSFont *boldUserFont = [fontManager convertFont:[NSFont userFontOfSize:12.0]
//                                        toHaveTrait:NSBoldFontMask];
//    [focusNoteAttrs setValue:boldUserFont
//                      forKey:NSFontAttributeName];
    [focusNoteAttrs setValue:[NSColor redColor]
                      forKey:NSForegroundColorAttributeName];
    [focusNoteAttrs setValue:[NSNumber numberWithFloat:-6.0]
                      forKey:NSStrokeWidthAttributeName];
//    NSForegroundColorAttributeName : [NSColor redColor]
//    NSStrokeWidthAttributeName : -3.0
    NSColor *selectionColor = [NSColor blueColor];
    [selectionColor set];
    NSRect selectRect;
    bool selectionStarted = NO;
    bool inSelection = NO;
    for (chordNum = firstChord; chordNum < firstChord + numChords; ++chordNum) {
        /// XXX
        VChord *chord = [tablature objectInChordsAtIndex:chordNum];
        inSelection = [[selectionManager selectedIndexes] containsIndex:chordNum];
        ///
        if (inSelection && !selectionStarted) {
            selectRect.origin = NSMakePoint(x, y);
            selectionStarted = YES;
        }
        for (VNote *note in chord) {
            if ([note hasFret]) {
                NSString *text = [note stringValue];
                if (note == [self focusNote]) {
                    [text drawAtPoint:NSMakePoint(x + CHORD_SPACE/3, y)
                       withAttributes:focusNoteAttrs];
                }
                else {
                    [text drawAtPoint:NSMakePoint(x + CHORD_SPACE/3, y)
                       withAttributes:tabAttrs];
                }
            }
            y += STRING_SPACE;
        }
        y = tabHeight;
        if (chord == [self focusChord]) {
            [self drawFocusRectForChordAtPoint:NSMakePoint(x, y)
                                       inColor:selectionColor];
        }
        if (selectionStarted && (!inSelection || chord == [tablature lastChord])) {
            if ((inSelection) && (chord == [tablature lastChord])) {
                x += CHORD_SPACE;
            }
            selectRect.size = NSMakeSize(x - selectRect.origin.x,
                                         y + [self lineHeight] - selectRect.origin.y);
            NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectRect
                                                                          xRadius:3.0
                                                                          yRadius:3.0];
            [[selectionColor colorWithAlphaComponent:0.3] setFill];
            [selectionPath fill];
            selectionStarted = NO;
        }
        x += CHORD_SPACE;
    }
}

- (void)drawTabWithGraphicsContext:(NSGraphicsContext *)theContext
{
    CGFloat stringHeight = TOP_MARGIN;
    CGFloat tabHeight = TOP_MARGIN;
    NSUInteger chordsAccommodated = 0;
    NSUInteger lineLength = 0;
    const NSUInteger chordsPerLine = (NSUInteger)(([self bounds].size.width - LEFT_MARGIN - RIGHT_MARGIN) / 
                                                  CHORD_SPACE);
    
    do {
        // draw one line's worth of tab strings
        if (chordsAccommodated + chordsPerLine > [tablature countOfChords]) {
            // set length to accommodate remaining chords
            lineLength = [tablature countOfChords] - chordsAccommodated;
        }
        else {
            // set length to max based on view width
            lineLength = chordsPerLine;
        }
        tabHeight = stringHeight - [[NSFont userFontOfSize:12.0] xHeight];
        stringHeight = [self drawOneLineOfStringsAtHeight:stringHeight
                                             withSpaceFor:lineLength] + LINE_SPACE;
        [self drawOneLineOfTabAtHeight:tabHeight
                       fromChordNumber:chordsAccommodated
                        numberOfChords:lineLength];
        chordsAccommodated += lineLength;
    } while (chordsAccommodated < [tablature countOfChords] && 
             stringHeight + [self lineHeight] <= [self bounds].size.height);
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSGraphicsContext *startGraphicsContext = [NSGraphicsContext currentContext];
    [startGraphicsContext saveGraphicsState];
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    [self drawTabWithGraphicsContext:startGraphicsContext];
    [startGraphicsContext restoreGraphicsState];
}

- (BOOL)isFlipped
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)awakeFromNib
{
    [self setSelectionManager:[TLSelectionManager new]];
    [selectionManager setDelegate:self];
    [tabController setNextResponder:[self nextResponder]];
    [self setNextResponder:tabController];
    if ([tablature countOfChords] >= 1) {
        [selectionManager selectIndexes:[NSIndexSet indexSetWithIndex:0]
                   byExtendingSelection:NO];
        [self setFocusChordIndex:0];
        [self setFocusNoteString:0];
    }
    [self setNeedsDisplay:YES];
    return;
}

#pragma mark -
#pragma mark Selection handling

- (BOOL)hasSelection
{
    return ([[selectionManager selectedIndexes] count] > 0);
}

- (NSIndexSet *)selectedIndexes
{
    return [selectionManager selectedIndexes];
}

- (NSArray *)selectedChords
{
    return [tablature chordsAtIndexes:[self selectedIndexes]];
}

- (void)selectIndexes:(NSIndexSet *)indexes
{
    [selectionManager selectIndexes:indexes
               byExtendingSelection:NO];
}

- (void)clearSelection
{
    [selectionManager selectIndexes:[NSIndexSet indexSet]
               byExtendingSelection:NO];
}

- (VChord *)focusChord
{
    return [tablature objectInChordsAtIndex:focusChordIndex];
}

- (VNote *)focusNote
{
    return [[self focusChord] objectInNotesAtIndex:focusNoteString];
}

- (NSUInteger)chordsPerLine
{
    return (NSUInteger)(([self bounds].size.width - LEFT_MARGIN - RIGHT_MARGIN) / CHORD_SPACE);
}

- (NSUInteger)lineHeight
{
    return (NSUInteger)(([tablature numStrings] - 0.5) * (STRING_SPACE + LINE_WIDTH));
}

- (VChord *)chordAtPoint:(NSPoint)thePoint
{
    NSInteger chordIndex = [self chordIndexAtPoint:thePoint];
    if (([tablature countOfChords] > chordIndex) &&
        (chordIndex != NO_HIT)) {
        return [tablature objectInChordsAtIndex:chordIndex];
    } else {
        return nil;    
    }
}

- (NSInteger)chordIndexAtPoint:(NSPoint)thePoint
{
    CGFloat x = thePoint.x - LEFT_MARGIN;
    CGFloat y = thePoint.y - TOP_MARGIN;
    // number of full lines of tab above click location
    NSUInteger skipLines = (int)(y / ([self lineHeight] + LINE_SPACE));
    if (fmod(y, skipLines) > [self lineHeight]) {
        return NO_HIT;
    }
    else {
        NSUInteger skipChords = (int)(x / CHORD_SPACE);
        return skipLines * [self chordsPerLine] + skipChords;
    }
}

- (VNote *)noteAtPoint:(NSPoint)thePoint
{
    VChord *theChord;
    if ((theChord = [self chordAtPoint:thePoint])) {
        return [theChord objectInNotesAtIndex:[self stringAtPoint:thePoint]];
    }
    else {
        return nil;
    }
}

- (NSInteger)stringAtPoint:(NSPoint)thePoint
{
    CGFloat y = thePoint.y - TOP_MARGIN;
    // find y-position of click relative to the top of its tab line
    y -= (int)(y / ([self lineHeight] + LINE_SPACE)) * ([self lineHeight] + LINE_SPACE);
    NSUInteger whichString = MIN((int)(y / STRING_SPACE), [tablature numStrings] - 1);
    NSLog(@"Clicked string: %lu, y = %f", whichString, y);
    return whichString;
}

#pragma mark -
#pragma mark TLSelectionList delegate method

- (NSUInteger)selectionManager:(TLSelectionManager*)manager
               indexUnderPoint:(NSPoint)windowPoint
                      userInfo:(void*)userInfo
{
    return [self chordIndexAtPoint:[self convertPoint:windowPoint
                                             fromView:nil]];
}

//- (BOOL)selectionManagerShouldInitiateDragLater:(TLSelectionManager*)manager
//									  dragEvent:(NSEvent*)dragEvent
//								  originalEvent:(NSEvent*)mouseDownEvent
//									   userInfo:(void*)userInfo
//{
//    return YES;
//}

- (NSIndexSet *)selectionManager:(TLSelectionManager*)manager
                    indexesInBox:(NSRect)windowRect
                        userInfo:(void*)userInfo
{
    NSRect viewRect = [self convertRect:windowRect
                               fromView:nil];
    NSPoint topLeft = viewRect.origin;
    NSPoint bottomRight = NSMakePoint(topLeft.x + viewRect.size.width,
                                      topLeft.y + viewRect.size.height);
    
    NSInteger startIndex = MAX([self chordIndexAtPoint:topLeft], 0);
    NSInteger endIndex = [self chordIndexAtPoint:bottomRight];
    
    if (endIndex < 0 || endIndex >= [tablature countOfChords]) {
        endIndex = [tablature countOfChords] - 1;
    }
    
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, endIndex - startIndex + 1)];
}

- (BOOL)shouldResetExistingSelection {
	return YES;
}

#pragma mark -
#pragma mark Input Handling

- (void)handleBoundKey:(NSString *)keyString
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSArray *actionParts = [[tabController keyBindings] objectForKey:keyString];
    NSString *selectorString = [actionParts objectAtIndex:0];
    SEL editSelector = NSSelectorFromString(selectorString);
    switch ([actionParts count])
    {
        case 1:
            [tabController performSelector:editSelector];
            break;
        case 2:
            if ([selectorString isEqualToString:@"addOpenString:"]) {
                [tabController addOpenString:[actionParts objectAtIndex:1]
                               reverseString:YES];
            }
            else {
                [tabController performSelector:editSelector
                                    withObject:[actionParts objectAtIndex:1]];
            }
            break;
        case 3:
            if ([selectorString isEqualToString:@"addNoteOnString:onFret:"]) {
                [tabController addNoteOnString:[actionParts objectAtIndex:1]
                                        onFret:[actionParts objectAtIndex:2]
                                 reverseString:YES];
            }
            else {
                [tabController performSelector:editSelector
                                    withObject:[actionParts objectAtIndex:1]
                                    withObject:[actionParts objectAtIndex:2]];
            }
    }
#pragma clang diagnostic pop
}

- (void)keyDown:(NSEvent *)theEvent
{
    if ([[tabController keyBindings] objectForKey:[theEvent characters]]) {
        [self handleBoundKey:[theEvent characters]];
        [self setNeedsDisplay:YES];
    }
    else {
        [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseDown:(NSEvent*)theEvent
{
    [selectionManager mouseDown:theEvent userInfo:NULL];
}

- (void)mouseDragged:(NSEvent*)theEvent
{
    [selectionManager mouseDragged:theEvent userInfo:NULL];
}

- (void)mouseUp:(NSEvent*)theEvent
{
    [selectionManager mouseUp:theEvent];
    NSPoint convertedPoint = [self convertPoint:[theEvent locationInWindow]
                                       fromView:nil];
    focusChordIndex = [self chordIndexAtPoint:convertedPoint];
    if (focusChordIndex >= [tablature countOfChords]) {
        focusChordIndex = [tablature countOfChords] - 1;
    }
    
    focusNoteString = [self stringAtPoint:convertedPoint];
    [self setNeedsDisplay:YES];
}

- (void)selectionManagerDidChangeSelection:(TLSelectionManager*)manager
{
    [self setNeedsDisplay:YES];
}

- (void)focusNextChord
{
    focusChordIndex++;
    [self clearSelection];
}

- (void)focusPrevChord
{
    focusChordIndex--;
    [self clearSelection];
}

- (void)focusUpString
{
    focusNoteString--;
}

- (void)focusDownString
{
    focusNoteString++;
}

@end