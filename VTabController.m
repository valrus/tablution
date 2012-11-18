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
#import "HandyTools.h"

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
    [tablature addObserver:self
                forKeyPath:@"chords" 
                   options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                   context:NULL];
}

#pragma mark -
#pragma mark Communication

- (BOOL)isInSoloMode
{
    return [[tabDoc soloMode] boolValue];
}

#pragma mark - Editing selectors -
#pragma mark Chord-level changes

- (void)insertChord:(VChord *)chord
            atIndex:(NSUInteger)index
{
    [tablature insertObject:chord inChordsAtIndex:index];
}

- (void)insertAndSelectChords:(NSArray *)chordArray
                    atIndexes:(NSIndexSet *)indexes
{
    [[[tabDoc undoManager] prepareWithInvocationTarget:tablature]
     removeChordsAtIndexes:indexes];
    [[tabDoc undoManager] setActionName:NSLocalizedString(@"Insert Chords", @"insert chords undo")];
    [tablature insertChords:chordArray
                  atIndexes:indexes];
    [tabView selectIndexes:indexes];
}

- (void)removeChordAtIndex:(NSUInteger)index
{
    [tablature removeObjectFromChordsAtIndex:index];
}

- (void)replaceSelectedChordsWithChords:(NSArray *)chordArray
{
    // FIXME: Need to handle case where selection is not same size as chordArray
    [tablature replaceChordsAtIndexes:[tabView selectedIndexes]
                           withChords:chordArray];
}

#pragma mark Note-level changes

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

#pragma mark Mode changes

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
    [tabView clearSelection];
    [tabView setFocusNoteString:NO_FRET];
}

#pragma mark Focus changes

- (void)advance
{
    if (![self focusNextChord]) {
        [tablature extend];
        [self focusNextChord];
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
        NSIndexSet *selectedIndexes = [tabView selectedIndexes];
        if (IsEmpty(selectedIndexes)) {
            [[[tabDoc undoManager] prepareWithInvocationTarget:tablature]
             insertObject:[tablature objectInChordsAtIndex:[tabView focusChordIndex]]
             inChordsAtIndex:[tabView focusChordIndex]];
            [[tabDoc undoManager] setActionName:NSLocalizedString(@"Delete Chord", @"delete chord undo")];
            [tablature removeObjectFromChordsAtIndex:[tabView focusChordIndex]];           
        }
        else {
            [[[tabDoc undoManager] prepareWithInvocationTarget:self]
             insertAndSelectChords:[tablature chordsAtIndexes:selectedIndexes]
             atIndexes:selectedIndexes];
            [[tabDoc undoManager] setActionName:NSLocalizedString(@"Delete Selection", @"delete selection undo")];
            [tablature removeChordsAtIndexes:selectedIndexes];
            [tabView clearSelection];
        }
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
        case NSKeyValueChangeReplacement: {
            NSArray *oldChordArray = [change valueForKey:NSKeyValueChangeOldKey];
            NSArray *newChordArray = [change valueForKey:NSKeyValueChangeNewKey];
            if ([oldChordArray count] == 1 && [newChordArray count] == 1) {
                VChord *oldChord = [oldChordArray objectAtIndex:0];
                VChord *newChord = [newChordArray objectAtIndex:0];
                NSIndexSet *changedNotesIndexes = [newChord indexesOfChangedNotesFrom:oldChord];
                if ([changedNotesIndexes count] == 1) {
                    [tabView setFocusNoteString:[changedNotesIndexes firstIndex]];
                }               
            }
            break;
        }
            
        case NSKeyValueChangeInsertion: {
            NSIndexSet *indexes = [change valueForKey:@"indexes"];
            NSUInteger indexForFocusAdjustment = [tabView focusChordIndex] + ([self isInSoloMode] ? 2 : 0);
            NSUInteger indexesBeforeFocus = [indexes countOfIndexesInRange:NSMakeRange(0, indexForFocusAdjustment)];
            [tabView setFocusChordIndex:[tabView focusChordIndex] + indexesBeforeFocus];
            break;
        }
            
        case NSKeyValueChangeRemoval: {
            NSIndexSet *indexes = [change valueForKey:@"indexes"];
            NSUInteger indexForFocusAdjustment = [tabView focusChordIndex] + ([self isInSoloMode] ? 1 : 0);
            NSUInteger indexesBeforeFocus = [indexes countOfIndexesInRange:NSMakeRange(0, indexForFocusAdjustment)];
            [tabView setFocusChordIndex:[tabView focusChordIndex] - indexesBeforeFocus];
            break;
        }
            
        default:
            // I'm pretty sure this shouldn't happen
            break;
    }
    [tabView setNeedsDisplay:YES];
}

@end
