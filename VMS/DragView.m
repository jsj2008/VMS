//
//  DropView.m
//  VMS
//
//  Created by mac_dev on 15/9/17.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "DragView.h"
@interface DragView() {
    BOOL _beginDrag;
}

@end
@implementation DragView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}

#pragma mark - dragging destination protocol
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    id<DragViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dragView:validateDrop:)])
        return [delegate dragView:self validateDrop:sender];
    
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    id<DragViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dragView:validateDrop:)])
        return [delegate dragView:self validateDrop:sender];
    
    return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    return YES;
}

#pragma mark - dragging souce protocol
- (NSDragOperation)draggingSession:(NSDraggingSession *)session
sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    switch(context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationNone;
            
        case NSDraggingContextWithinApplication:
            return NSDragOperationCopy;
    }
}

- (void)draggingSession:(NSDraggingSession *)session
       willBeginAtPoint:(NSPoint)screenPoint
{
    //交给委托去做
    id<DragViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dragView:draggingSession:willBeginAtPoint:)])
        [delegate dragView:self draggingSession:session willBeginAtPoint:screenPoint];
    
}

- (void)draggingSession :(NSDraggingSession *)session
           endedAtPoint :(NSPoint)screenPoint
              operation :(NSDragOperation)operation
{
    //交给委托去做
    id<DragViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dragView:draggingSession:endedAtPoint:operation:)])
        [delegate dragView:self draggingSession:session endedAtPoint:screenPoint operation:operation];
}


#pragma mark - mouse events
- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    _beginDrag = YES;
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    _beginDrag = NO;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    id<DragViewDelegate> delegate = self.delegate;
    NSArray *draggingItems = nil;
   
    if ([delegate respondsToSelector:@selector(dragView:draggingItemsAtPoint:)]) {
        NSPoint ptInWindow = [theEvent locationInWindow];
        NSRect rcInWindow = NSMakeRect(ptInWindow.x, ptInWindow.y, 0, 0);
        NSRect rcInScreen = [theEvent.window convertRectToScreen:rcInWindow];
        NSPoint ptInScreen = rcInScreen.origin;
        draggingItems = [delegate dragView:self draggingItemsAtPoint:ptInScreen];
    }
    
    if (_beginDrag && draggingItems) {
        [self beginDraggingSessionWithItems:draggingItems event:theEvent source:self];
        _beginDrag = NO;
    }
    [super mouseDragged:theEvent];
}
@end
