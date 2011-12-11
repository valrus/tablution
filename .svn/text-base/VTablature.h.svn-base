//
//  VTablature.h
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VTablature : NSObject {
    NSMutableArray *tabData;
    
    int numStrings;
}

// setup stuff
- (id)initWithStrings:(NSUInteger)num;
- (id)init;

// get information about tab
- (NSUInteger) strings;
- (NSUInteger) length;
- (NSString *) asText;
- (NSUInteger) fretAtLocation:(NSUInteger)location
                     onString:(NSUInteger)stringNum;

// alter the tab
- (void) addNoteAtIndex:(NSUInteger)noteIndex;
- (void) addNoteAtLocation:(NSUInteger)location
                  onString:(NSUInteger)stringNum
                    onFret:(NSUInteger)fretNum;

// convert tab data to text
+ (NSString *) getNoteTextForString:(NSString *)fretText;
+ (NSString *) getNoteTextForValue:(NSUInteger)fretNum;

@end
