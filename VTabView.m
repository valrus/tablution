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
@synthesize lastFocusChordIndex;
@synthesize focusChordIndex;
@synthesize focusNoteString;
@synthesize mouseDownEvent;

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

- (void)drawChord:(VChord *)chord
     withCornerAt:(NSPoint)topLeft
      normalStyle:(NSDictionary *)tabAttrs
     focusedStyle:(NSDictionary *)focusNoteAttrs
{
    for (VNote *note in chord) {
        bool focused = (note == [self focusNote]);
        NSDictionary *attrsToUse = focused ? focusNoteAttrs : tabAttrs;
        NSString *text = [note hasFret] ? [note stringValue] : @"•";
        if ([note hasFret] || focused) {
            [text drawAtPoint:NSMakePoint(topLeft.x + CHORD_SPACE/3, topLeft.y)
               withAttributes:attrsToUse];
        }
        topLeft.y += STRING_SPACE;
    }
}

- (void)drawSelectionForChordRange:(NSRange)chordRange
                     withTopLeftAt:(NSPoint)topLeft
                        usingColor:(NSColor *)selectionColor
{
    NSRect selectRect;
    NSIndexSet *thisRangeSelection = [[selectionManager selectedIndexes]
                                      indexesInRange:chordRange
                                             options:0
                                         passingTest:^(NSUInteger idx, BOOL *stop) { return YES; }];
    NSRange thisRowRange = NSMakeRange([thisRangeSelection firstIndex] - chordRange.location,
                                       [thisRangeSelection lastIndex] - [thisRangeSelection firstIndex] + 1);

    selectRect.origin = NSMakePoint(topLeft.x + thisRowRange.location * CHORD_SPACE,
                                    topLeft.y);
    selectRect.size = NSMakeSize(thisRowRange.length * CHORD_SPACE, [self lineHeight]);
    NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectRect
                                                                  xRadius:3.0
                                                                  yRadius:3.0];
    [[selectionColor colorWithAlphaComponent:0.3] setFill];
    [selectionPath fill];
}

- (void)drawOneLineOfTabAtHeight:(CGFloat)tabHeight
                 fromChordNumber:(NSUInteger)firstChord
                  numberOfChords:(NSUInteger)numChords
{
    NSPoint currentCoords = NSMakePoint(LEFT_MARGIN, tabHeight);
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
    [self drawSelectionForChordRange:NSMakeRange(firstChord, numChords)
                       withTopLeftAt:currentCoords
                          usingColor:selectionColor];
    for (chordNum = firstChord; chordNum < firstChord + numChords; ++chordNum) {
        VChord *chord = [tablature objectInChordsAtIndex:chordNum];
        [self drawChord:chord
           withCornerAt:currentCoords
            normalStyle:tabAttrs
           focusedStyle:focusNoteAttrs];
        currentCoords.y = tabHeight;
        if (chord == [self focusChord]) {
            [self drawFocusRectForChordAtPoint:currentCoords
                                       inColor:selectionColor];
        }
        currentCoords.x += CHORD_SPACE;
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
        NSUInteger chordIndex = skipLines * [self chordsPerLine] + skipChords;
        NSLog(@"Chord index: %lu", chordIndex);
        return chordIndex;
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

- (NSUInteger)selectionManager:(TLSelectionManager *)manager
               indexUnderPoint:(NSPoint)windowPoint
                      userInfo:(void *)userInfo
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

- (NSIndexSet *)selectionManager:(TLSelectionManager *)manager
                    indexesInBox:(NSRect)windowRect
                        userInfo:(void *)userInfo
{
    NSRect viewRect = [self convertRect:windowRect
                               fromView:nil];
    NSPoint topLeft = viewRect.origin;
    NSPoint topRight = NSMakePoint(topLeft.x + viewRect.size.width, viewRect.origin.y);
    NSPoint bottomLeft = NSMakePoint(viewRect.origin.x, topLeft.y + viewRect.size.height);
    NSPoint bottomRight = NSMakePoint(topLeft.x + viewRect.size.width,
                                      topLeft.y + viewRect.size.height);
    
    NSPoint mouseDownPoint = [self convertPoint:[[self mouseDownEvent] locationInWindow]
                                       fromView:nil];
    NSInteger startIndex, endIndex;
    if (NSEqualPoints(mouseDownPoint, topLeft) || NSEqualPoints(mouseDownPoint, bottomRight)) {
        startIndex = MAX([self chordIndexAtPoint:topLeft], 0);
        endIndex = MIN([self chordIndexAtPoint:bottomRight], [tablature countOfChords] - 1);
    }
    else {
        startIndex = MAX([self chordIndexAtPoint:topRight], 0);
        endIndex = MIN([self chordIndexAtPoint:bottomLeft], [tablature countOfChords] - 1);
    }
    
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(MIN(startIndex, endIndex),
                                                              abs(endIndex - startIndex) + 1)];
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
    }
    else {
        [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
    }
    [self setNeedsDisplay:YES];
}

- (void)reFocusAtPoint:(NSPoint)thePoint
{
    focusChordIndex = [self chordIndexAtPoint:thePoint];
    if (focusChordIndex >= [tablature countOfChords]) {
        focusChordIndex = [tablature countOfChords] - 1;
    }
    
    focusNoteString = [self stringAtPoint:thePoint];
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent*)theEvent
{
    [self setLastFocusChordIndex:[self focusChordIndex]];
    [self setMouseDownEvent:theEvent];
    [selectionManager mouseDown:theEvent userInfo:NULL];
    [self reFocusAtPoint:[self convertPoint:[theEvent locationInWindow]
                                   fromView:nil]];
}

- (void)mouseDragged:(NSEvent*)theEvent
{
    [selectionManager mouseDragged:theEvent userInfo:NULL];
    [self reFocusAtPoint:[self convertPoint:[theEvent locationInWindow]
                                   fromView:nil]];
}

- (void)mouseUp:(NSEvent*)theEvent
{
    [selectionManager mouseUp:theEvent];
    if ([[selectionManager selectedIndexes] count] == 1 &&
        [[selectionManager selectedIndexes] firstIndex] != [self lastFocusChordIndex]) {
        [self clearSelection];
    }
    [self reFocusAtPoint:[self convertPoint:[theEvent locationInWindow]
                                   fromView:nil]];
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