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
    NSMutableArray *tabData;
    
    NSUInteger numStrings;
}

@property (readonly) NSUInteger numStrings;

// setup stuff
- (id)initWithStrings:(NSUInteger)num;
- (id)init;

// get information about tab
- (NSString *)asText;
- (NSInteger)fretAtindex:(NSUInteger)index
                onString:(NSUInteger)stringNum;
- (VChord *)chordAtIndex:(NSUInteger)index;
- (NSArray *)chordsAtIndexes:(NSIndexSet *)indexSet;
- (VChord *)lastChord;
- (NSUInteger)tabLength;

// alter the tab
- (void)insertNoteAtindex:(NSUInteger)index
                 onString:(NSUInteger)stringNum
                   onFret:(NSUInteger)fretNum;
- (void)insertChordFromArray:(NSArray *)chordArray
                     atindex:(NSUInteger)index;
- (void)addChordFromArray:(NSArray *)chordArray;
- (void)addChordFromString:(NSString *)chordString;
- (void)extend;

// convert tab data to text
+ (NSString *)getNoteTextForString:(NSString *)fretText;
+ (NSString *)getNoteTextForValue:(NSUInteger)fretNum;

// NSFastEnumeration protocol
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len;

@end
