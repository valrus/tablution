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

#import "TLSelectionManager.h"
#import "NSIndexSet+SetOperations.h"

#define TLBooleanCast !!
static inline CGFloat TLPointDistance(NSPoint a, NSPoint b);


static const NSUInteger TLSMContinuousSelectionMask = NSShiftKeyMask;
static const NSUInteger TLSMDiscontinuousSelectionMask = NSCommandKeyMask;
static const NSUInteger TLSMClickMultipleIndexesMask = NSAlternateKeyMask;


@interface TLSelectionManager ()
- (void)deselectIndexes:(NSIndexSet*)unwantedIndexes;
@property (nonatomic, strong) NSEvent* mouseDownEvent;
@property (nonatomic, copy) NSIndexSet* deferredDeselection;
@property (nonatomic, copy) NSIndexSet* anchorIndexes;
@property (nonatomic, copy) NSIndexSet* previousHitIndexes;
@property (nonatomic, copy) NSIndexSet* selectionBeforeDrag;
- (CGFloat)dragThreshold;
- (BOOL)shouldResetExistingSelection;
@end


enum {
	TLSMDragModeIgnore = 0,
	TLSMDragModeAttemptDrag,
	TLSMDragModeFlipSelection,
	TLSMDragModeExtendSelection
};
typedef NSUInteger TLSMDragMode;


@implementation TLSelectionManager

#pragma mark Lifecycle

- (id)init {
	self = [super init];
	if (self) {
		// ...
	}
	return self;
}



#pragma mark Basic accessors

@synthesize delegate;
@synthesize continuousSelectionModel;
@synthesize selectedIndexes;
@synthesize mouseDownEvent;
@synthesize deferredDeselection;
@synthesize anchorIndexes;
@synthesize previousHitIndexes;
@synthesize selectionBeforeDrag;

- (void)setSelectedIndexes:(NSIndexSet*)newSelectedIndexes {
	if ((!selectedIndexes && !newSelectedIndexes) ||
        ([selectedIndexes isEqualToIndexSet:newSelectedIndexes])) {
        return;
    }
	selectedIndexes = [newSelectedIndexes copy];
	if ([[self delegate] respondsToSelector:@selector(selectionManagerDidChangeSelection:)]) {
		[[self delegate] selectionManagerDidChangeSelection:self];
	}
}

- (void)selectIndexes:(NSIndexSet*)indexes byExtendingSelection:(BOOL)shouldExtend {
	if (shouldExtend && [self selectedIndexes]) {
		[self setSelectedIndexes:[[self selectedIndexes] indexSetByAddingIndexes:indexes]];
	}
	else {
		[self setSelectedIndexes:indexes];
	}
}

- (void)deselectIndexes:(NSIndexSet*)unwantedIndexes {
	NSIndexSet* previousSelection = [self selectedIndexes];
	if (!previousSelection) return;
	NSMutableIndexSet* newSelection = [previousSelection indexSetByRemovingIndexes:unwantedIndexes];
	[self setSelectedIndexes:newSelection];
}

- (CGFloat)dragThreshold {
	/* NOTE: drag must move at least 3 pixels before initiated according to
	 http://developer.apple.com/documentation/UserExperience/Conceptual/AppleHIGuidelines/XHIGDragDrop/chapter_13_section_5.html */
	return 3.0f;
}

- (BOOL)shouldResetExistingSelection {
	return YES;
}


#pragma mark Mouse handling

- (NSIndexSet*)continuousSelectionBasedOnHitIndexes:(NSIndexSet*)hitIndexes userInfo:(void*)userInfo {
	/*
	 Continous selection seems to be the least consistently implemented selection method amongst all of AppKit's views.
	 There are two basic models: "fixed-point" and "addition". Fixed-point anchors the selection at the last "normally"
	 selected indexes and all continuous selection is between those indexes and the new indexes. Addition either "adds on" or
	 it "chops off" (as little as possible).
	 
	 (See http://developer.apple.com/documentation/UserExperience/Conceptual/AppleHIGuidelines/XHIGUserInput/chapter_12_section_4.html
	 #//apple_ref/doc/uid/TP30000361-TPXREF24 as well as http://daringfireball.net/2006/08/highly_selective for other discussion.)
	 
	 As far as implementation, there are three pertinent index sets:
	 - anchorIndexes
	 - previousHitIndexes
	 - hitIndexes (i.e. the current ones)
	 
	 The current hitIndexes should be always be recorded in previousHitIndexes. In any non-continous selection,
	 the anchorIndexes are set to nil which signals they are the same as previousHitIndexes. 
	 
	 If in "fixed-point" mode, the anchorIndexes are not updated except when nil.
	 If in "addition" mode, the current anchorIndexes and previousHitIndexes compete. Whichever yields the largest
	 selection vis-a-vis the current hitIndexes gets set as the anchorIndexes. Then in either continuous selection mode,
	 the new selection includes the hitIndexes, the achorIndexes and everything in between.
	 */
	
	// check to make sure we have enough information
	NSAssert([delegate respondsToSelector:@selector(selectionManager:indexesBetweenIndexes:andIndexes:userInfo:)],
			 @"Caller must verify continuous selection delegate support");
	BOOL anchorAndPreviousSame = NO;
	if (![[self previousHitIndexes] count]) {
		NSAssert(![self anchorIndexes], @"Selection anchor indexes left in unkempt state");
		return hitIndexes;
	}
	if (![[self anchorIndexes] count]) {
		[self setAnchorIndexes:[self previousHitIndexes]];
		anchorAndPreviousSame = YES;
	}
	
	NSIndexSet* indexesBetween = nil;
	if (anchorAndPreviousSame || [self continuousSelectionModel] == TLSelectionManagerModelFixedPoint) {
		indexesBetween = [delegate selectionManager:self
								indexesBetweenIndexes:[self anchorIndexes]
										 andIndexes:hitIndexes
										 userInfo:userInfo];
	}
	else {	// assume ([self continuousSelectionModel] == TLSelectionManagerModelAddition)
		NSIndexSet* anchorResult = [delegate selectionManager:self
									   indexesBetweenIndexes:[self anchorIndexes]
												andIndexes:hitIndexes
												userInfo:userInfo];
		NSIndexSet* previousResult = [delegate selectionManager:self
										 indexesBetweenIndexes:[self previousHitIndexes]
												  andIndexes:hitIndexes
												  userInfo:userInfo];
		if ([previousResult count] > [anchorResult count]) {
			[self setAnchorIndexes:[self previousHitIndexes]];
			indexesBetween = previousResult;
		}
		else {
			indexesBetween = anchorResult;
		}
	}
	
	NSMutableIndexSet* allIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:indexesBetween];
	[allIndexes addIndexes:hitIndexes];
	[allIndexes addIndexes:[self anchorIndexes]];
	return allIndexes;
}

- (void)mouseDown:(NSEvent*)mouseEvent userInfo:(void*)userInfo {
	[self setMouseDownEvent:mouseEvent];
	
	// see if multiple indexes should be requested from delegate
	BOOL attemptMultiple = TLBooleanCast([mouseEvent modifierFlags] & TLSMClickMultipleIndexesMask);
	if ([delegate respondsToSelector:@selector(selectionManagerShouldSelectMultipleIndexes:withEvent:userInfo:)]) {
		attemptMultiple = [delegate selectionManagerShouldSelectMultipleIndexes:self withEvent:mouseEvent userInfo:userInfo];
	}
	
	// get hit index(s)
	NSIndexSet* hitIndexes = nil;
	NSPoint windowPoint = [mouseEvent locationInWindow];
	if (attemptMultiple && [delegate respondsToSelector:@selector(selectionManager:allIndexesUnderPoint:userInfo:)]) {
		hitIndexes = [delegate selectionManager:self indexesUnderPoint:windowPoint userInfo:userInfo];
	}
	else if ([delegate respondsToSelector:@selector(selectionManager:indexUnderPoint:userInfo:)]) {
		NSInteger hitIndex = [delegate selectionManager:self indexUnderPoint:windowPoint userInfo:userInfo];
		if (hitIndex != NO_HIT) {
            hitIndexes = [NSIndexSet indexSetWithIndex:hitIndex];
        }
	}
	
	BOOL isContinuousSelection = TLBooleanCast([mouseEvent modifierFlags] & TLSMContinuousSelectionMask);
	BOOL isDiscontinuousSelection = TLBooleanCast([mouseEvent modifierFlags] & TLSMDiscontinuousSelectionMask);
	if (isDiscontinuousSelection) {
		// discontinuous overrides continuous
		isContinuousSelection = NO;
	}
	if (isContinuousSelection && ![delegate respondsToSelector:@selector(selectionManager:indexesBetweenIndexes:andIndexes:userInfo:)]) {
		// treat as discontinuous if delegate doesn't provide support for continuous selection
		isContinuousSelection = NO;
		isDiscontinuousSelection = YES;
	}
	
	/* We never completely clear selection if an "extend selection" modifier is held.
	 This is not how table views do it, but it is how column views work.
	 Outline views never seem to clear their selection. */
	BOOL keepSelection = TLBooleanCast(isDiscontinuousSelection || isContinuousSelection);
    BOOL indexesWereAlreadySelected = [[self selectedIndexes] intersectsIndexes:hitIndexes];

	if ([hitIndexes count]) {
		/* Unless a brand new selection is being started, we deselect on mouse *up*.
		 Unlike column views, outline and table views don't defer deselection, but that seems broken. */
		if (indexesWereAlreadySelected) {
			if (isContinuousSelection) {
				NSIndexSet* resultingSelection = [self continuousSelectionBasedOnHitIndexes:hitIndexes userInfo:userInfo];
				NSIndexSet* unselectedIndexes = [[self selectedIndexes] indexSetByRemovingIndexes:resultingSelection];
				[self setDeferredDeselection:unselectedIndexes];
			}
			if (isDiscontinuousSelection) {
				[self setDeferredDeselection:hitIndexes];
			}
			else {
				if ([self shouldResetExistingSelection]) {
					NSIndexSet* missedIndexes = [[self selectedIndexes] indexSetByRemovingIndexes:hitIndexes];
					[self setDeferredDeselection:missedIndexes];
				}
			}
		}
		else {
			if (isContinuousSelection) {
				NSIndexSet* resultingSelection = [self continuousSelectionBasedOnHitIndexes:hitIndexes userInfo:userInfo];
				[self selectIndexes:resultingSelection byExtendingSelection:NO];
			}
			else if (isDiscontinuousSelection) {
				[self selectIndexes:hitIndexes byExtendingSelection:YES];
			}
			else {
				[self selectIndexes:hitIndexes byExtendingSelection:NO];
			}
		}
		dragMode = TLSMDragModeAttemptDrag;
		[self setPreviousHitIndexes:hitIndexes];
		if (!isContinuousSelection) [self setAnchorIndexes:nil];
	}
    else if (!keepSelection) {
        [self setSelectedIndexes:nil];
        [self setPreviousHitIndexes:nil];
        [self setAnchorIndexes:nil];
    }
	if (!indexesWereAlreadySelected) {
		if ([mouseEvent modifierFlags] & NSCommandKeyMask) {
			dragMode = TLSMDragModeFlipSelection;
		}
		else {
			dragMode = TLSMDragModeExtendSelection;
		}
	}
}

- (void)mouseDraggedIndexes:(NSEvent*)dragEvent userInfo:(void*)userInfo {
	NSEvent* downEvent = [self mouseDownEvent];
	
	if (![[self selectedIndexes] count]) return;
	
	CGFloat dragDistance = TLPointDistance([dragEvent locationInWindow], [downEvent locationInWindow]);
	if (dragDistance < [self dragThreshold]) return;
	
	// NOTE: must initiate only once, otherwise a drag cancelled via escape will be restarted
	BOOL initiateLater = NO;
	if ([[self delegate] respondsToSelector:@selector(selectionManagerShouldInitiateDragLater:dragEvent:originalEvent:userInfo:)]) {
		initiateLater = [[self delegate] selectionManagerShouldInitiateDragLater:self
																	   dragEvent:dragEvent
																   originalEvent:downEvent
																		userInfo:userInfo];
	}
	
	if (!initiateLater) {
		// signals that a drag is "done"
		dragMode = TLSMDragModeIgnore;
	}
}

- (void)mouseDraggedSelection:(NSEvent*)dragEvent userInfo:(void*)userInfo {
	(void)userInfo;
	
	NSIndexSet* originalSelection = [self selectionBeforeDrag];
	if (!originalSelection) {
		// remember original selection at beginning of drag
		originalSelection = [self selectedIndexes] ? [self selectedIndexes] : [NSIndexSet indexSet];
		[self setSelectionBeforeDrag:originalSelection];
	}
	
	NSPoint point1 = [[self mouseDownEvent] locationInWindow];
	NSPoint point2 = [dragEvent locationInWindow];
	NSRect selectionBox = NSMakeRect((CGFloat)fmin(point1.x, point2.x),
									 (CGFloat)fmin(point1.y, point2.y),
									 (CGFloat)fabs(point2.x - point1.x),
									 (CGFloat)fabs(point2.y - point1.y));
	
	NSIndexSet* indexesInBox = nil;
	if ([[self delegate] respondsToSelector:@selector(selectionManager:indexesInBox:userInfo:)]) {
		indexesInBox = [[self delegate] selectionManager:self indexesInBox:selectionBox userInfo:userInfo];
	}
	else {
		indexesInBox = [NSIndexSet indexSet];
	}
	
	NSMutableIndexSet* newSelection = nil;
	if (dragMode == TLSMDragModeFlipSelection) {
		NSIndexSet* addedIndexes = [indexesInBox indexSetByRemovingIndexes:originalSelection];
		newSelection = [originalSelection indexSetByRemovingIndexes:indexesInBox];
		[newSelection addIndexes:addedIndexes];
	}
	else if	(dragMode == TLSMDragModeExtendSelection) {
		newSelection = [originalSelection indexSetByAddingIndexes:indexesInBox];
	}
	NSAssert1(newSelection, @"Bad drag mode (%lu)", (long unsigned)dragMode);
	[self setSelectedIndexes:newSelection];
}

- (void)mouseDragged:(NSEvent*)dragEvent userInfo:(void*)userInfo {
	if (!dragMode) return;
	NSAssert([self mouseDownEvent], @"No mouse down event stored for drag");
	
	if (dragMode == TLSMDragModeAttemptDrag) {
		[self mouseDraggedIndexes:dragEvent userInfo:userInfo];
	}
	else {
		[self mouseDraggedSelection:dragEvent userInfo:userInfo];
	}
}

- (void)mouseUp:(NSEvent*)mouseEvent {
	(void)mouseEvent;
	
	if ([self mouseDownEvent]) {
		[self deselectIndexes:[self deferredDeselection]];
		[self setDeferredDeselection:nil];
		[self setMouseDownEvent:nil];
		[self setSelectionBeforeDrag:nil];
	}
}

@end

CGFloat TLPointDistance(NSPoint a, NSPoint b) {
	return (CGFloat)hypot(a.x - b.x, a.y - b.y);
}
