//
//  VTabDocument.m
//  tablution
//
//  Created by Ian McCowan on 9/30/08.
//  Copyright valrusware 2008. All rights reserved.
//

#import "VTabDocument.h"
#import "VTablature.h"
#import "VTabController.h"
#import "VTabView.h"
#import "VEditModeTransformer.h"
#import "HandyTools.h"

@implementation VTabDocument

@synthesize baseFret;
@synthesize tablature;
@synthesize soloMode;

// setup

- (id)init
{
    self = [super init];
    if (self) {
        NSValueTransformer *transformer = [[VEditModeTransformer alloc] init];
        [NSValueTransformer setValueTransformer:transformer forName:@"VEditModeTransformer"];
        if (tablature == nil) {
            tablature = [[VTablature alloc] initWithStrings:6];
            baseFret = [NSNumber numberWithInt:0];
            soloMode = [NSNumber numberWithBool:NO];
            [tablature addChordFromString:@"-1 -1 -1 -1 -1 -1"];
        }
        [controller setTablature:tablature];
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"TabDocument";
}

//-(NSDocument *)object prepareSavePanel:(NSSavePanel *)savePanel
//{
//
//}

// saving and loading

- (NSData *)dataOfType:(NSString *)typeName
                 error:(NSError **)outError
{
    NSData *data;
    NSString *tabText;

    NSLog(@"Saving doc of type: %@", typeName);
    if ([typeName  isEqual: @"com.valrusware.tablature"]) {
        tabText = [tablature toSerialString];
    }
    else if ([typeName  isEqual: @"public.plain-text"]) {
        tabText = [tablature toHumanReadableString];
    }
    
    if (!data) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}

    data = [tabText dataUsingEncoding:NSUTF8StringEncoding];
	return data;
}

- (BOOL)readFromData:(NSData *)data
              ofType:(NSString *)typeName
               error:(NSError **)outError
{
    NSString *tabText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    VTablature *tablatureToLoad = [VTablature tablatureFromText:tabText];
    [self setTablature:tablatureToLoad];
        
    if ( *outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
}

- (IBAction)copy:(id)sender
{
    NSArray *selectedChords = [tabView selectedChords];
    if (!IsEmpty(selectedChords)) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        VTablature *tabWithSelection = [VTablature tablatureWithChords:selectedChords];
        [pasteboard writeObjects:[NSArray arrayWithObject:tabWithSelection]];
    }
}

- (IBAction)paste:(id)sender
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[VTablature class]];
    NSDictionary *options = [NSDictionary dictionary];
    
    if ([pasteboard canReadObjectForClasses:classArray options:options]) {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        VTablature *tabToPaste = [objectsToPaste objectAtIndex:0];
        if ([tabView hasSelection]) {
            [controller replaceSelectedChordsWithChords:[tabToPaste chords]];
        }
        else {
            NSRange indexRange = NSMakeRange([tabView focusChordIndex], [tabToPaste countOfChords]);
            [controller insertAndSelectChords:[tabToPaste chords]
                                    atIndexes:[NSIndexSet indexSetWithIndexesInRange:indexRange]];
        }
    }
}

- (IBAction)cut:(id)sender
{
    [self copy:sender];
    [controller deleteSelectedChords];
}

@end
