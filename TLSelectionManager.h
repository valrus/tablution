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


enum {
	TLSelectionManagerModelAddition = 0,
	TLSelectionManagerModelFixedPoint
};
typedef NSUInteger TLSelectionManagerModel;

@interface TLSelectionManager : NSObject {
@private
	id __unsafe_unretained delegate;
	
	NSSet* selectedItems;
	
	TLSelectionManagerModel continuousSelectionModel;
	NSSet* anchorItems;
	NSSet* previousHitItems;
	
	NSUInteger dragMode;
	NSSet* selectionBeforeDrag;
	NSEvent* mouseDownEvent;
	NSSet* deferredDeselection;
}

@property (nonatomic, unsafe_unretained) id delegate;

@property (nonatomic, assign) TLSelectionManagerModel continuousSelectionModel;

@property (nonatomic, copy) NSSet* selectedItems;
- (void)selectItems:(NSSet*)items byExtendingSelection:(BOOL)shouldExtend;

- (void)mouseDown:(NSEvent*)mouseEvent userInfo:(void*)userInfo;
- (void)mouseDragged:(NSEvent*)mouseEvent userInfo:(void*)userInfo;
- (void)mouseUp:(NSEvent*)mouseEvent;

@end


@interface NSObject (TLSelectionManagerDelegate)

- (void)selectionManagerDidChangeSelection:(TLSelectionManager*)manager;

- (BOOL)selectionManagerShouldSelectMultipleItems:(TLSelectionManager*)manager
										withEvent:(NSEvent*)mouseDownEvent
										 userInfo:(void*)userInfo;

// may return nil
- (id)selectionManager:(TLSelectionManager*)manager
		itemUnderPoint:(NSPoint)windowPoint
			  userInfo:(void*)userInfo;

// may return nil or an empty set
- (NSSet*)selectionManager:(TLSelectionManager*)manager
		allItemsUnderPoint:(NSPoint)windowPoint
				  userInfo:(void*)userInfo;


- (NSSet*)selectionManager:(TLSelectionManager*)manager
		 itemsBetweenItems:(NSSet*)items1
				  andItems:(NSSet*)items2
				  userInfo:(void*)userInfo;


- (NSSet*)selectionManager:(TLSelectionManager*)manager
				itemsInBox:(NSRect)windowRect
				  userInfo:(void*)userInfo;


- (BOOL)selectionManagerShouldInitiateDragLater:(TLSelectionManager*)manager
									  dragEvent:(NSEvent*)dragEvent
								  originalEvent:(NSEvent*)mouseDownEvent
									   userInfo:(void*)userInfo;

@end
