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

- (void)drawTab
{
    return;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    [self drawStringsWithGraphicsContext:[NSGraphicsContext currentContext]];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)awakeFromNib
{
    
}
@end
