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

@synthesize tabDoc;
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
}

- (void)awakeFromNib
{
    [tabView setTablature:[tabDoc tablature]];
    [self setTablature:[tabDoc tablature]];
    [self setupKeyBindings];
    [tabView setNeedsDisplay:YES];
}

// Editing selectors

- (void)addOpenString:(NSNumber *)whichString
        reverseString:(bool)doReverse
{
    if ([whichString intValue] < [tablature numStrings]) {
        [[tabView focusChord] addFret:0
                             onString:doReverse ? [tablature numStrings] - [whichString intValue] - 1
                                                : [whichString intValue]];
    }

}

- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret
          reverseString:(bool)doReverse
{
    if ([whichString intValue] < [tablature numStrings]) {
        [[tabView focusChord] addFret:[whichFret intValue] + [[tabDoc baseFret] intValue]
                             onString:doReverse ? [tablature numStrings] - [whichString intValue] - 1
                                                : [whichString intValue]];
    }
}

- (void)incrementBaseFret
{
    int currFret = [[tabDoc baseFret] intValue];
    if (currFret < MAX_FRET) {
        [tabDoc setBaseFret:[NSNumber numberWithInt:currFret + 1]];
    }
}

- (void)decrementBaseFret
{
    int currFret = [[tabDoc baseFret] intValue];
    if (currFret > 0) {
        [tabDoc setBaseFret:[NSNumber numberWithInt:currFret - 1]];
    }
}

- (void)advance
{
    if (![self focusNextChord]) {
        [tablature extend];
        [self focusNextChord];
    }
}

- (void)deleteFocusNote
{
    [[tabView focusChord] deleteNoteOnString:[tabView focusNoteString]];
}

- (bool)focusNextChord
{
    if ([tabView focusChordIndex] < [tablature tabLength] - 1) {
        [tabView focusNextChord];
        return YES;
    }
    return NO;
}

- (bool)focusPrevChord
{
    if ([tabView focusChordIndex] > 0) {
        [tabView focusPrevChord];
        return YES;
    }
    return NO;
}

- (bool)focusUpString
{
    if ([tabView focusNoteString] > 0) {
        [tabView focusUpString];
        return YES;
    }
    return NO;
}

- (bool)focusDownString
{
    if ([tabView focusNoteString] < [tablature numStrings] - 1) {
        [tabView focusDownString];
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark inputManager overrides

// Editing: selectors from input manager or whatever
// TODO: change drawing to use replaceCharactersInRange:

- (IBAction)moveRight:(id)sender
{
    [self focusNextChord];
}

- (IBAction)moveLeft:(id)sender
{
    [self focusPrevChord];
}

- (IBAction)moveUp:(id)sender
{
    [self focusUpString];
}

- (IBAction)moveDown:(id)sender
{
    [self focusDownString];
}

- (IBAction)deleteForward:(id)sender
{
    [self deleteFocusNote];
}

- (IBAction)deleteBackward:(id)sender
{
    if ([tabView focusChordIndex] > 0) {
        [[[tabDoc undoManager] prepareWithInvocationTarget:[self tablature]]
         insertChord:[tablature chordAtIndex:[tabView focusChordIndex] - 1]
         atIndex:[tabView focusChordIndex] - 1];
        [[tabDoc undoManager] setActionName:NSLocalizedString(@"Delete Chord", @"delete chord undo")];
        [tablature deleteChordAtIndex:[tabView focusChordIndex] - 1];
        [tabView focusPrevChord];
    }
}

- (IBAction)undo:(id)sender
{
    [self.nextResponder tryToPerform:@selector(undo:) with:sender];
    [tabView setNeedsDisplay:YES];
}
@end
