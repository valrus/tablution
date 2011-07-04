//
//  VTabDocument.h
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VTablature.h"
#import "VTabController.h"

@interface VTabDocument : NSDocument
{
	VTablature *theTablature;
    
    NSUInteger currentLocation;
    NSUInteger currentString;
    NSUInteger baseFret;
    
    NSRange currentSelection;
}

// get information about the tab
- (VTablature *) tablature;
- (NSUInteger) cursorLocation;
- (NSUInteger) cursorString;
- (NSUInteger) tabLength;
- (NSUInteger) baseFret;
- (NSRange) cursorTextRange;
- (NSArray *) cursorTextRanges;
- (NSRange) textRangeForString:(NSUInteger)stringNum
					atLocation:(NSUInteger)location;
- (BOOL) atEndOfTab;

// editing
- (void) advanceCurrentLocation;
- (void) recedeCurrentLocation;
- (void) upString;
- (void) downString;
- (void) addNoteOnString:(NSNumber *)stringNum
                  onFret:(NSNumber *)fretNum;
- (void) incrementBaseFret;
- (void) decrementBaseFret;
- (void) insertNoteBefore:(NSUInteger)noteIndex;
- (void) changeSelectionToIndex:(NSUInteger)clickIndex;

// hook into a tab
- (void) setTablature:(VTablature *)aTablature;

@end