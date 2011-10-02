#import <Cocoa/Cocoa.h>

@class VTabController;
@class VTablature;
@class VTabDocument;

@interface VTabView : NSView
{
    VTabController *tabController;
    VTablature *tablature;
    
    NSArray *selectedRanges;
}

@property (retain) VTablature *tablature;

// Drawing helper functions
- (void)drawStringsWithGraphicsContext:(NSGraphicsContext *)theContext;
- (void)drawTab;

- (void)drawRect:(NSRect)dirtyRect;

- (BOOL)isFlipped;

- (void)awakeFromNib;

@end