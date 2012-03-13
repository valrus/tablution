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

@synthesize numStrings;

- (id)initWithStrings:(NSUInteger)num
{
    // Returns an initialized VTablature.
    self = [super init];
    if (self) {
        numStrings = 6; // TODO: make not hardcoded

        tabData = [NSMutableArray arrayWithCapacity:10];
        
        return self;
    } else {
        return nil;
    }
}

- (id) init
{
    NSLog(@"VTablature init");
    return [self initWithStrings:numStrings];
}

- (NSString *) asText
{
    // FIXME: stub
    return @"";
}

- (NSInteger)fretAtindex:(NSUInteger)index
                onString:(NSUInteger)stringNum
{
    VChord *soughtChord;
    if ((soughtChord = [tabData objectAtIndex:index])) {
        return [[soughtChord noteOnString:stringNum] fret];
    } else {
        return -1;
    }
}

- (VChord *)chordAtIndex:(NSUInteger)index
{
    VChord *soughtChord;
    if ((soughtChord = [tabData objectAtIndex:index])) {
        return soughtChord;
    } else {
        return nil;
    }
}

- (NSArray *)chordsAtIndexes:(NSIndexSet *)indexSet
{
    return [tabData objectsAtIndexes:indexSet];
}

- (VChord *)lastChord
{
    return [self chordAtIndex:[self tabLength]];
}

- (NSUInteger)tabLength
{
    return [tabData count]; 
}

- (void)insertNoteAtindex:(NSUInteger)index
                 onString:(NSUInteger)stringNum
                   onFret:(NSUInteger)fretNum
{
    id chordAlready;
    id newChord;
    if ((chordAlready = [tabData objectAtIndex:index])) {
        [chordAlready addFret:fretNum
                     onString:stringNum];
    } else {
        newChord = [VChord chordWithStrings:numStrings
                                   withFret:fretNum
                                   onString:stringNum];
    }
    [tabData replaceObjectAtIndex:index withObject:newChord];
}

- (void)insertChordFromArray:(NSArray *)chordArray
                  atindex:(NSUInteger)index
{
    [tabData insertObject:[VChord chordWithArray:chordArray]
                  atIndex:index];
}

- (void)addChordFromArray:(NSArray *)chordArray
{
    [tabData addObject:[VChord chordWithArray:chordArray]];
}

- (void)addChordFromString:(NSString *)chordString
{
    NSArray *fretStringsArray;
    NSArray *fretNumsArray;
    fretStringsArray = [chordString componentsSeparatedByString:@" "];
    if ([fretStringsArray count] == numStrings) {
        fretNumsArray = [fretStringsArray valueForKey:@"intValue"];
        [self addChordFromArray:fretNumsArray];
    }
}

- (void)extend
{
    NSLog(@"Extend tab length");
    [self addChordFromString:@"-1 -1 -1 -1 -1 -1"];
}

+ (NSString *)getNoteTextForString:(NSString *)fretText
{
    // A note with a string marked should look like "-2-" or "-13"
    // depending on the length of the fret number. Prepend a hyphen
    // and then append enough more to make the total length 5.
    return [@"-" stringByAppendingString:[fretText stringByPaddingToLength:2 
																withString:@"—"
														   startingAtIndex:0]];
}

+ (NSString *) getNoteTextForValue:(NSUInteger)fretNum
{
    return [VTablature getNoteTextForString:[NSString stringWithFormat:@"%i", fretNum]];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len
{
    // just "delegate" this to internal NSMutableArray
    return [tabData countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
