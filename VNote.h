//
//  VNote.h
//  tablution
//
//  Created by Ian Mccowan on 7/9/11.
//

#import <Foundation/Foundation.h>

#define NO_FRET -1

@class VChord;

@interface VNote : NSObject
{
    NSInteger fret;
    NSDictionary *attrs;
}

@property (readwrite) NSInteger fret;
@property (strong) NSDictionary *attrs;

#pragma mark - Setup -
#pragma mark Constructors
+ (VNote *)noteAtFret:(NSInteger)theFret;
+ (VNote *)blankNote;

#pragma mark Initializers
- (VNote *)initAtFret:(NSInteger)theFret;

#pragma mark - Information -
#pragma mark Accessors
- (NSString *)stringValue;
- (NSString *)stringValueOrDash;

#pragma mark Other information
- (BOOL)isEqualToNote:(VNote *)otherNote;
- (BOOL)hasFret;

@end
