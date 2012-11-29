//
//  VTabController.h
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VTablature;
@class VTabView;
@class VTabDocument;
@class VChord;

@interface VTabController : NSViewController <NSApplicationDelegate>
{
    // View stuff
    IBOutlet VTabView *tabView;
    IBOutlet NSTextField *currentFretField;
    IBOutlet NSTextField *chordModeField;
    
    NSDictionary *keyBindings;
    
    // Document
    IBOutlet VTabDocument *tabDoc;
}

@property (strong) VTabDocument *tabDoc;
@property (weak) VTablature *tablature;
@property (strong) NSDictionary *keyBindings;

// Setup

- (void)setupKeyBindings;

- (void)awakeFromNib;

// Information

- (BOOL)isInSoloMode;

// Editing functions

- (void)addOpenString:(NSNumber *)whichString
        reverseString:(BOOL)doReverse;

- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret
          reverseString:(BOOL)doReverse;

- (void)insertChord:(VChord *)chord
            atIndex:(NSUInteger)index;
- (void)insertAndSelectChords:(NSArray *)chordArray
                    atIndexes:(NSIndexSet *)indexes;
- (void)removeChordAtIndex:(NSUInteger)index;
- (void)deleteSelectedChords;
- (void)replaceSelectedChordsWithChords:(NSArray *)chordArray;

- (void)incrementBaseFret;
- (void)decrementBaseFret;
- (void)toggleSoloMode;

- (void)deleteFocusNote;
- (bool)focusNextChord;
- (bool)focusPrevChord;

@end
