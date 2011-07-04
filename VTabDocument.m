//
//  VTabDocument.m
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import "VTabDocument.h"

@implementation VTabDocument

// get information about the tab

- (VTablature *) tablature { return theTablature; }
- (NSUInteger) cursorLocation { return currentLocation; }
- (NSUInteger) cursorString { return currentString; }
- (NSUInteger) tabLength { return [theTablature length]; }
- (NSUInteger) baseFret { return baseFret; }

- (NSRange) cursorTextRange
{
	// Return a text range that encompasses the five characters representing
	// the current location of the cursor on the tab.
	return [self textRangeForString:currentString
						 atLocation:currentLocation];
}

- (NSArray *)cursorTextRanges
{
	// Return an array of NSValues (containing NSRanges) representing the location of
	// the cursor on all the strings.
	NSMutableArray *returnArray =
		[[NSMutableArray alloc] initWithCapacity:[theTablature strings]];
	int stringCount;
	for (stringCount = 0; stringCount < 6; stringCount ++)
	{
		[returnArray addObject:[NSValue valueWithRange:[self textRangeForString:stringCount
																	 atLocation:currentLocation]]];
	}
	return returnArray;
}

- (NSRange)textRangeForString:(NSUInteger)stringNum
				   atLocation:(NSUInteger)location
{
	return NSMakeRange((3 * [self tabLength] + 1) * stringNum + 3 * location, 3);
}

- (BOOL) atEndOfTab {
    if (currentLocation < [self tabLength] - 1) { return NO; }
    else { return YES; }
}

// editing

- (void) advanceCurrentLocation
{
    if (![self atEndOfTab]) {
        currentLocation ++;
    }
}

- (void) recedeCurrentLocation
{ 
    if (currentLocation > 0) {
        currentLocation --; 
    }
}

- (void) upString
{
    if (currentString > 0) {
        currentString --;
    }
}

- (void) downString
{
    if (currentString < [theTablature strings] - 1) {
        currentString ++;
    }
}

- (void) addNoteOnString:(NSNumber *)stringNum
                  onFret:(NSNumber *)fretNum
{
    [theTablature addNoteAtLocation:currentLocation
                           onString:[stringNum intValue]
                             onFret:(baseFret + [fretNum intValue])];
}

- (void) incrementBaseFret
{
    if (baseFret < 30) {
        baseFret ++;
    }
}

- (void) decrementBaseFret;
{
    if (baseFret > 0) {
        baseFret --;
    }
}

- (void) insertNoteBefore:(NSUInteger)noteIndex
{
	[theTablature addNoteAtIndex:noteIndex];
}
	
- (void) changeSelectionToIndex:(NSUInteger)clickIndex
{
    NSUInteger textLength = [self tabLength] * 3 + 1;
    NSUInteger whichString = clickIndex / textLength;
    NSUInteger whichNote = (clickIndex % textLength) / 3;
    currentLocation = whichNote;
    currentString = whichString;
    // NSLog([NSString stringWithFormat:@"click index %i, length %i", clickIndex, textLength]);
    // NSLog([NSString stringWithFormat:@"string %i, index %i", whichString, whichNote]);
}

// setup stuff

- (void) setTablature: (VTablature *)newValue
{
    if (theTablature != newValue) {
        if (theTablature) [theTablature release];
        
        theTablature = [newValue retain];
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        
        if (theTablature == nil) {
            theTablature = [[VTablature alloc] initWithStrings:6];
            currentLocation = 0;
            currentString = 0;
            currentSelection = NSMakeRange(0,0);
            baseFret = 0;
        }
    }
    return self;
}

- (void)makeWindowControllers
{
    VTabController *tabController =
    [ [VTabController alloc] initWithWindowNibName:[self windowNibName] ];
    
	[tabController autorelease];
    [self addWindowController:tabController];
    
    [tabController setDocument:self];
}

- (NSString *)windowNibName
{
    return @"TabDocument";
}

// saving and loading

- (NSData *)dataOfType:(NSString *)typeName
                 error:(NSError **)outError
{
    NSData *data;
    
    data = [NSArchiver archivedDataWithRootObject:[self tablature]];
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return data;
}

- (BOOL)readFromData:(NSData *)data
              ofType:(NSString *)typeName
               error:(NSError **)outError
{
    VTablature *tablatureToLoad = [NSUnarchiver unarchiveObjectWithData:data];
    [self setTablature:tablatureToLoad];
        
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

@end
