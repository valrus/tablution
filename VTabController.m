//
//  VTabController.m
//  tablution
//
//  Created by The Valrus on 9/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VTabController.h"
#import "VTabDocument.h"

@implementation VTabController
    
- (void)setupEditDict
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"editChars"
                                                          ofType:@"plist"];
    editCharsDict = [[NSDictionary dictionaryWithContentsOfFile:plistPath] retain];
    if (!editCharsDict) {
        // make a dialog box or something for this
        NSLog(@"Edit chars dictionary not found!");
    }
}

- (void)setupTextAttrDicts
{
    NSMutableParagraphStyle *noLineBreakStyle =
		[[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [noLineBreakStyle setLineBreakMode:NSLineBreakByClipping];
		
	defaultTextAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
						noLineBreakStyle, NSParagraphStyleAttributeName,
						[NSFont fontWithName:@"Monaco" size:12.0], NSFontAttributeName,
						[NSColor blackColor], NSForegroundColorAttributeName,
						[NSColor whiteColor], NSBackgroundColorAttributeName, nil];
	selectedTextAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
						 noLineBreakStyle, NSParagraphStyleAttributeName,
						 [NSFont fontWithName:@"Monaco" size:12.0], NSFontAttributeName,
						 [NSColor whiteColor], NSForegroundColorAttributeName,
						 [NSColor blackColor], NSBackgroundColorAttributeName, nil];
	hiliteTextAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
					   noLineBreakStyle, NSParagraphStyleAttributeName,
					   [NSFont fontWithName:@"Monaco" size:12.0], NSFontAttributeName,
					   [NSColor redColor], NSForegroundColorAttributeName,
					   [NSColor blackColor], NSBackgroundColorAttributeName, nil];
}	
	
- (void)drawTablature
{
    VTablature *theTablature = [tabDoc tablature];
	NSString *tabString = [NSString stringWithString:[theTablature asText]];
    NSMutableAttributedString *tabDisplayString = [[NSMutableAttributedString alloc]
													initWithString:tabString];
    NSMutableParagraphStyle *noLineBreakStyle =
        [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [noLineBreakStyle setLineBreakMode:NSLineBreakByClipping];
    int tabTextLength = [tabString length] / [theTablature strings];
    int whichString;
    NSRange textRange;
    
    NSLog(@"tabString: %@", tabString);
	
	[tabDisplayString addAttributes:defaultTextAttrs
							  range:NSMakeRange(0, [tabDisplayString length])];
	for (whichString = 0; whichString < [theTablature strings]; whichString ++) {
        NSLog(@"%i", whichString);
        textRange = NSMakeRange((tabTextLength + 1) * whichString +
                                3 * [tabDoc cursorLocation],
                                3);
        if (whichString == [tabDoc cursorString]) {
            [tabDisplayString addAttributes:hiliteTextAttrs
									  range:textRange];
        } else {
            [tabDisplayString addAttributes:selectedTextAttrs
									  range:textRange];
        }
    }
    [[tabView textStorage] setAttributedString:tabDisplayString];
    [tabView setNeedsDisplay:YES];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
        
    [tabView setAlignment:NSLeftTextAlignment];
    [tabView setFont:[NSFont fontWithName:@"Monaco" size:12.0]];
    tabDoc = [self document];
    
    VTablature *newTablature = [[VTablature alloc] init];
    
    [tabDoc setTablature:newTablature];
    // NSLog(@"tabtext:");
    // NSLog([[tabDoc tablature] asText]);
	
	NSTextContainer *tabContainer = [tabView textContainer];
	NSScrollView *tabScroller = [tabView enclosingScrollView];
	
	// Code for horizontal scrolling adapted from:
	// http://lists.apple.com/archives/cocoa-dev/2005/May/msg01401.html
	[tabView setHorizontallyResizable:YES];
	[tabContainer setContainerSize:NSMakeSize(10000000,[tabContainer containerSize].height)];
	[tabView setMaxSize:NSMakeSize (10000000, [tabView maxSize].height)];
	[tabContainer setWidthTracksTextView:NO];
	[tabScroller setHasHorizontalScroller:YES];
    
    [self setupEditDict];
    [self setupTextAttrDicts];
    [self drawTablature];
}

@end

@implementation VTabController(NSTextViewDelegate)

- (BOOL)textView:(NSTextView *)aTextView
    shouldChangeTextInRange:(NSRange)affectedCharRange
          replacementString:(NSString *)replacementString
{
    // This method intercepts changes to text, since the input
    // procedures are totally overhauled in the tab view.
    if ( [editCharsDict objectForKey:replacementString] != nil )
    {
        NSDictionary *stuffToDo = [editCharsDict objectForKey:replacementString];
        SEL theSelector = NSSelectorFromString([stuffToDo objectForKey:@"aSelector"]);
        switch ( [stuffToDo count] )
        {
            case 1:
                [self performSelector:theSelector];
                break;
            case 2:
                [self performSelector:theSelector
                           withObject:[stuffToDo objectForKey:@"param1"]];
                break;
            case 3:
                [self performSelector:theSelector
                           withObject:[stuffToDo objectForKey:@"param1"]
                           withObject:[stuffToDo objectForKey:@"param2"]];
                break;
            default:
				// something's wonky in the editChars plist
                NSLog(@"FUCK BLARG ARGLBLGLGLBL");
                break;
        }
    } 
    return NO;
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    NSLog(@"text view received selector: %s", (char *)aSelector);
    return [self tryToPerform:aSelector with:aTextView];
}

- (void) respondToClickAtIndex:(NSUInteger)clickIndex
{
    [tabDoc changeSelectionToIndex:clickIndex];
    [self drawTablature];
}

// Editing selectors

- (void)addNoteOnString:(NSNumber *)whichString
                 onFret:(NSNumber *)whichFret
{
    NSUInteger stringNum = [whichString intValue];
    NSUInteger fretNum = [whichFret intValue] + [tabDoc baseFret];
    
    NSString *replaceString = [VTablature getNoteTextForValue:fretNum];
    NSRange textRange = [tabDoc textRangeForString:stringNum atLocation:[tabDoc cursorLocation]];
    
    [tabDoc addNoteOnString:whichString
                     onFret:whichFret];
    
    // Might need to change selection to location
	// where a note was just added.
    
    // NSLog(@"rar?");
    
	// NSLog(@"textRange start: %i, length: %i", textRange.location, textRange.length);
    [[tabView textStorage] replaceCharactersInRange:textRange
										 withString:replaceString];
}

- (void)incrementBaseFret
{
    [tabDoc incrementBaseFret];
    [currentFretField setStringValue:
        [@"Current Fret: " stringByAppendingString:
            [NSString stringWithFormat:@"%i", [tabDoc baseFret]]]];
}

- (void)decrementBaseFret
{
    [tabDoc decrementBaseFret];
    [currentFretField setStringValue:
        [@"Current Fret: " stringByAppendingString:
            [NSString stringWithFormat:@"%i", [tabDoc baseFret]]]];
}

- (void)advance
{
	if ( [tabDoc atEndOfTab] )
	{
		[tabDoc insertNoteBefore:[tabDoc tabLength]];
	}
	[self moveRight:nil];
}

// Editing: selectors from input manager or whatever
// TODO: change drawing to use replaceCharactersInRange:

- (IBAction)moveRight:(id)sender
{
    [tabDoc advanceCurrentLocation];
    [self drawTablature];
}

- (IBAction)moveLeft:(id)sender
{
    [tabDoc recedeCurrentLocation];
    [self drawTablature];
}

- (IBAction)moveUp:(id)sender
{
    [tabDoc upString];
    [self drawTablature];
}

- (IBAction)moveDown:(id)sender
{
    [tabDoc downString];
    [self drawTablature];
}

@end
