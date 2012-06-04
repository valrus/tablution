//
//  VTabController.m
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VTabController.h"
#import "VTabDocument.h"
#import "VTablature.h"
#import "VTabView.h"

#define MAX_FRET 22

@implementation VTabController

@synthesize tabDocument;
@synthesize tablature;
@synthesize keyBindings;
    
- (void)setupKeyBindings
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"keyBindings"
                                                          ofType:@"plist"];
    
    if ((!(keyBindings = [NSDictionary dictionaryWithContentsOfFile:plistPath])))
    {
        // TODO: make a dialog box or something for this
        NSLog(@"Edit chars dictionary not found or contains an error!");
    }
    NSLog(@"Loaded dictionary:\n%@", [keyBindings description]);
}

- (void)awakeFromNib
{
    [tabView setTablature:[tabDocument tablature]];
    [self setTablature:[tabDocument tablature]];
    [self setupKeyBindings];
}

// Editing selectors

- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret
          reverseString:(bool)doReverse
{
    if ([whichString intValue] < [tablature numStrings]) {
        [[tabView focusChord] addFret:[whichFret intValue] + [[tabDocument baseFret] intValue]
                             onString:doReverse ? [tablature numStrings] - [whichString intValue] - 1
                                                : [whichString intValue]];
    }
}

- (void)incrementBaseFret
{
    int currFret = [[tabDocument baseFret] intValue];
    if (currFret < MAX_FRET) {
        [tabDocument setBaseFret:[NSNumber numberWithInt:currFret + 1]];
    }
}

- (void)decrementBaseFret
{
    int currFret = [[tabDocument baseFret] intValue];
    if (currFret > 0) {
        [tabDocument setBaseFret:[NSNumber numberWithInt:currFret - 1]];
    }
}

- (void)advance
{
    if (![tabView focusNextChord]) {
        [tablature extend];
        [tabView focusNextChord];
    }
}

@end
