//
//  VNote.h
//  tablution
//
//  Created by Ian Mccowan on 7/9/11.
//

#import <Foundation/Foundation.h>

#define NO_FRET -1

@class VChord;

@interface VNote : NSObject {
    NSInteger fret;
    NSDictionary *attrs;
}

@property (readwrite) NSInteger fret;
@property (strong) NSDictionary *attrs;

+ (VNote *)noteAtFret:(NSInteger)theFret;
+ (VNote *)blankNote;

- (VNote *)initAtFret:(NSInteger)theFret;

- (NSString *)stringValue;
- (NSString *)stringValueOrDash;

- (BOOL)hasFret;

// - (VChord *)plusNoteOnString:(NSUInteger)stringNum
//                       atFret:(NSInteger)fretNum;

@end
