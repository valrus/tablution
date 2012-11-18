//
//  NSIndexSet+SetOperations.m
//  tablution
//
//  Created by Ian Mccowan on 6/24/12.
//  Copyright (c) 2012 Nuance, Inc. All rights reserved.
//

#import "NSIndexSet+SetOperations.h"

@implementation NSIndexSet (SetOperations)

- (NSMutableIndexSet *)indexSetByAddingIndexes:(NSIndexSet *)indexes
{
    NSMutableIndexSet *newIndexSet = [[NSMutableIndexSet alloc] initWithIndexSet:self];
    [newIndexSet addIndexes:indexes];
    return newIndexSet;
}

- (NSMutableIndexSet *)indexSetByRemovingIndexes:(NSIndexSet *)indexes
{
    NSMutableIndexSet *newIndexSet = [[NSMutableIndexSet alloc] initWithIndexSet:self];
    [newIndexSet removeIndexes:indexes];
    return newIndexSet;    
}

- (BOOL)intersectsIndexes:(NSIndexSet *)otherIndexes
{
    // Could maybe make more efficient using technique described here:
    // http://www.cocoabuilder.com/archive/cocoa/82348-nsindexset.html
    NSUInteger intersectIndex = [self indexPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        if ([otherIndexes containsIndex:idx]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    if (intersectIndex == NSNotFound) {
        return NO;
    }
    return YES;
}

- (NSArray *)contiguousRanges
{
    __block NSMutableArray *rangeArray = [NSArray array];
    if ([self count] == 0) {
        return rangeArray;
    }
    
    __block NSUInteger lastIndex = 0;
    __block NSUInteger currentStart = 0;
    __block BOOL first = YES;
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (first) {
            currentStart = idx;
        }
        else if (idx != lastIndex + 1) {
            [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(currentStart, lastIndex - currentStart)]];
            first = YES;
        }
        lastIndex = idx;
    }];
    [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(currentStart, lastIndex - currentStart)]];
    return rangeArray;
}

@end
