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
#import "VNote.h"

#define MAX_FRET 22

@interface VTabController (Private)

- (void)prepareUndoForChangeFromNote:(VNote *)previousNote
                            onString:(NSUInteger)whichString;

@end

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
    [tablature addObserver:self forKeyPath:@"chords" options:0 context:NULL];
    [tabView setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Editing selectors

- (void)prepareUndoForChangeFromNote:(VNote *)previousNote
                            onString:(NSUInteger)whichString
{
    [[[tabDoc undoManager] prepareWithInvocationTarget:tablature]
     insertNote:previousNote
     atIndex:[tabView focusChordIndex]
     onString:whichString];
    [[tabDoc undoManager] setActionName:NSLocalizedString(@"Change Note", @"change note undo")];
}

- (void)addOpenString:(NSNumber *)whichString
        reverseString:(BOOL)doReverse
{
    [self addNoteOnString:whichString
                   onFret:0
            reverseString:doReverse];
}

- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret
          reverseString:(BOOL)doReverse
{
    NSUInteger stringNum = doReverse ? [tablature numStrings] - [whichString intValue] - 1
                                     : [whichString intValue];
    if ([whichString intValue] < [tablature numStrings]) {
        if ([[tabDoc soloMode] boolValue]) {
            VChord *newChord = [VChord chordWithStrings:[tablature numStrings]
                                               withFret:[whichFret intValue]
                                               onString:[whichString intValue]];
            [[[tabDoc undoManager] prepareWithInvocationTarget:self]
             removeChordAtIndex:[tabView focusChordIndex] + 1];
            [[tabDoc undoManager] setActionName:NSLocalizedString(@"Add Solo Note", @"add solo note undo")];
            [tablature insertObject:newChord
                    inChordsAtIndex:[tabView focusChordIndex] + 1];
            [tabView focusNextChord];
        }
        else {
            [self prepareUndoForChangeFromNote:[[tabView focusChord] objectInNotesAtIndex:stringNum]
                                      onString:stringNum];
            [tablature insertNoteAtIndex:[tabView focusChordIndex]
                                onString:stringNum
                                  onFret:[whichFret intValue] + [[tabDoc baseFret] intValue]];
            [tabView setFocusNoteString:stringNum];
        }
    }
}

- (void)insertChord:(VChord *)chord
            atIndex:(NSUInteger)index
{
    [tablature insertObject:chord inChordsAtIndex:index];
    if (index <= [tabView focusChordIndex]) {
        [self focusNextChord];
    }
}

- (void)removeChordAtIndex:(NSUInteger)index
{
    [tablature removeObjectFromChordsAtIndex:index];
    if (index <= [tabView focusChordIndex]) {
        [self focusPrevChord];
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

- (void)toggleSoloMode
{
    BOOL currentMode = [[tabDoc soloMode] boolValue];
    [tabDoc setSoloMode:[NSNumber numberWithBool:!currentMode]];
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
    VNote *currentNote = [tabView focusNote];
    if ([currentNote hasFret]) {
        [self prepareUndoForChangeFromNote:currentNote
                                  onString:[tabView focusNoteString]];
        [tablature deleteNoteAtIndex:[tabView focusChordIndex]
                            onString:[tabView focusNoteString]];
    }
}

- (bool)focusNextChord
{
    if ([tabView focusChordIndex] < [tablature countOfChords] - 1) {
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
        [[[tabDoc undoManager] prepareWithInvocationTarget:tablature]
         insertObject:[tablature objectInChordsAtIndex:[tabView focusChordIndex] - 1]
         inChordsAtIndex:[tabView focusChordIndex] - 1];
        [[tabDoc undoManager] setActionName:NSLocalizedString(@"Delete Chord", @"delete chord undo")];
        [tablature removeObjectFromChordsAtIndex:[tabView focusChordIndex] - 1];
    }
}

#pragma mark -
#pragma mark KVO observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    NSLog(@"VTabController sees a change in %@!", keyPath);
    NSNumber *changeKindNumber = [change valueForKey:@"kind"];
    NSKeyValueChange changeKind = [changeKindNumber intValue];
    switch (changeKind) {
        case NSKeyValueChangeInsertion: {
            NSIndexSet *indexes = [change valueForKey:@"indexes"];
            NSUInteger indexesBeforeFocus = 
                [indexes countOfIndexesInRange:NSMakeRange(0, [tabView focusChordIndex] + 1)];
            [tabView setFocusChordIndex:[tabView focusChordIndex] + indexesBeforeFocus];
            break;
        }
            
        case NSKeyValueChangeRemoval: {
            NSIndexSet *indexes = [change valueForKey:@"indexes"];
            NSUInteger indexesBeforeFocus = [indexes countOfIndexesInRange:NSMakeRange(0, [tabView focusChordIndex])];
            [tabView setFocusChordIndex:[tabView focusChordIndex] - indexesBeforeFocus];
            break;
        }
    }
    [tabView setNeedsDisplay:YES];
}

@end
