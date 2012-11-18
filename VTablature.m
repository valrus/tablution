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

NSString * const VTABLATURE_DATA_UTI = @"com.valrusware.tablature";

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

+ (VTablature *)tablatureWithChords:(NSArray *)chords
{
    VTablature *newTab = [[VTablature alloc] init];
    [newTab insertChords:[NSArray arrayWithArray:chords]
               atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [chords count])]];
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
#pragma mark Teardown

- (void) dealloc
{
    [chords removeObserver:self
      fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [chords count])]
                forKeyPath:@"notes"];
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

- (void)insertChords:(NSArray *)chordArray
           atIndexes:(NSIndexSet *)indexes
{
    [chords insertObjects:chordArray atIndexes:indexes];
    [chords addObserver:self
     toObjectsAtIndexes:indexes
             forKeyPath:@"notes"
                options:0
                context:NULL];
}

- (void)addChordFromArray:(NSArray *)chordArray
{
    VChord *newChord = [VChord chordWithArray:chordArray];
    [chords addObject:newChord];
    [newChord addObserver:self
               forKeyPath:@"notes"
                  options:0
                  context:NULL];
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
    [chords removeObserver:self
      fromObjectsAtIndexes:indexes
                forKeyPath:@"notes"
                   context:NULL];
    [chords removeObjectsAtIndexes:indexes];
}

- (void)replaceChordsAtIndexes:(NSIndexSet *)indexes
                    withChords:(NSArray *)array
{
    [self removeChordsAtIndexes:indexes];
    NSRange insertRange = NSMakeRange([indexes firstIndex], [array count]);
    [self insertChords:array atIndexes:[NSIndexSet indexSetWithIndexesInRange:insertRange]];
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
    [chords removeObserver:self
      fromObjectsAtIndexes:[NSIndexSet indexSetWithIndex:index]
                forKeyPath:@"notes"];
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
    return [self getNoteTextForString:[NSString stringWithFormat:@"%lu", fretNum]];
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

#pragma mark -
#pragma mark NSPasteboardWriting protocol

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return [NSArray arrayWithObject:VTABLATURE_DATA_UTI];
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type
                                         pasteboard:(NSPasteboard *)pasteboard
{
    return 0;
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    if ([type isEqualToString:VTABLATURE_DATA_UTI]) {
        return [self toSerialString];
    }
    return nil;
}

#pragma mark -
#pragma mark NSPasteboardReading protocol

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return [NSArray arrayWithObject:VTABLATURE_DATA_UTI];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type
                                         pasteboard:(NSPasteboard *)pasteboard
{
    if ([type isEqualToString:VTABLATURE_DATA_UTI]) {
        return NSPasteboardReadingAsString;
    }
    return 0;
}

- (id)initWithPasteboardPropertyList:(id)propertyList
                              ofType:(NSString *)type
{
    if ([type isEqualToString:VTABLATURE_DATA_UTI]) {
        return [VTablature tablatureWithString:propertyList];
    }
    return nil;
}

#pragma mark -
#pragma mark NSCoding protocol

#define kChords     @"chords"
#define kStrings    @"numStrings"

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[self chords] forKey:kChords];
}

@end
