//
//  JFSplitView.m
//  VMS
//
//  Created by mac_dev on 15/5/14.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "JFSplitView.h"


@interface JFSplitView()
@property (nonatomic,weak)NSView *selectedView;
@end

@implementation JFSplitView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    for (NSView *view in self.subviews) {
        if (view == [self.delegate1 selectedView]) {
            [[NSColor redColor] set];
            NSRectFill(NSInsetRect(view.frame, -2, -2));
            break;
        }
    }
}

//由于nsview不能将鼠标右键按照相应链传递下去，而是调用该方法，这里交给委托处理鼠标右键按下事件
- (NSMenu *)menuForEvent:(NSEvent *)event
{
    if ([self.delegate1 respondsToSelector:@selector(splitView:rightMouseDown:)]) {
        [self.delegate1 splitView:self rightMouseDown:event];
    }
    
    return [super menuForEvent:event];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
    if ([self.delegate1 respondsToSelector:@selector(splitView:keyDown:)]) {
        [self.delegate1 splitView:self keyDown:theEvent];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    if ([self.delegate1 respondsToSelector:@selector(splitView:mouseDown:)]) {
        [self.delegate1 splitView:self mouseDown:theEvent];
    }
}

@end