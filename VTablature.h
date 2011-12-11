//
//  VTablature.h
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright 2008 valrusware. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Fraction.h"
#import "VChord.h"

@interface VTablature : NSObject {
    NSMutableDictionary *tabData;
    
    NSUInteger numStrings;
    Fraction *tabLength;
}

@property (readonly) NSUInteger numStrings;
@property (readonly) Fraction *tabLength;

// setup stuff
- (id)initWithStrings:(NSUInteger)num;
- (id)init;

// get information about tab
- (NSString *)asText;
- (NSInteger)fretAtLocation:(Fraction *)location
                   onString:(NSUInteger)stringNum;
- (VChord *)chordAtLocation:(Fraction *)location;

// alter the tab
- (void)addNoteAtLocation:(Fraction *)location
                 onString:(NSUInteger)stringNum
                   onFret:(NSUInteger)fretNum;

// convert tab data to text
+ (NSString *)getNoteTextForString:(NSString *)fretText;
+ (NSString *)getNoteTextForValue:(NSUInteger)fretNum;

@end
