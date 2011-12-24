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

@property (retain) VTabDocument *tabDocument;
@property (retain) VTablature *tablature;
@property (retain) NSDictionary *keyBindings;

// Setup

- (void)setupKeyBindings;

- (void)awakeFromNib;

// Editing functions

- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret;

- (void)incrementBaseFret;
- (void)decrementBaseFret;

@end
