//
//  VTabDocument.h
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VTablature;
@class VTabController;

@interface VTabDocument : NSDocument
{
	VTablature *tablature;
    NSUInteger baseFret;
    IBOutlet VTabController *controller;
}

@property (retain) VTablature *tablature;
@property (readwrite) NSUInteger baseFret;

@end