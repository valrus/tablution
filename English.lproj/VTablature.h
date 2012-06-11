//
//  VTablature.h
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright 2008 valrusware. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VChord.h"

@interface VTablature : NSObject {
    NSMutableArray *chords;
    
    NSUInteger numStrings;
}

@property (strong) NSMutableArray *chords;
@property (readonly) NSUInteger numStrings;

// setup stuff
- (id)initWithStrings:(NSUInteger)num;
- (id)init;
+ (VTablature *)tablatureWithString:(NSString *)tabText;

// get information about tab
- (NSArray *)asArrayOfStrings;
- (NSString *)asText;
- (NSInteger)fretAtIndex:(NSUInteger)index
                onString:(NSUInteger)stringNum;
- (id)objectInChordsAtIndex:(NSUInteger)index;
- (NSArray *)chordsAtIndexes:(NSIndexSet *)indexSet;
- (VChord *)lastChord;
- (NSUInteger)countOfChords;

// alter the tab
- (void)insertNoteAtIndex:(NSUInteger)index
                 onString:(NSUInteger)stringNum
                   onFret:(NSUInteger)fretNum;
- (void)insertNote:(VNote *)note
           atIndex:(NSUInteger)index
          onString:(NSUInteger)stringNum;
- (void)insertChordFromArray:(NSArray *)chordArray
                     atIndex:(NSUInteger)index;
- (void)insertObject:(VChord *)chord
     inChordsAtIndex:(NSUInteger)index;
- (void)addChordFromArray:(NSArray *)chordArray;
- (void)addChordFromString:(NSString *)chordString;
- (void)deleteNoteAtIndex:(NSUInteger)index
                 onString:(NSUInteger)stringNum;
- (void)removeObjectFromChordsAtIndex:(NSUInteger)index;
- (void)extend;

// convert tab data to text
+ (NSString *)getNoteTextForString:(NSString *)fretText;
+ (NSString *)getNoteTextForValue:(NSUInteger)fretNum;
- (NSString *)toSerialString;

// NSFastEnumeration protocol
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len;

@end