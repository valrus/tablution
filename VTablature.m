//
//  VTablature.m
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VTablature.h"
#import "VChord.h"
#import "VNote.h"

#define MAX_STRINGS 7

@implementation VTablature

@synthesize chords;
@synthesize numStrings;

#pragma mark -
#pragma mark Init and setup

- (id)initWithStrings:(NSUInteger)num
{
    // Returns an initialized VTablature.
    self = [super init];
    if (self) {
        numStrings = 6; // TODO: make not hardcoded
        chords = [NSMutableArray arrayWithCapacity:10];
        return self;
    } else {
        return nil;
    }
}

- (id)init
{
    NSLog(@"VTablature init");
    return [self initWithStrings:numStrings];
}

+ (VTablature *)tablatureWithString:(NSString *)tabText
{
    VTablature *newTab = [[VTablature alloc] init];
    NSArray *chordTexts = [tabText componentsSeparatedByString:@"\n"];
    for (NSString *chordText in chordTexts) {
        [newTab addChordFromString:chordText];
    }
    [[newTab chords] addObserver:newTab
              toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [newTab countOfChords])]
                      forKeyPath:@"notes"
                         options:0
                         context:NULL];
    return newTab;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    NSLog(@"VTablature sees a change in a chord's %@!", keyPath);
}

#pragma mark -
#pragma mark KVC-compliant accessors

- (id)objectInChordsAtIndex:(NSUInteger)index
{
    VChord *soughtChord;
    if ((soughtChord = [chords objectAtIndex:index])) {
        return soughtChord;
    } else {
        return nil;
    }
}

- (NSArray *)chordsAtIndexes:(NSIndexSet *)indexSet
{
    return [chords objectsAtIndexes:indexSet];
}

- (NSUInteger)countOfChords
{
    return [chords count]; 
}

- (void)insertObject:(VChord *)chord
     inChordsAtIndex:(NSUInteger)index
{
    [chords insertObject:chord atIndex:index];
    [chord addObserver:self forKeyPath:@"notes" options:0 context:NULL];
}

- (void)insertChords:chordArray
           atIndexes:indexes
{
    [chords insertObjects:chordArray atIndexes:indexes];
}

- (void)addChordFromArray:(NSArray *)chordArray
{
    VChord *newChord = [VChord chordWithArray:chordArray];
    [chords addObject:newChord];
    [newChord addObserver:self forKeyPath:@"notes" options:0 context:NULL];
}

- (void)addChordFromString:(NSString *)chordString
{
    VChord *newChord;
    if ((newChord = [VChord chordWithStrings:numStrings
                                    fromText:chordString])) {
        [chords addObject:newChord];
    }
    else {
        // invalid chord
    }
}

- (void)deleteNoteAtIndex:(NSUInteger)index
                 onString:(NSUInteger)stringNum
{
    [self insertNote:[VNote blankNote]
             atIndex:index onString:stringNum];
}

- (void)removeObjectFromChordsAtIndex:(NSUInteger)index
{
    if (index < [self countOfChords]) {
        [chords removeObserver:self
          fromObjectsAtIndexes:[NSIndexSet indexSetWithIndex:index]
                    forKeyPath:@"notes"
                       context:NULL];
        [chords removeObjectAtIndex:index];
    }
}

- (void)removeChordsAtIndexes:(NSIndexSet *)indexes
{
    [chords removeObjectsAtIndexes:indexes];
}

#pragma mark -
#pragma mark Other accessors

- (VChord *)lastChord
{
    return [self objectInChordsAtIndex:[self countOfChords] - 1];
}

- (VNote *)noteAtIndex:(NSUInteger)index
              onString:(NSUInteger)stringNum
{
    VChord *soughtChord;
    if ((soughtChord = [chords objectAtIndex:index])) {
        return [soughtChord objectInNotesAtIndex:stringNum];
    } else {
        return nil;
    }
}

- (NSInteger)fretAtIndex:(NSUInteger)index
                onString:(NSUInteger)stringNum
{
    VNote *soughtNote;
    if ((soughtNote = [self noteAtIndex:index onString:stringNum])) {
        return [soughtNote fret];
    } else {
        return -1;
    }
}

#pragma mark Tab-level mutators

- (void)extend
{
    [self addChordFromString:@"-1 -1 -1 -1 -1 -1"];
}

#pragma mark Note-level mutators

- (void)insertNoteAtIndex:(NSUInteger)index
                 onString:(NSUInteger)stringNum
                   onFret:(NSUInteger)fretNum
{
    [self insertNote:[VNote noteAtFret:fretNum]
             atIndex:index
            onString:stringNum];
}

- (void)insertNote:(VNote *)note
           atIndex:(NSUInteger)index
          onString:(NSUInteger)stringNum
{
    id chordAlready;
    VChord *newChord;
    [self willChange:NSKeyValueChangeReplacement
     valuesAtIndexes:[NSIndexSet indexSetWithIndex:index]
              forKey:@"chords"];
    [[chords objectAtIndex:index] removeObserver:self];
    if ((chordAlready = [chords objectAtIndex:index])) {
        newChord = [VChord chordWithChord:chordAlready];
        [newChord replaceObjectInNotesAtIndex:stringNum
                                   withObject:note];
        [chords replaceObjectAtIndex:index withObject:newChord];
    }
    else {
        newChord = [VChord chordWithStrings:numStrings
                                   withNote:note
                                   onString:stringNum];
        [chords replaceObjectAtIndex:index withObject:newChord];
    }
    [newChord addObserver:self forKeyPath:@"notes" options:0 context:NULL];
    [self didChange:NSKeyValueChangeReplacement
    valuesAtIndexes:[NSIndexSet indexSetWithIndex:index]
             forKey:@"chords"];
}

- (void)insertChordFromArray:(NSArray *)chordArray
                     atIndex:(NSUInteger)index
{
    VChord *newChord = [VChord chordWithArray:chordArray];
    [self insertObject:newChord
       inChordsAtIndex:index];
    [newChord addObserver:self forKeyPath:@"notes" options:0 context:NULL];
}

#pragma mark -
#pragma mark Converting to strings

+ (NSString *)getNoteTextForString:(NSString *)fretText
{
    // A note with a string marked should look like "-2-" or "-13"
    // depending on the length of the fret number. Prepend a hyphen
    // and then append enough more to make the total length 5.
    return [@"-" stringByAppendingString:[fretText stringByPaddingToLength:2 
																withString:@"—"
														   startingAtIndex:0]];
}

+ (NSString *)getNoteTextForValue:(NSUInteger)fretNum
{
    return [self getNoteTextForString:[NSString stringWithFormat:@"%i", fretNum]];
}

- (NSString *)toSerialString
{
    return [[self asArrayOfStrings] componentsJoinedByString:@"\n"];
}

- (NSArray *)asArrayOfStrings
{
    return [chords valueForKey:@"asText"];
}

- (NSString *)asText
{
    // FIXME: stub
    return @"";
}

#pragma mark -
#pragma mark NSFastEnumeration protocol

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len
{
    // just "delegate" this to internal NSMutableArray
    return [chords countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
