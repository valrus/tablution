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
    NSUInteger tabLength;
}

@property (readonly) NSUInteger numStrings;
@property (readonly) NSUInteger tabLength;

// setup stuff
- (id)initWithStrings:(NSUInteger)num;
- (id)init;

// get information about tab
- (NSString *)asText;
- (NSInteger)fretAtLocation:(NSUInteger)location
                   onString:(NSUInteger)stringNum;
- (VChord *)chordAtLocation:(NSUInteger)location;

// alter the tab
- (void)insertNoteAtLocation:(NSUInteger)location
                    onString:(NSUInteger)stringNum
                      onFret:(NSUInteger)fretNum;
- (void)insertChordFromArray:(NSArray *)chordArray
                  atLocation:(NSUInteger)location;
- (void)addChordFromArray:(NSArray *)chordArray;
- (void)addChordFromString:(NSString *)chordString;

// convert tab data to text
+ (NSString *)getNoteTextForString:(NSString *)fretText;
+ (NSString *)getNoteTextForValue:(NSUInteger)fretNum;

// NSFastEnumeration protocol
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id *)stackbuf
                                    count:(NSUInteger)len;

@end
