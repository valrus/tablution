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

#pragma mark - Setup -
#pragma mark Constructors

+ (VChord *)chordWithChord:(VChord *)oldChord;
{
    VChord *newChord = [[self alloc] init];
    [newChord setNotes:[oldChord notes] == nil ? nil : [NSMutableArray arrayWithArray:[oldChord notes]]];
    [newChord setAttrs:[oldChord attrs] == nil ? nil : [NSMutableDictionary dictionaryWithDictionary:[oldChord attrs]]];
    return newChord;
}

+ (VChord *)chordWithArray:(NSArray *)fretArray
{
    return [[self alloc] initWithArray:fretArray];
}

+ (VChord *)chordWithStrings:(NSUInteger)numStrings
                    withNote:(VNote *)note
                    onString:(NSUInteger)string
{
    return [[self alloc] initWithStrings:(NSUInteger)numStrings
                                 withNote:(VNote *)note
                                 onString:(NSUInteger)string];
}

+ (VChord *)chordWithStrings:(NSUInteger)numStrings
                    withFret:(NSInteger)fret
                    onString:(NSUInteger)string
{
    return [[self alloc] initWithStrings:(NSUInteger)numStrings
                                 withFret:(NSInteger)fret
                                 onString:(NSUInteger)string];
}

+ (VChord *)chordWithStrings:(NSUInteger)numStrings
                    fromText:(NSString *)chordString
{
    NSLog(@"Loading chord from string: %@", chordString);
    NSArray *fretStringsArray;
    NSArray *fretNumsArray;
    fretStringsArray = [chordString componentsSeparatedByString:@" "];
    if ([fretStringsArray count] >= numStrings) {
        fretNumsArray = [[fretStringsArray subarrayWithRange:NSMakeRange(0, numStrings)] valueForKey:@"intValue"];
        return [VChord chordWithArray:fretNumsArray];
    }
    else {
        return nil;
    }
}

#pragma mark Initializers

- (VChord *)init
{
    self = [super init];
    notes = nil;
    attrs = nil;
    return self;
}

- (VChord *)initWithArray:(NSArray *)fretArray
{
    self = [super init];
    if (self) {
        [self setNotes:[NSMutableArray arrayWithCapacity:[fretArray count]]];
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
        [self setNotes:[NSMutableArray arrayWithCapacity:numStrings]];
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

#pragma mark - Accessors and mutators -
#pragma mark Accessors

- (VNote *)objectInNotesAtIndex:(NSInteger)stringNum
{
    assert(stringNum == NO_FRET || (stringNum >= 0 && stringNum <= [[self notes] count]));
    if (stringNum == NO_FRET) {
        return nil;
    }
    return [notes objectAtIndex:stringNum];
}

- (NSInteger)fretOnString:(NSUInteger)stringNum
{
    return [[self objectInNotesAtIndex:stringNum] fret];
}

- (bool)hasNoteOnString:(NSUInteger)stringNum
{
    return ([self fretOnString:stringNum] != NO_FRET);
}

- (NSString *)asText
{
    return [[notes valueForKey:@"stringValue"] componentsJoinedByString:@" "];
}

- (NSIndexSet *)indexesOfChangedNotesFrom:(VChord *)otherChord
{
    NSUInteger stringCount = [[self notes] count];
    assert(stringCount == [[otherChord notes] count]);
    return [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, stringCount)]
            indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
                return ![[self objectInNotesAtIndex:idx]
                         isEqualToNote:[otherChord objectInNotesAtIndex:idx]];
            }];
}

#pragma mark Mutators

- (void)replaceObjectInNotesAtIndex:(NSUInteger)stringNum
                         withObject:(VNote *)note;
{
    [notes replaceObjectAtIndex:stringNum
                     withObject:note];
}

- (void)addFret:(NSInteger)fret
       onString:(NSUInteger)stringNum
{
    [self replaceObjectInNotesAtIndex:stringNum
                           withObject:[VNote noteAtFret:fret]];
}

- (void)insertObject:(VNote *)note
      inNotesAtIndex:(NSUInteger)stringNum;
{
    [self replaceObjectInNotesAtIndex:stringNum withObject:note];
}

- (void)removeObjectFromNotesAtIndex:(NSUInteger)stringNum
{
    [self addFret:NO_FRET onString:stringNum];
}

#pragma mark - NSFastEnumeration protocol -

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len
{
    // just "delegate" this to internal NSMutableArray
    return [notes countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
