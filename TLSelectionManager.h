/*
 // Copyright (c) 2008-2009 Calf Trail Software, LLC
 // 
 // Permission is hereby granted, free of charge, to any person
 // obtaining a copy of this software and associated documentation
 // files (the "Software"), to deal in the Software without
 // restriction, including without limitation the rights to use,
 // copy, modify, merge, publish, distribute, sublicense, and/or sell
 // copies of the Software, and to permit persons to whom the
 // Software is furnished to do so, subject to the following
 // conditions:
 // 
 // The above copyright notice and this permission notice shall be
 // included in all copies or substantial portions of the Software.
 // 
 // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 // EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 // OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 // NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 // HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 // WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 // FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 // OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Cocoa/Cocoa.h>

#define NO_HIT -1

enum {
	TLSelectionManagerModelAddition = 0,
	TLSelectionManagerModelFixedPoint
};
typedef NSUInteger TLSelectionManagerModel;

@interface TLSelectionManager : NSObject {
@private
	id __unsafe_unretained delegate;
	
	NSIndexSet* selectedIndexes;
	
	TLSelectionManagerModel continuousSelectionModel;
	NSIndexSet* anchorIndexes;
	NSIndexSet* previousHitIndexes;
	
	NSUInteger dragMode;
	NSIndexSet* selectionBeforeDrag;
	NSEvent* mouseDownEvent;
	NSIndexSet* deferredDeselection;
}

@property (nonatomic, unsafe_unretained) id delegate;

@property (nonatomic, assign) TLSelectionManagerModel continuousSelectionModel;

@property (nonatomic, copy) NSIndexSet* selectedIndexes;
- (void)selectIndexes:(NSIndexSet*)indexes byExtendingSelection:(BOOL)shouldExtend;

- (void)mouseDown:(NSEvent*)mouseEvent userInfo:(void*)userInfo;
- (void)mouseDragged:(NSEvent*)mouseEvent userInfo:(void*)userInfo;
- (void)mouseUp:(NSEvent*)mouseEvent;

@end


@interface NSObject (TLSelectionManagerDelegate)

- (void)selectionManagerDidChangeSelection:(TLSelectionManager*)manager;

- (BOOL)selectionManagerShouldSelectMultipleIndexes:(TLSelectionManager*)manager
										withEvent:(NSEvent*)mouseDownEvent
										 userInfo:(void*)userInfo;

// may return nil
- (NSInteger)selectionManager:(TLSelectionManager*)manager
              indexUnderPoint:(NSPoint)windowPoint
                     userInfo:(void*)userInfo;

// may return nil or an empty set
- (NSIndexSet*)selectionManager:(TLSelectionManager*)manager
              indexesUnderPoint:(NSPoint)windowPoint
                       userInfo:(void*)userInfo;


- (NSIndexSet*)selectionManager:(TLSelectionManager*)manager
          indexesBetweenIndexes:(NSIndexSet*)indexes1
                     andIndexes:(NSIndexSet*)indexes2
                       userInfo:(void*)userInfo;


- (NSIndexSet*)selectionManager:(TLSelectionManager*)manager
                   indexesInBox:(NSRect)windowRect
                       userInfo:(void*)userInfo;


- (BOOL)selectionManagerShouldInitiateDragLater:(TLSelectionManager*)manager
									  dragEvent:(NSEvent*)dragEvent
								  originalEvent:(NSEvent*)mouseDownEvent
									   userInfo:(void*)userInfo;

@end
