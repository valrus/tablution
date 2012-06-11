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

@interface VTabController : NSViewController
{
    // View stuff
    IBOutlet VTabView *tabView;
    IBOutlet NSTextField *currentFretField;
    
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

// Editing functions

- (void)addOpenString:(NSNumber *)whichString
        reverseString:(bool)doReverse;

- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret
          reverseString:(bool)doReverse;

- (void)insertChord:(VChord *)chord
            atIndex:(NSUInteger)index;

- (void)incrementBaseFret;
- (void)decrementBaseFret;

- (void)deleteFocusNote;
- (bool)focusNextChord;
- (bool)focusPrevChord;

@end
