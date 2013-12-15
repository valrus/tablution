//
//  VTablature.h
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright 2008 valrusware. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VChord.h"
#import "VNote.h"

@interface VTablature : NSObject <NSPasteboardWriting, NSPasteboardReading>
{
    NSMutableArray *chords;
    NSMutableIndexSet *measureBars;
    
    NSUInteger numStrings;
}

@property (strong) NSMutableArray *chords;
@property (strong) NSMutableIndexSet *measureBars;
@property (readonly) NSUInteger numStrings;

#pragma mark - Setup/teardown -
#pragma mark Setup

- (id)initWithStrings:(NSUInteger)num;
- (id)init;
+ (VTablature *)tablatureFromText:(NSString *)tabText;
+ (VTablature *)tablatureWithChords:(NSArray *)chords;

#pragma mark Teardown

- (void) dealloc;

#pragma mark - KVC compliance -
#pragma mark KVC-compliant accessors

- (id)objectInChordsAtIndex:(NSUInteger)index;
- (NSArray *)chordsAtIndexes:(NSIndexSet *)indexes;

#pragma mark KVC-compliant mutators

- (void)insertObject:(VChord *)chord
     inChordsAtIndex:(NSUInteger)index;
- (void)insertChords:(NSArray *)chordArray
           atIndexes:(NSIndexSet *)indexes;
- (void)removeObjectFromChordsAtIndex:(NSUInteger)index;
- (void)removeChordsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceChordsAtIndexes:(NSIndexSet *)indexes
                    withChords:(NSArray *)array;

#pragma mark - Other accessors and mutators -
#pragma mark Accessors

- (VNote *)noteAtIndex:(NSUInteger)index
              onString:(NSUInteger)stringNum;
- (NSInteger)fretAtIndex:(NSUInteger)index
                onString:(NSUInteger)stringNum;
- (VChord *)lastChord;
- (NSUInteger)countOfChords;
- (bool)hasBarAtIndex:(NSUInteger)index;

#pragma mark Mutators

- (void)addChordFromArray:(NSArray *)chordArray;
- (void)addChordFromString:(NSString *)chordString;
- (void)deleteNoteAtIndex:(NSUInteger)index
                 onString:(NSUInteger)stringNum;
- (void)extend;
- (void)insertChordFromText:(NSString *)chordText
                    atIndex:(NSUInteger)index;
- (void)toggleBarAtIndex:(NSUInteger)index;

#pragma mark Note-level mutators

- (void)insertNoteAtIndex:(NSUInteger)index
                 onString:(NSUInteger)stringNum
                   onFret:(NSUInteger)fretNum;
- (void)insertNote:(VNote *)note
           atIndex:(NSUInteger)index
          onString:(NSUInteger)stringNum;

#pragma mark - Converting to text -

+ (NSString *)getNoteTextForString:(NSString *)fretText;
+ (NSString *)getNoteTextForValue:(NSInteger)fretNum;
- (NSString *)toSerialString;
- (NSString *)toHumanReadableString;

#pragma mark - Protocols -
#pragma mark NSFastEnumeration protocol

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len;

#pragma mark NSPasteboardWriting protocol
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard;
- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type
                                         pasteboard:(NSPasteboard *)pasteboard;
- (id)pasteboardPropertyListForType:(NSString *)type;

#pragma mark NSPasteboardReading protocol
+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard;
+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type
                                         pasteboard:(NSPasteboard *)pasteboard;
- (id)initWithPasteboardPropertyList:(id)propertyList
                              ofType:(NSString *)type;

@end
