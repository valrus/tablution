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
    
    NSDictionary *editCharsDict;
    
    // Document
    IBOutlet VTabDocument *tabDocument;
    
    // Data
    VTablature *tablature;
}

@property (retain) VTabDocument *tabDocument;
@property (retain) VTablature *tablature;

- (void)setupEditDict;

- (void)awakeFromNib;

@end
