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

#define MAX_FRET 22

@implementation VTabController

@synthesize tabDocument;
@synthesize tablature;
@synthesize keyBindings;
    
- (void)setupKeyBindings
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"keyBindings"
                                                          ofType:@"plist"];
    
    if ((!(keyBindings = [[NSDictionary dictionaryWithContentsOfFile:plistPath] retain])))
    {
        // TODO: make a dialog box or something for this
        NSLog(@"Edit chars dictionary not found or contains an error!");
    }
    NSLog(@"Loaded dictionary:\n%@", [keyBindings description]);
}

- (void)awakeFromNib
{
    [tabView setTablature:[tabDocument tablature]];
    [self setupKeyBindings];
}

// Editing selectors

- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret
{
    NSLog(@"Add a note on string %i at fret %i",
          [whichString intValue], [whichFret intValue]);
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
//	if ( [tabDoc atEndOfTab] )
//	{
//		[tabDoc insertNoteBefore:[tabDoc tabLength]];
//	}
//	[self moveRight:nil];
}

// Editing: selectors from input manager or whatever
// TODO: change drawing to use replaceCharactersInRange:

- (IBAction)moveRight:(id)sender
{
//    [tabDoc advanceCurrentLocation];
}

- (IBAction)moveLeft:(id)sender
{
//    [tabDoc recedeCurrentLocation];
}

- (IBAction)moveUp:(id)sender
{
//    [tabDoc upString];
}

- (IBAction)moveDown:(id)sender
{
//    [tabDoc downString];
}

@end
