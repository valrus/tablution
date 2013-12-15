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

#pragma mark - Setup -
#pragma mark Constructors

+ (VNote *)noteAtFret:(NSInteger)theFret;
{
    return [[self alloc] initAtFret:theFret];
}

+ (VNote *)blankNote
{
    return [[self alloc] initAtFret:NO_FRET];
}

#pragma mark Initializers

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

#pragma mark - Information -
#pragma mark Accessors

- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"%li", fret];
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

#pragma mark Other information

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
