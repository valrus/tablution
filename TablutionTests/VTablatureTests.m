//
//  VTablatureTests.m
//  tablution
//
//  Created by Ian Mccowan on 6/10/12.
//  Copyright (c) 2012 Nuance, Inc. All rights reserved.
//

#import "VTablatureTests.h"
#import "VTablature.h"

static NSString * const testTabString = @"0 2 2 1 0 0\n-1 -1 2 2 -1 -1\n-1 2 4 4 4 2";

@implementation VTablatureTests

- (void)setUp
{
    [super setUp];
    
    testTab = [VTablature tablatureWithString:testTabString];
}

// All code under test must be linked into the Unit Test bundle
- (void)testInit
{
    NSString *serialString = [testTab toSerialString];
    STAssertEqualObjects(serialString, testTabString,
                         @"Initialized tab does not serialize to same string. Instead it is %@", serialString);
}

@end
