//
//  VTabDocument.m
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright valrusware 2008. All rights reserved.
//

#import "VTabDocument.h"
#import "VTablature.h"
#import "VTabController.h"
#import "Fraction.h"

@implementation VTabDocument

@synthesize baseFret;
@synthesize tablature;

// setup

- (id)init
{
    self = [super init];
    if (self) {
        
        if (tablature == nil) {
            tablature = [[VTablature alloc] initWithStrings:6];
            baseFret = 0;
        }
        [controller setTablature:tablature];
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"TabDocument";
}

// saving and loading

- (NSData *)dataOfType:(NSString *)typeName
                 error:(NSError **)outError
{
    NSData *data;
    
    data = [NSArchiver archivedDataWithRootObject:[self tablature]];
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return data;
}

- (BOOL)readFromData:(NSData *)data
              ofType:(NSString *)typeName
               error:(NSError **)outError
{
    VTablature *tablatureToLoad = [NSUnarchiver unarchiveObjectWithData:data];
    [self setTablature:tablatureToLoad];
        
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

@end
