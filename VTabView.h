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
    NSUInteger lastFocusChordIndex;
    NSUInteger focusChordIndex;
    NSUInteger focusNoteString;
}

@property (weak) VTablature *tablature;
@property (strong) TLSelectionManager *selectionManager;
@property (assign, readwrite) NSUInteger lastFocusChordIndex;
@property (assign, readwrite) NSUInteger focusChordIndex;
@property (assign, readwrite) NSUInteger focusNoteString;

- (void)drawRect:(NSRect)dirtyRect;

- (BOOL)isFlipped;

- (void)awakeFromNib;

- (BOOL)acceptsFirstResponder;

- (BOOL)hasSelection;
- (NSIndexSet *)selectedIndexes;
- (NSArray *)selectedChords;
- (void)selectIndexes:(NSIndexSet *)indexes;
- (void)clearSelection;

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