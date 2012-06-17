//
//  VTabDocument.h
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright valrusware 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VTablature;
@class VTabController;

@interface VTabDocument : NSDocument
{
	VTablature *tablature;
    NSNumber *baseFret;
    NSNumber *soloMode;
    IBOutlet VTabController *controller;
}

@property (strong) VTablature *tablature;
@property (strong) NSNumber *baseFret;
@property (strong) NSNumber *soloMode;

@end