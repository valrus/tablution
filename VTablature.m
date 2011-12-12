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

#define NUM_STRINGS 6

@implementation VTablature

@synthesize numStrings;
@synthesize tabLength;

- (id)initWithStrings:(NSUInteger)num
{
    // Returns an initialized VTablature.
    self = [super init];
    if (self) {
        numStrings = num;

        tabData = [[NSMutableArray arrayWithCapacity:10] retain];
        tabLength = 1;
        
        return self;
    } else {
        return nil;
    }
}

- (id) init
{
    NSLog(@"VTablature init");
    return [self initWithStrings:NUM_STRINGS];
}

- (NSString *) asText
{
    // FIXME: stub
    return @"";
}

- (NSInteger)fretAtLocation:(NSUInteger)location
                   onString:(NSUInteger)stringNum
{
    VChord *soughtChord;
    if ((soughtChord = [tabData objectAtIndex:location])) {
        return [[soughtChord noteOnString:stringNum] fret];
    } else {
        return -1;
    }
}

- (VChord *)chordAtLocation:(NSUInteger)location
{
    VChord *soughtChord;
    if ((soughtChord = [tabData objectAtIndex:location])) {
        return soughtChord;
    } else {
        return nil;
    }

}

- (void)insertNoteAtLocation:(NSUInteger)location
                    onString:(NSUInteger)stringNum
                      onFret:(NSUInteger)fretNum
{
    id noteAlready;
    id newChord;
    if ((noteAlready = [tabData objectAtIndex:location])) {
        newChord = [noteAlready plusNoteOnString:stringNum
                                             onFret:fretNum];
    } else {
        newChord = [VNote noteOnString:stringNum atFret:fretNum];
    }
    [tabData replaceObjectAtIndex:location withObject:newChord];
}

- (void)insertChordFromArray:(NSArray *)chordArray
                  atLocation:(NSUInteger)location
{
    [tabData insertObject:[[VChord alloc] initWithArray:chordArray]
                  atIndex:location];
}

- (void)addChordFromArray:(NSArray *)chordArray
{
    [tabData addObject:[[VChord alloc] initWithArray:chordArray]];
}

+ (NSString *) getNoteTextForString:(NSString *)fretText
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

@end
