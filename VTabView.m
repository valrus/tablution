#import "VTabView.h"
#import "VTabController.h"
#import "VTablature.h"
#import "VTabDocument.h"
#import "VNote.h"
#import "TLSelectionManager.h"

#define STRING_SPACE 12.0
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

@end

@implementation VTabView

@synthesize tablature;
@synthesize selectionManager;
@synthesize focusChordIndex;

#pragma mark -
#pragma mark Drawing Functions

- (void)drawStringsWithGraphicsContext:(NSGraphicsContext *)theContext
{
    NSUInteger stringNum;
    NSPoint startPoint;
    NSPoint endPoint;
    NSRect viewRect = [self bounds];
    CGFloat viewWidth = viewRect.size.width;
    CGFloat viewHeight = viewRect.size.height;
    CGFloat stringHeight = 0.0;
    NSUInteger chordsAccommodated = 0;
    NSUInteger lineLength = 0;
    const NSUInteger chordsPerLine = (NSUInteger)((viewWidth - LEFT_MARGIN - TOP_MARGIN) / 
                                                  CHORD_SPACE);
    
    [NSBezierPath setDefaultLineWidth:LINE_WIDTH];
    [[NSColor lightGrayColor] setStroke];
    
    do {
        if (chordsAccommodated + chordsPerLine > [tablature tabLength]) {
            lineLength = [tablature tabLength] - chordsAccommodated;
        }
        else {
            lineLength = chordsPerLine;
        }
        for (stringNum = 0;
             stringNum < [tablature numStrings] && stringHeight + TOP_MARGIN < viewHeight;
             stringNum++) {
            startPoint = NSMakePoint(LEFT_MARGIN,
                                     stringHeight + TOP_MARGIN);
            endPoint = NSMakePoint(LEFT_MARGIN + (lineLength * CHORD_SPACE), 
                                   stringHeight + TOP_MARGIN);
            [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
            stringHeight += STRING_SPACE;
            chordsAccommodated += lineLength;
        }
        stringHeight += LINE_SPACE;
    } while (chordsAccommodated < [tablature tabLength] && 
             stringHeight + TOP_MARGIN + [self lineHeight] <= viewHeight);
}

- (void)drawFocusRectAtPoint:(NSPoint)origin
                      ofSize:(NSSize)size
                     inColor:(NSColor *)strokeColor
{
    NSRect focusRect = {origin, size};
    NSBezierPath *focusPath = [NSBezierPath bezierPathWithRoundedRect:focusRect
                                                              xRadius:3.0
                                                              yRadius:3.0];
    [[strokeColor colorWithAlphaComponent:0.5] setStroke];
    [focusPath stroke];
}

- (void)drawTabWithGraphicsContext:(NSGraphicsContext *)theContext
{
    NSRect viewRect = [self bounds];
    CGFloat viewWidth = viewRect.size.width;
    CGFloat viewHeight = viewRect.size.height;
    NSFont *currFont = [NSFont userFontOfSize:12.0];
    CGFloat textHeight = [currFont xHeight];
    NSUInteger x = LEFT_MARGIN;
    NSUInteger y = TOP_MARGIN - textHeight;
    NSDictionary *tabAttrs = [NSDictionary dictionary];
    NSColor *selectionColor = [NSColor blueColor];
    [selectionColor set];
    NSRect selectRect;
    bool selectionStarted = NO;
    bool inSelection = NO;
    bool drawEndLine = YES;
    VChord *lastChord = [tablature chordAtIndex:[tablature tabLength] - 1];
    for (VChord *chord in tablature) {
        inSelection = [[selectionManager selectedItems] containsObject:chord];
        if (inSelection && !selectionStarted) {
            selectRect.origin = NSMakePoint(x, y);
            selectionStarted = YES;
        }
        for (VNote *note in chord) {
            if ([note hasFret]) {
                NSString *text = [note stringValue];
                [text drawAtPoint:NSMakePoint(x + CHORD_SPACE/3, y)
                   withAttributes:tabAttrs];
            }
            y += STRING_SPACE;
        }
        y = TOP_MARGIN - textHeight;
        if (chord == [self focusChord]) {
            [self drawFocusRectAtPoint:NSMakePoint(x, y)
                                ofSize:NSMakeSize(CHORD_SPACE, [self lineHeight])
                               inColor:selectionColor];
        }
        if (selectionStarted && (!inSelection || chord == lastChord)) {
            if ((inSelection) && (chord == lastChord)) {
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
        if (x > viewWidth) {
            x = LEFT_MARGIN;
            y += LINE_SPACE;
        }
        if (y + [self lineHeight] > viewHeight) {
            drawEndLine = NO;
            break;
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSGraphicsContext *startGraphicsContext = [NSGraphicsContext currentContext];
    [startGraphicsContext saveGraphicsState];
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    [self drawStringsWithGraphicsContext:startGraphicsContext];
    [self drawTabWithGraphicsContext:startGraphicsContext];
    [startGraphicsContext restoreGraphicsState];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)awakeFromNib
{
    [self setSelectionManager:[TLSelectionManager new]];
    [selectionManager setDelegate:self];
    if ([tablature tabLength] >= 1) {
        [selectionManager selectItems:[NSSet setWithObject:[tablature chordAtIndex:0]]
                 byExtendingSelection:NO];
        [self setFocusChordIndex:0];
    }
    return;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (VChord *)focusChord
{
    return [tablature chordAtIndex:focusChordIndex];
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
    if (([tablature tabLength] > chordIndex) &&
        (chordIndex != -1)) {
        return [tablature chordAtIndex:chordIndex];
    } else {
        return nil;    
    }
}

- (NSInteger)chordIndexAtPoint:(NSPoint)thePoint
{
    CGFloat x = thePoint.x - LEFT_MARGIN;
    CGFloat y = thePoint.y - TOP_MARGIN;
    NSUInteger skipLines = (int)(y / ([self lineHeight] + LINE_SPACE));
    if (fmod(y, skipLines) > [self lineHeight]) {
        return -1;
    }
    else {
        NSUInteger skipChords = (int)(x / CHORD_SPACE);
        return skipLines * [self chordsPerLine] + skipChords;
    }
}
#pragma mark -
#pragma mark TLSelectionList delegate method

- (id)selectionManager:(TLSelectionManager*)manager
        itemUnderPoint:(NSPoint)windowPoint
              userInfo:(void*)userInfo
{
    return [self chordAtPoint:[self convertPoint:windowPoint
                                        fromView:nil]];
}

//- (BOOL)selectionManagerShouldInitiateDragLater:(TLSelectionManager*)manager
//									  dragEvent:(NSEvent*)dragEvent
//								  originalEvent:(NSEvent*)mouseDownEvent
//									   userInfo:(void*)userInfo
//{
//    return YES;
//}

- (NSSet*)selectionManager:(TLSelectionManager*)manager
				itemsInBox:(NSRect)windowRect
				  userInfo:(void*)userInfo
{
    NSRect viewRect = [self convertRect:windowRect
                               fromView:nil];
    NSPoint topLeft = viewRect.origin;
    NSPoint bottomRight = NSMakePoint(topLeft.x + viewRect.size.width,
                                      topLeft.y + viewRect.size.height);
    
    NSInteger startIndex = MAX([self chordIndexAtPoint:topLeft], 0);
    NSInteger endIndex = [self chordIndexAtPoint:bottomRight];
    
    if (endIndex < 0 || endIndex >= [tablature tabLength]) {
        endIndex = [tablature tabLength] - 1;
    }
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, endIndex - startIndex + 1)];
    
    return [NSSet setWithArray:[tablature chordsAtIndexes:indexSet]];
}

- (BOOL)shouldResetExistingSelection {
	return YES;
}

/* Input Handling -------------------------------------------------------------------- */

#pragma mark -
#pragma mark Input Handling

- (void)keyDown:(NSEvent *)theEvent
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([[tabController keyBindings] objectForKey:[theEvent characters]])
    {
        NSArray *actionParts = [[tabController keyBindings] objectForKey:[theEvent characters]];
        NSString *selectorString = [actionParts objectAtIndex:0];
        SEL editSelector = NSSelectorFromString(selectorString);
        switch ([actionParts count])
        {
            case 1:
                [tabController performSelector:editSelector];
                [self setNeedsDisplay:YES];
                break;
            case 2:
                [tabController performSelector:editSelector
                                    withObject:[actionParts objectAtIndex:1]];
                [self setNeedsDisplay:YES];
                break;
            case 3:
                // annoying rationale behind this:
                // 
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
                [self setNeedsDisplay:YES];
        }
    }
#pragma clang diagnostic pop
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
    focusChordIndex = [self chordIndexAtPoint:[self convertPoint:[theEvent locationInWindow]
                                                        fromView:nil]];
    if (focusChordIndex >= [tablature tabLength]) {
        focusChordIndex = [tablature tabLength] - 1;
    }
    [self setNeedsDisplay:YES];
}

- (void)selectionManagerDidChangeSelection:(TLSelectionManager*)manager
{
    [self setNeedsDisplay:YES];
}

- (bool)focusNextChord
{
    if (focusChordIndex < [tablature tabLength] - 1) {
        focusChordIndex++;
        [selectionManager selectItems:[NSSet setWithObject:[tablature chordAtIndex:focusChordIndex]]
                 byExtendingSelection:NO];
        return YES;
    }
    return NO;
}

@end