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

@implementation VTabController

@synthesize tabDocument;
@synthesize tablature;
    
- (void)setupEditDict
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"editChars"
                                                          ofType:@"plist"];
    editCharsDict = [[NSDictionary dictionaryWithContentsOfFile:plistPath] retain];
    if (!editCharsDict) {
        // make a dialog box or something for this
        NSLog(@"Edit chars dictionary not found!");
    }
}

- (void)awakeFromNib
{
    [tabView setTablature:[tabDocument tablature]];
    [self setupEditDict];
}

// Editing selectors

- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret
{
//    [tablature addNoteAtLocation:
//                        onString:whichString
//                          onFret:whichFret];
}

- (void)incrementBaseFret
{
//    [tabDoc incrementBaseFret];
//    [currentFretField setStringValue:
//        [@"Current Fret: " stringByAppendingString:
//            [NSString stringWithFormat:@"%i", [tabDoc baseFret]]]];
}

- (void)decrementBaseFret
{
//    [tabDoc decrementBaseFret];
//    [currentFretField setStringValue:
//        [@"Current Fret: " stringByAppendingString:
//            [NSString stringWithFormat:@"%i", [tabDoc baseFret]]]];
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
