//
//  VTabController.m
//  tablution
//
//  Created by Ian McCowan on 9/30/08.
//  Copyright 2008 valrusware. All rights reserved.
//

#import "VTabController.h"
#import "VTabDocument.h"
#import "VTablature.h"
#import "VTabView.h"
#import "tablution-Swift.h"
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

#pragma mark - Setup -

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
    [tablature addObserver:self
                forKeyPath:@"bars"
                   options:0
                   context:NULL];
}

#pragma mark - Editing selectors -
#pragma mark Chord-level changes

- (void)insertBlankChord
{
    NSMutableArray *emptyFrets = [NSMutableArray arrayWithCapacity:[tablature numStrings]];
    for (NSUInteger i = 0; i < [tablature numStrings]; ++i) {
        [emptyFrets addObject:[NSNumber numberWithInt:[VNote NO_FRET]]];
    }
    NSArray *oneBlankChord = [NSArray arrayWithObject:[VChord chordWithIntArray:emptyFrets]];
    if ([tabView hasSelection]) {
        [self replaceSelectedChordsWithChords:oneBlankChord];
    }
    else {
        NSUInteger focusIndex = [tabView focusChordIndexForMode] + 1;
        NSIndexSet *focusIndexSet = [NSIndexSet indexSetWithIndex:focusIndex];
        [self insertChords:oneBlankChord atIndexes:focusIndexSet andSelectThem:NO];
    }
}

- (void)insertChords:(NSArray *)chordArray
           atIndexes:(NSIndexSet *)indexes
       andSelectThem:(BOOL)doSelect
{
    [[[tabDoc undoManager] prepareWithInvocationTarget:tablature]
     removeChordsAtIndexes:indexes];
    [[tabDoc undoManager] setActionName:NSLocalizedString(@"Insert Chords",
                                                          @"insert chords undo")];
    [tablature insertChords:chordArray
                  atIndexes:indexes];
    if (doSelect) {
        [tabView selectIndexes:indexes];
    }
}

- (void)removeChordAtIndex:(NSUInteger)index
{
    [tablature removeObjectFromChordsAtIndex:index];
}

- (void)deleteSelectedChords
{
    NSIndexSet *selectedIndexes = [tabView selectedIndexes];
    [[[tabDoc undoManager] prepareWithInvocationTarget:self]
     insertChords:[tablature chordsAtIndexes:selectedIndexes]
     atIndexes:selectedIndexes
     andSelectThem:YES];
    [[tabDoc undoManager] setActionName:NSLocalizedString(@"Delete Selection",
                                                          @"delete selection undo")];
    [tablature removeChordsAtIndexes:selectedIndexes];
    [tabView clearSelection];
}

- (void)replaceSelectedChordsWithChords:(NSArray *)chordArray
{
    NSRange insertionRange = NSMakeRange([[tabView selectedIndexes] firstIndex],
                                         [chordArray count]);
    [[[tabDoc undoManager] prepareWithInvocationTarget:tablature]
     replaceChordsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:insertionRange]
                 withChords:[tabView selectedChords]];
    [[tabDoc undoManager] setActionName:NSLocalizedString(@"Replace Selected Chords",
                                                          @"replace selection undo")];
    [tablature removeChordsAtIndexes:[tabView selectedIndexes]];
    
    NSIndexSet *insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:insertionRange];
    [tablature insertChords:chordArray atIndexes:insertionIndexes];
    [tabView selectIndexes:insertionIndexes];
}

- (void)toggleMeasureBar
{
    [[[tabDoc undoManager] prepareWithInvocationTarget:tablature]
     toggleBarAtIndex:[tabView focusChordIndexForMode]];
    [[tabDoc undoManager] setActionName:NSLocalizedString(@"Undo Toggle Measure Bar",
                                                          @"toggle bar undo")];
    [tablature toggleBarAtIndex:[tabView focusChordIndexForMode]];
}

#pragma mark Note-level changes

- (void)prepareUndoForChangeFromNote:(VNote *)previousNote
                            onString:(NSUInteger)whichString
{
    [[[tabDoc undoManager] prepareWithInvocationTarget:tablature]
     insertNote:previousNote
     atIndex:[tabView focusChordIndexForMode]
     onString:whichString];
    [[tabDoc undoManager] setActionName:NSLocalizedString(@"Change Note",
                                                          @"change note undo")];
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
    NSInteger fretNum = [whichFret intValue] + [[tabDoc baseFret] intValue];
    if ([whichString intValue] < [tablature numStrings]) {
        if ([self isInSoloMode]) {
            VChord *newChord = [VChord chordWithOneFret:fretNum
                                               onString:stringNum
                                             numStrings:[tablature numStrings]];
            [[[tabDoc undoManager] prepareWithInvocationTarget:self]
             removeChordAtIndex:[tabView focusChordIndexForMode] + 1];
            [[tabDoc undoManager] setActionName:NSLocalizedString(@"Add Solo Note",
                                                                  @"add solo note undo")];
            [tablature insertObject:newChord
                    inChordsAtIndex:[tabView focusChordIndexForMode] + 1];
        }
        else {
            [self prepareUndoForChangeFromNote:[tabView focusChord][stringNum]
                                      onString:stringNum];
            [tablature insertNoteAtIndex:[tabView focusChordIndexForMode]
                                onString:stringNum
                                  onFret:fretNum];
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
        [tablature deleteNoteAtIndex:[tabView focusChordIndexForMode]
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
    [tabView setFocusNoteString:(currentMode ? 0 : 1)];
}

#pragma mark Focus changes

- (bool)focusNextChord
{
    if ([tabView focusChordIndexForMode] < [tablature countOfChords] - 1) {
        [tabView focusNextChord];
        return YES;
    }
    return NO;
}

- (bool)focusPrevChord
{
    
    if ([tabView currFocusChordIndex] > 0) {
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

#pragma mark Information

- (BOOL)isInSoloMode
{
    return [[tabDoc soloMode] boolValue];
}

#pragma mark - AppKit overrides -
#pragma mark inputManager

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
    if ([tabView hasSelection]) {
        [self deleteSelectedChords];
    }
    else if ([tabView currFocusChordIndex] > 0) {
        [[[tabDoc undoManager] prepareWithInvocationTarget:tablature]
         insertObject:[tablature objectInChordsAtIndex:[tabView focusChordIndexForMode]]
         inChordsAtIndex:[tabView focusChordIndexForMode]];
        [[tabDoc undoManager] setActionName:NSLocalizedString(@"Delete Chord",
                                                              @"delete chord undo")];
        [tablature removeObjectFromChordsAtIndex:[tabView focusChordIndexForMode]];
    }
}

#pragma mark KVO

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
            NSUInteger indexForFocusAdjustment = [tabView focusChordIndexForMode]
                                                 + ([self isInSoloMode] ? 3 : 2);
            NSRange rangeBeforeFocus = NSMakeRange(0, indexForFocusAdjustment);
            NSUInteger indexesBeforeFocus = [indexes countOfIndexesInRange:rangeBeforeFocus];
            [tabView setCurrFocusChordIndex:[tabView currFocusChordIndex] + indexesBeforeFocus];
            break;
        }
            
        case NSKeyValueChangeRemoval: {
            NSIndexSet *indexes = [change valueForKey:@"indexes"];
            NSUInteger indexForFocusAdjustment = [tabView focusChordIndexForMode]
                                                 + ([self isInSoloMode] ? 1 : 0);
            // If focus is on the very last chord, we need to pull it back one farther
            // so it doesn't drop off the end.
            if ([tabView focusChordIndexForMode] >= [[self tablature] countOfChords]) {
                indexForFocusAdjustment += 1;
            }
            NSRange rangeBeforeFocus = NSMakeRange(0, indexForFocusAdjustment);
            NSUInteger indexesBeforeFocus = [indexes countOfIndexesInRange:rangeBeforeFocus];
            [tabView setCurrFocusChordIndex:[tabView currFocusChordIndex] - indexesBeforeFocus];
            break;
        }
            
        default:
            // I'm pretty sure this shouldn't happen
            break;
    }
    [tabView setNeedsDisplay:YES];
}

@end
