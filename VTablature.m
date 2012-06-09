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
    return newTab;
}

- (NSArray *)asArrayOfStrings
{
    return [tabData valueForKey:@"asText"];
}

- (NSString *)asText
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
    return [self chordAtIndex:[self tabLength] - 1];
}

- (NSUInteger)tabLength
{
    return [tabData count]; 
}

- (void)insertNoteAtIndex:(NSUInteger)index
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
                     atIndex:(NSUInteger)index
{
    [self insertChord:[VChord chordWithArray:chordArray]
              atIndex:index];
}

- (void)insertChord:(VChord *)chord
            atIndex:(NSUInteger)index
{
    [tabData insertObject:chord atIndex:index];
}

- (void)addChordFromArray:(NSArray *)chordArray
{
    [tabData addObject:[VChord chordWithArray:chordArray]];
}

- (void)addChordFromString:(NSString *)chordString
{
    VChord *newChord;
    if ((newChord = [VChord chordWithStrings:numStrings
                                    fromText:chordString])) {
        [tabData addObject:newChord];
    }
    else {
        // invalid chord
    }
}

- (void)deleteNoteAtIndex:(NSUInteger)index
                 onString:(NSUInteger)stringNum
{
    [self insertNoteAtIndex:index onString:stringNum onFret:NO_FRET];
}

- (void)deleteChordAtIndex:(NSUInteger)index
{
    if (index < [self tabLength]) {
        [tabData removeObjectAtIndex:index];
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

+ (NSString *)getNoteTextForValue:(NSUInteger)fretNum
{
    return [self getNoteTextForString:[NSString stringWithFormat:@"%i", fretNum]];
}

- (NSString *)toSerialString
{
    return [[self asArrayOfStrings] componentsJoinedByString:@"\n"];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len
{
    // just "delegate" this to internal NSMutableArray
    return [tabData countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
