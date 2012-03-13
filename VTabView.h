#import <Cocoa/Cocoa.h>

@class VTabController;
@class VTablature;
@class VTabDocument;
@class TLSelectionManager;
@class VChord;

@interface VTabView : NSView
{
    IBOutlet VTabController *tabController;
    VTablature *tablature;
    TLSelectionManager *selectionManager;
    NSUInteger focusChordIndex;
}

@property (strong) VTablature *tablature;
@property (strong) TLSelectionManager *selectionManager;
@property (assign) NSUInteger focusChordIndex;

- (void)drawRect:(NSRect)dirtyRect;

- (BOOL)isFlipped;

- (void)awakeFromNib;

- (BOOL)acceptsFirstResponder;

- (VChord *)focusChord;

// Input handling

- (void)keyDown:(NSEvent *)theEvent;

- (void)mouseDown:(NSEvent*)theEvent;
- (void)mouseDragged:(NSEvent*)theEvent;
- (void)mouseUp:(NSEvent*)theEvent;

- (bool)focusNextChord;

@end