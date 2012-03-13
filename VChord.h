//
//  VChord.h
//  tablution
//
//  Created by Ian Mccowan on 7/9/11.
//

#import <Foundation/Foundation.h>
@class VNote;

@interface VChord : NSObject {
    NSMutableArray *notes;
    NSDictionary *attrs;
}

@property (readwrite, strong) NSMutableArray *notes;
@property (readwrite, strong) NSDictionary *attrs;

// construct
+ (VChord *)chordWithArray:(NSArray *)fretArray;
+ (VChord *)chordWithStrings:(NSUInteger)numStrings
                    withNote:(VNote *)note
                    onString:(NSUInteger)string;
+ (VChord *)chordWithStrings:(NSUInteger)numStrings
                    withFret:(NSInteger)fret
                    onString:(NSUInteger)string;

// init
- (VChord *)initWithArray:(NSArray *)fretArray;
- (VChord *)initWithStrings:(NSUInteger)numStrings
                   withNote:(VNote *)note
                   onString:(NSUInteger)string;
- (VChord *)initWithStrings:(NSUInteger)numStrings
                   withFret:(NSInteger)fret
                   onString:(NSUInteger)string;

// access
- (VNote *)noteOnString:(NSUInteger)stringNum;
- (NSInteger)fretOnString:(NSUInteger)stringNum;
- (NSString *)asText;

// alter
- (void)addNote:(VNote *)note
       onString:(NSUInteger)stringNum;
- (void)addFret:(NSInteger)fret
       onString:(NSUInteger)stringNum;

// NSFastEnumeration protocol
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len;

@end
