#import "VTabView.h"
#import "VTabController.h"
#import "VTablature.h"


@interface VTabView (Private)

- (void)fretEntry:(NSString *)entryChar;
- (void)moveBaseFret:(NSString *)entryChar;

@end

@implementation VTabView

// setup stuff

- (void)setupEditDict {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"editChars"
                                                          ofType:@"plist"];
    editCharsDict = [[NSDictionary dictionaryWithContentsOfFile:plistPath] retain];
    if (!editCharsDict) {
        // make a dialog box or something for this
        NSLog(@"Edit chars dictionary not found!");
    }
}

- (void)setTablature:(VTablature *)newValue {
    if (myTablature != newValue) {
        if (myTablature) [myTablature release];
        
        myTablature = [newValue retain];
    }
}

// editing

- (void)fretEntry:(NSString *)entryChar
{
    NSDictionary *fretInfo = [editCharsDict objectForKey:entryChar];
    [myController addNoteOnString:[fretInfo objectForKey:@"stringNum"]
                           onFret:[fretInfo objectForKey:@"fretNum"]];
}

- (void)moveBaseFret:(NSString *)entryChar
{
    if ( [entryChar isEqualToString:@"+"] ) {
        [myController incrementBaseFret];
    } else {
        [myController decrementBaseFret];
    }
}

// changing text

- (void)replaceNote:(NSUInteger)whichNote
           onString:(NSUInteger)whichString
           withFret:(NSUInteger)whichFret
{
    int tabTextLength = [myTablature length] * 6 + 1;
    NSString *replaceString = [VTablature getNoteTextForValue:whichFret];
    NSRange textRange = NSMakeRange((tabTextLength + 1) * whichString +
                                    6 * whichNote, 5);
    NSString *stringForDelegate = replaceString;
    
    if ([myTablature fretAtLocation:whichNote  
                           onString:whichString] == whichFret)
        stringForDelegate = nil;
    
    NSLog(@"what the");
    if ([self shouldChangeTextInRange:textRange
                    replacementString:stringForDelegate])
    {
        NSLog(@"HARBL");
        // if a note is being replaced, we can assume it is selected.
        // Hence, use red text on a black background to indicate this.
        NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:
            NSForegroundColorAttributeName, [NSColor redColor],
            NSBackgroundColorAttributeName, [NSColor blackColor],
            NSFontAttributeName, [NSFont fontWithName:@"Monaco" size:12.0]];
        
        NSAttributedString *attrString = [[NSAttributedString alloc]
                                            initWithString:replaceString
                                                attributes:attrDict];
        [[self textStorage] replaceCharactersInRange:textRange
                                withAttributedString:attrString];
        NSLog(@"%@", [[self textStorage] string]);
        [self didChangeText];
        [self needsDisplay];
    }
}

// NSResponder overrides

- (BOOL)acceptsFirstResponder {
    return YES;    
}

- (void)keyDown:(NSEvent *)theEvent {
    NSCharacterSet *fretEntryChars =
        [NSCharacterSet characterSetWithCharactersInString:@"123456qwertyasdfghzxcvbn"];
    NSString *theKey = [theEvent charactersIgnoringModifiers];
    NSString *keyChar;
    unichar keyUnichar = 0;
    if ( [theKey length] == 1 ) {
        keyChar = [theKey substringToIndex:1];
        keyUnichar = [keyChar characterAtIndex:0];
        if ( [keyChar isEqualToString:@" "] ) {
            [myController advanceAndExtend:YES];
        } else if ( [fretEntryChars characterIsMember:keyUnichar] ) {
            // keys for adding fretted strings
            [self fretEntry:keyChar];
        } else if ( [[NSCharacterSet characterSetWithCharactersInString:@"-+"]
                        characterIsMember:keyUnichar] ) {
            // move base fret
            [self moveBaseFret:keyChar];
        } else if ( [theEvent modifierFlags] & NSNumericPadKeyMask ) {
            // handle arrow keys using input management system
            [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
        }
    } else {
        [super keyDown:theEvent];
    }
}

- (IBAction)moveRight:(id)sender
{
    [myController advanceAndExtend:NO];
}

- (IBAction)moveLeft:(id)sender
{
    [myController recede];
}

- (IBAction)moveUp:(id)sender
{
    [myController upString];
}

- (IBAction)moveDown:(id)sender
{
    [myController downString];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSLog(@"mouseUp");
    
    NSPoint clickPoint = [theEvent locationInWindow];
    NSLog([NSString stringWithFormat:@"window click x:%f, y:%f", clickPoint.x, clickPoint.y]);
    // Get the point where the mouse was clicked in the view
    // Change from window coordinates by sending nil as the fromView
    // NSPoint viewClickPoint = [self convertPoint:clickPoint
    //                                    fromView:nil];
    clickPoint = [[self window] convertBaseToScreen:clickPoint];
    NSLog([NSString stringWithFormat:@"view click x:%f, y:%f", clickPoint.x, clickPoint.y]);
    // Get the index in the text where the mouse was clicked
    NSUInteger clickIndex = [self characterIndexForPoint:clickPoint];
    [myController respondToClickAtIndex:clickIndex];
}
    
@end
