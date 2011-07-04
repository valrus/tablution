//
//  VTabController.h
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VTablature.h"

@class VTabDocument;

@interface VTabController : NSWindowController
{
    IBOutlet NSTextView *tabView;
    IBOutlet NSTextField *currentFretField;
	NSDictionary *defaultTextAttrs;
	NSDictionary *selectedTextAttrs;
	NSDictionary *hiliteTextAttrs;
    NSDictionary *editCharsDict;
    VTabDocument *tabDoc;
}

- (void)setupEditDict;
- (void)setupTextAttrDicts;
- (void)drawTablature;

@end
