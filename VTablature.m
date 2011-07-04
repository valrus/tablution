//
//  VTablature.m
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VTablature.h"

@implementation VTablature

- (NSUInteger) strings { return numStrings; }

- (id)initWithStrings:(NSUInteger)num
{
    // Returns an initialized VTablature with space for eight notes, no strings played.
    self = [super init];
    if (self) {
        numStrings = num;
        // outer array holds "notes"
        tabData = [[NSMutableArray arrayWithCapacity:32] retain];
        
        int noteNumber, stringNumber;
        for (noteNumber = 0; noteNumber < 8; noteNumber ++) {
            // inner array holds "strings"
            [tabData addObject:[NSMutableArray arrayWithCapacity:numStrings]];
            for (stringNumber = 0; stringNumber < numStrings; stringNumber ++) {
                [[tabData objectAtIndex:noteNumber] addObject:[NSNumber numberWithInt:-1]];
            }
        }
        // NSLog([tabData description]);
        return self;
    } else {
        return nil;
    }
}

- (id) init
{
    NSLog(@"VTablature init");
    return [self initWithStrings:6];
}

- (NSUInteger) length { return [tabData count]; }

- (NSUInteger) fretAtLocation:(NSUInteger)location
                     onString:(NSUInteger)stringNum
{
    NSNumber *fretNum = [[tabData objectAtIndex:location] objectAtIndex:stringNum];
    return [fretNum intValue];
}

- (NSString *) asText
{
    NSMutableString *tabText = [NSMutableString stringWithCapacity:32];
    
    NSEnumerator *instrStringsEnum;
    NSNumber *aNote;
    NSMutableArray *stringsArray = [NSMutableArray arrayWithCapacity:numStrings];
    id tabNote;
    
    int stringNum;
    for (stringNum = 0; stringNum < numStrings; stringNum ++) {
        // NSLog(@"string %i", stringNum);
        instrStringsEnum = [tabData objectEnumerator];
        while ( tabNote = [instrStringsEnum nextObject] ) {
            aNote = [tabNote objectAtIndex:stringNum];
            if ( [aNote intValue] < 0 ) {
                // negative values indicate unplayed strings
                [tabText appendString:@"———"];
                // NSLog([NSString stringWithFormat:@"Unplayed string: %@", tabText]);
            } else {
                [tabText appendString:[VTablature getNoteTextForString:[aNote stringValue]]];
                // NSLog(@"String value: %i", [aNote intValue]);
            }
        }
        [stringsArray addObject:[tabText copy]];
        [tabText setString:@""];
    }
    [tabText setString:[stringsArray componentsJoinedByString:@"\n"]];
    return tabText;
}

- (void) addNoteAtIndex:(NSUInteger)noteIndex
{
    int stringNumber;
	
	// make an array with no strings fretted
	NSMutableArray *emptyStringsArray = [NSMutableArray arrayWithCapacity:numStrings];
    for (stringNumber = 0; stringNumber < numStrings; stringNumber ++)
	{
		[emptyStringsArray addObject:[NSNumber numberWithInt:-1]];
	}
	
	// insert it
    [tabData insertObject:emptyStringsArray
				  atIndex:noteIndex];
}

- (void) addNoteAtLocation:(NSUInteger)location
                  onString:(NSUInteger)stringNum
                    onFret:(NSUInteger)fretNum
{
    [[tabData objectAtIndex:location] replaceObjectAtIndex:stringNum
                                                withObject:[NSNumber numberWithInt:fretNum]];
}

+ (NSString *) getNoteTextForString:(NSString *)fretText
{
    // A note with a string marked should look like "-2-" or "-13"
    // depending on the length of the fret number. Prepend a hyphen
    // and then append enough more to make the total length 5.
    return [@"-" stringByAppendingString:[fretText stringByPaddingToLength:2 
																withString:@"—"
														   startingAtIndex:0]];
}

+ (NSString *) getNoteTextForValue:(NSUInteger)fretNum
{
    return [VTablature getNoteTextForString:[NSString stringWithFormat:@"%i", fretNum]];
}

@end
