//
//  VNote.h
//  tablution
//
//  Created by Ian Mccowan on 7/9/11.
//

#import <Foundation/Foundation.h>
@class Fraction;
@class VChord;

@interface VNote : NSObject {
    Fraction *duration;
    NSUInteger stringNum;
    NSUInteger fret;
    
    NSDictionary *attrs;
}

@property (retain) Fraction *duration;
@property (readwrite) NSUInteger stringNum;
@property (readwrite) NSUInteger fret;

@property (retain) NSDictionary *attrs;

+ (VNote *)noteOnString:(NSUInteger)theString
                 atFret:(NSUInteger)theFret;

- (VNote *)initOnString:(NSUInteger)theString
                 atFret:(NSUInteger)theFret;

- (VChord *)plusNoteOnString:(NSUInteger)stringNum
                      onFret:(NSUInteger)fretNum;

@end
