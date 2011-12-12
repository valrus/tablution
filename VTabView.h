#import <Cocoa/Cocoa.h>

@class VTabController;
@class VTablature;
@class VTabDocument;

@interface VTabView : NSView
{
    IBOutlet VTabController *tabController;
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

- (BOOL)acceptsFirstResponder;

// Input handling

- (void)keyDown:(NSEvent *)theEvent;

// NSTextInputClient-ish protocol

//Handling Marked Text
//– hasMarkedText  required method
//– markedRange  required method
//– selectedRange  required method
//– setMarkedText:selectedRange:replacementRange:  required method
//– unmarkText  required method
//– validAttributesForMarkedText  required method
//Storing Text
//– attributedSubstringForProposedRange:actualRange:  required method
//– insertText:replacementRange:  required method
//Getting Character Coordinates
//– characterIndexForPoint:  required method
//– firstRectForCharacterRange:actualRange:  required method
//Binding Keystrokes
//– doCommandBySelector:  required method
@end