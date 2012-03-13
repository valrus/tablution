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

@interface VTabController : NSObject
{
    // View stuff
    IBOutlet VTabView *tabView;
    IBOutlet NSTextField *currentFretField;
    
    NSDictionary *keyBindings;
    
    // Document
    IBOutlet VTabDocument *tabDocument;
    
    // Data
    VTablature *tablature;
}

@property (strong) VTabDocument *tabDocument;
@property (strong) VTablature *tablature;
@property (strong) NSDictionary *keyBindings;

// Setup

- (void)setupKeyBindings;

- (void)awakeFromNib;

// Editing functions

- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret
          reverseString:(bool)doReverse;

- (void)incrementBaseFret;
- (void)decrementBaseFret;

@end
