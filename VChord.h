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

@property (readwrite, retain) NSMutableArray *notes;
@property (readwrite, retain) NSDictionary *attrs;

// init
- (VChord *)initWithArray:(NSArray *)fretArray;
- (VChord *)initWithNote:(VNote *)note;

// access
- (VNote *)noteOnString:(NSUInteger)stringNum;
- (NSUInteger)fretOnString:(NSUInteger)stringNum;

// alter
- (void)addNote:(VNote *)note;
- (void)addFret:(NSUInteger)fret
       onString:(NSUInteger)stringNum;

@end
