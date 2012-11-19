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
@class VTabView;

@interface VTabDocument : NSDocument
{
	VTablature *tablature;
    NSNumber *baseFret;
    NSNumber *soloMode;
    IBOutlet VTabController *controller;
    IBOutlet VTabView *tabView;
}

@property (strong) VTablature *tablature;
@property (strong) NSNumber *baseFret;
@property (strong) NSNumber *soloMode;

- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)cut:(id)sender;

@end