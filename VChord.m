//
//  VChord.m
//  tablution
//
//  Created by Ian Mccowan on 7/9/11.
//

#import "VChord.h"
#import "VNote.h"

static NSUInteger numStrings = 6;

@implementation VChord

@synthesize notes;
@synthesize attrs;

// init
- (VChord *)initWithArray:(NSArray *)fretArray
{
    self = [super init];
    if (self) {
        notes = [NSMutableArray arrayWithArray:fretArray];
        attrs = nil;
        return self;
    } else {
        return nil;
    }
}

- (VChord *)initWithNote:(VNote *)note
{
    self = [super init];
    if (self) {
        NSMutableArray *fretArray = [NSMutableArray arrayWithCapacity:numStrings];
        NSNumber *noteFret = [NSNumber numberWithInt:[note fret]];
        NSUInteger noteString = [note stringNum];
        NSUInteger i;
        for (i = 0; i < numStrings; i++) {
            if (i == noteString) {
                [fretArray addObject:noteFret];
            } else {
                [fretArray addObject:[NSNumber numberWithInt:-1]];
            }
        }
        return self;
    } else {
        return nil;
    }
}

// access
- (VNote *)noteOnString:(NSUInteger)stringNum
{
    return [VNote noteOnString:stringNum
                        atFret:[[notes objectAtIndex:stringNum] intValue]];
}

- (NSUInteger)fretOnString:(NSUInteger)stringNum
{
    return [[notes objectAtIndex:stringNum] intValue];
}

- (void)addNote:(VNote *)note
{
    [notes replaceObjectAtIndex:[note stringNum]
                     withObject:[NSNumber numberWithInt:[note fret]]];
}

- (void)addFret:(NSUInteger)fret
       onString:(NSUInteger)stringNum
{
    [notes replaceObjectAtIndex:stringNum
                     withObject:[NSNumber numberWithInt:fret]];
}
@end
