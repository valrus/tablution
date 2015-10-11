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
    NSUInteger currFocusChordIndex;
    NSUInteger focusNoteString;
    NSEvent *mouseDownEvent;
}

@property (weak, readwrite) VTablature *tablature;
@property (strong) TLSelectionManager *selectionManager;
@property (readonly) NSUInteger lastFocusChordIndex;
@property (assign, readwrite) NSUInteger currFocusChordIndex;
@property (assign, readwrite) NSUInteger focusNoteString;
@property (strong) NSEvent *mouseDownEvent;

#pragma mark - Setup and init -
- (void)awakeFromNib;
- (BOOL)acceptsFirstResponder;

#pragma mark - Drawing methods -
- (void)drawRect:(NSRect)dirtyRect;
- (BOOL)isFlipped;

#pragma mark - Selection handling -
#pragma mark Accessors
- (BOOL)hasSelection;
- (NSIndexSet *)selectedIndexes;
- (NSArray *)selectedChords;

#pragma mark Mutators
- (void)selectIndexes:(NSIndexSet *)indexes;
- (void)clearSelection;

#pragma mark - Focus handling -
#pragma mark Accessors
- (NSUInteger)focusChordIndexForMode;
- (VChord *)focusChord;
- (VNote *)focusNote;

#pragma mark Mutators
- (void)focusNextChord;
- (void)focusPrevChord;
- (void)focusUpString;
- (void)focusDownString;

#pragma mark - Input Handling -
#pragma mark Keys
- (void)keyDown:(NSEvent *)theEvent;

#pragma mark Mouse
- (void)mouseDown:(NSEvent*)theEvent;
- (void)mouseDragged:(NSEvent*)theEvent;
- (void)mouseUp:(NSEvent*)theEvent;

@end