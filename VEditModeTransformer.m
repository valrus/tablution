//
//  VEditModeTransformer.m
//  tablution
//
//  Created by Ian Mccowan on 6/13/12.
//  Copyright (c) 2012 Nuance, Inc. All rights reserved.
//

#import "VEditModeTransformer.h"

@implementation VEditModeTransformer

+ (Class)transformedValueClass { return [NSString class]; }

+ (BOOL)allowsReverseTransformation { return YES; }

- (id)transformedValue:(id)value {
    return [value boolValue] ? @"Solo Mode" : @"Chord Mode";
}

- (id)reverseTransformedValue:(id)value {
    return [NSNumber numberWithBool:[value isEqualToString:@"Solo Mode"]];
}

@end
