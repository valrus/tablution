//
//  NSIndexSet+SetOperations.h
//  tablution
//
//  Created by Ian Mccowan on 6/24/12.
//  Copyright (c) 2012 Nuance, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (SetOperations)
{}

- (NSMutableIndexSet *)indexSetByAddingIndexes:(NSIndexSet *)indexes;
- (NSMutableIndexSet *)indexSetByRemovingIndexes:(NSIndexSet *)indexes;

- (BOOL)intersectsIndexes:(NSIndexSet *)otherIndexes;

@end
