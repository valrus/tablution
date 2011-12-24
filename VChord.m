//
//  VChord.m
//  tablution
//
//  Created by Ian Mccowan on 7/9/11.
//

#import "VChord.h"
#import "VNote.h"

@implementation VChord

@synthesize notes;
@synthesize attrs;

// construct

+ (VChord *)chordWithArray:(NSArray *)fretArray
{
    return [[[self alloc] initWithArray:fretArray] autorelease];
}

+ (VChord *)chordWithStrings:(NSUInteger)numStrings
                    withNote:(VNote *)note
                    onString:(NSUInteger)string
{
    return [[[self alloc] initWithStrings:(NSUInteger)numStrings
                                 withNote:(VNote *)note
                                 onString:(NSUInteger)string] autorelease];
}

+ (VChord *)chordWithStrings:(NSUInteger)numStrings
                    withFret:(NSInteger)fret
                    onString:(NSUInteger)string
{
    return [[[self alloc] initWithStrings:(NSUInteger)numStrings
                                 withFret:(NSInteger)fret
                                 onString:(NSUInteger)string] autorelease];
}

// init
- (VChord *)initWithArray:(NSArray *)fretArray
{
    self = [super init];
    if (self) {
        notes = [NSMutableArray arrayWithCapacity:[fretArray count]];
        NSUInteger i;
        for (i = 0; i < [fretArray count]; i++) {
            [notes addObject:[VNote noteAtFret:[[fretArray objectAtIndex:i] intValue]]];
        }
        attrs = nil;
        return self;
    } else {
        return nil;
    }
}

- (VChord *)initWithStrings:(NSUInteger)numStrings
                   withNote:(VNote *)note
                   onString:(NSUInteger)string
{
    self = [super init];
    
    if (self) {
        notes = [NSMutableArray arrayWithCapacity:numStrings];
        NSUInteger i;
        for (i = 0; i < numStrings; i++) {
            if (i == string) {
                [notes addObject:note];
            } else {
                [notes addObject:[VNote blankNote]];
            }
        }
        return self;
    } else {
        return nil;
    }
}

- (VChord *)initWithStrings:(NSUInteger)numStrings
                   withFret:(NSInteger)fret
                   onString:(NSUInteger)string;
{
    VNote *newNote = [VNote noteAtFret:fret];
    return [self initWithStrings:numStrings
                        withNote:newNote
                        onString:string];
}

// access
- (VNote *)noteOnString:(NSUInteger)stringNum
{
    assert(stringNum > 0 && stringNum <= [[self notes] count]);
    return [notes objectAtIndex:stringNum];
}

- (NSInteger)fretOnString:(NSUInteger)stringNum
{
    return [[notes objectAtIndex:stringNum] fret];
}

- (void)addNote:(VNote *)note
       onString:(NSUInteger)stringNum
{
    [notes replaceObjectAtIndex:stringNum
                     withObject:note];
}

- (void)addFret:(NSInteger)fret
       onString:(NSUInteger)stringNum
{
    [notes replaceObjectAtIndex:stringNum
                     withObject:[VNote noteAtFret:fret]];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id *)stackbuf
                                    count:(NSUInteger)len
{
    // just "delegate" this to internal NSMutableArray
    return [notes countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
