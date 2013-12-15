//
//  VTabController.h
//  tablution
//
//  Created by Ian McCowan on 9/30/08.
//  Copyright 2008 valrusware. All rights reserved.
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

#pragma mark - Setup -

- (void)setupKeyBindings;
- (void)awakeFromNib;

// Information

- (BOOL)isInSoloMode;

#pragma mark - Editing selectors -
#pragma mark Chord-level changes

- (void)insertAndSelectChords:(NSArray *)chordArray
                    atIndexes:(NSIndexSet *)indexes;
- (void)removeChordAtIndex:(NSUInteger)index;
- (void)deleteSelectedChords;
- (void)replaceSelectedChordsWithChords:(NSArray *)chordArray;

- (void)toggleMeasureBar;

#pragma mark Note-level changes

- (void)addOpenString:(NSNumber *)whichString
        reverseString:(BOOL)doReverse;
- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret
          reverseString:(BOOL)doReverse;
- (void)deleteFocusNote;

#pragma mark Mode changes

- (void)incrementBaseFret;
- (void)decrementBaseFret;
- (void)toggleSoloMode;

@end
