//
//  VNote.m
//  tablution
//
//  Created by Ian Mccowan on 7/9/11.
//

#import "VNote.h"
#import "VChord.h"

@implementation VNote

@synthesize duration;
@synthesize stringNum;
@synthesize fret;

@synthesize attrs;

+ (VNote *)noteOnString:(NSUInteger)theString
                 atFret:(NSUInteger)theFret;
{
    return [[self alloc] initOnString:theString atFret:theFret];
}

- (VNote *)initOnString:(NSUInteger)theString
                 atFret:(NSUInteger)theFret;
{
    self = [super init];
    if (self) {
        fret = theFret;
        stringNum = theString;
        attrs = nil;
        return self;
    } else {
        return nil;
    }
}

- (VChord *)plusNoteOnString:(NSUInteger)stringNum
                      onFret:(NSUInteger)fretNum
{
    // stub
    return [[VChord alloc] initWithNote:[VNote noteOnString:1 atFret:1]];
}

@end
