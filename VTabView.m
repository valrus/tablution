#import "VTabView.h"
#import "VTabController.h"
#import "VTablature.h"
#import "VTabDocument.h"

#define STRING_SPACE 12.0
#define LINE_SPACE 24.0
#define LEFT_MARGIN 16.0
#define RIGHT_MARGIN 16.0
#define TOP_MARGIN 16.0
#define LINE_WIDTH 2

@interface VTabView (Private)

- (void)drawStringsWithGraphicsContext:(NSGraphicsContext *)theContext;
- (void)drawTab;

@end

@implementation VTabView

@synthesize tablature;

#pragma mark -
#pragma mark Drawing Functions

- (void)drawStringsWithGraphicsContext:(NSGraphicsContext *)theContext
{
    NSUInteger i;
    NSPoint startPoint;
    NSPoint endPoint;
    NSRect viewRect = [self bounds];
    CGFloat viewWidth = viewRect.size.width;
    CGFloat viewHeight = viewRect.size.height;
    CGFloat stringHeight = 0.0;
    NSUInteger lineHeight = ([tablature numStrings] - 1) * (STRING_SPACE + LINE_WIDTH);
    
    [theContext saveGraphicsState];
    
    [NSBezierPath setDefaultLineWidth:LINE_WIDTH];
    [[NSColor grayColor] setStroke];
    
    while (stringHeight + TOP_MARGIN + lineHeight <= viewHeight) {
        for (i = 0; i < [tablature numStrings]; i++) {
            startPoint = NSMakePoint(LEFT_MARGIN, stringHeight + TOP_MARGIN);
            endPoint = NSMakePoint(viewWidth - RIGHT_MARGIN, stringHeight + TOP_MARGIN);
            [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
            stringHeight += STRING_SPACE;
        }
        stringHeight += LINE_SPACE;
    }
    [theContext restoreGraphicsState];
}

// TODO
- (void)drawTab
{
    return;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    [self drawStringsWithGraphicsContext:[NSGraphicsContext currentContext]];
    [self drawTab];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)awakeFromNib
{
    return;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}


#pragma mark -
#pragma mark Input Handling
- (void)keyDown:(NSEvent *)theEvent
{
    NSLog(@"Bindings: %@", [[tabController keyBindings] description]);
    NSLog(@"keyDown: %@", [theEvent characters]);
    if ([[tabController keyBindings] objectForKey:[theEvent characters]])
    {
        NSArray *actionParts = [[tabController keyBindings] objectForKey:[theEvent characters]];
        NSLog(@"%@", [actionParts objectAtIndex:0]);
        SEL theSelector = NSSelectorFromString([actionParts objectAtIndex:0]);
        switch ([actionParts count])
        {
            case 1:
                [tabController performSelector:theSelector];
                break;
            case 2:
                [tabController performSelector:theSelector
                                    withObject:[actionParts objectAtIndex:1]];
                break;
            case 3:
                [tabController performSelector:theSelector
                                    withObject:[actionParts objectAtIndex:1]
                                    withObject:[actionParts objectAtIndex:2]];
        }
    }
}

@end