//
//  VNote.m
//  tablution
//
//  Created by Ian Mccowan on 7/9/11.
//

#import "VNote.h"
#import "VChord.h"

@implementation VNote

@synthesize fret;
@synthesize attrs;

+ (VNote *)noteAtFret:(NSInteger)theFret;
{
    return [[self alloc] initAtFret:theFret];
}

+ (VNote *)blankNote
{
    return [[self alloc] initAtFret:NO_FRET];
}

- (VNote *)initAtFret:(NSInteger)theFret;
{
    self = [super init];
    if (self) {
        fret = theFret;
        attrs = nil;
        return self;
    } else {
        return nil;
    }
}

- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"%i", fret];
}

- (NSString *)stringValueOrDash
{
    if (fret == NO_FRET) {
        return @"-";
    }
    else {
        return [self stringValue];
    }
}

- (BOOL)isEqualToNote:(VNote *)otherNote
{
    if ([self fret] != [otherNote fret]) {
        return NO;
    }
    if (([self attrs] != nil && [otherNote attrs] != nil) &&
        ![[self attrs] isEqualToDictionary:[otherNote attrs]]) {
        return NO;
    }
    return YES;
}

- (BOOL)hasFret
{
    return (fret != NO_FRET);
}

@end
