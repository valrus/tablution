#import <Cocoa/Cocoa.h>

@class VTabController;
@class VTablature;

@interface VTabView : NSTextView
{
    // dictionary to store characters for entering tab
    NSDictionary    *editCharsDict;
    IBOutlet VTabController  *myController;
    VTablature *myTablature;
}

- (void)setupEditDict;
- (void)setTablature:(VTablature *)newValue;

- (void)replaceNote:(NSUInteger)whichNote
           onString:(NSUInteger)whichString
           withFret:(NSUInteger)whichFret;
@end
