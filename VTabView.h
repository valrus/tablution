#import <Cocoa/Cocoa.h>

@class VTabController;
@class VTablature;
@class VTabDocument;
@class TLSelectionManager;
@class VChord;
@class VNote;

@interface VTabView : NSView
{
    IBOutlet VTabController *tabController;
    TLSelectionManager *selectionManager;
    NSUInteger focusChordIndex;
    NSUInteger focusNoteString;
}

@property (weak) VTablature *tablature;
@property (strong) TLSelectionManager *selectionManager;
@property (assign) NSUInteger focusChordIndex;
@property (assign) NSUInteger focusNoteString;

- (void)drawRect:(NSRect)dirtyRect;

- (BOOL)isFlipped;

- (void)awakeFromNib;

- (BOOL)acceptsFirstResponder;

- (VChord *)focusChord;

- (VNote *)focusNote;

// Input handling

- (void)keyDown:(NSEvent *)theEvent;

- (void)mouseDown:(NSEvent*)theEvent;
- (void)mouseDragged:(NSEvent*)theEvent;
- (void)mouseUp:(NSEvent*)theEvent;

- (void)focusNextChord;
- (void)focusPrevChord;
- (void)focusUpString;
- (void)focusDownString;

@end