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
    IBOutlet VTabController *controller;
}

@property (retain) VTablature *tablature;
@property (retain) NSNumber *baseFret;

@end