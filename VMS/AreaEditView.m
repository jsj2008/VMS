//
//  AreaEditView.m
//  VMS
//
//  Created by mac_dev on 15/10/9.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "AreaEditView.h"

@interface AreaEditView()

@property (assign) NSPoint anchor;
@property (assign) NSPoint drag;
@property (assign,getter = isDragging) BOOL dragging;
@end

@implementation AreaEditView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    NSRect bounds = self.bounds;
    NSSize size = bounds.size;
    //首先对每个小区域描边
    double rowStep = size.height / ROWS;
    double colStep = size.width / COLS;
    NSColor *coverColor = [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.3];
    NSColor *clearColor = [NSColor clearColor];
    NSColor *blue = [NSColor blueColor];
    NSColor *yellow = [NSColor yellowColor];
    
    
    if ([self.delegate respondsToSelector:@selector(editView:shouldCoverAtRow:column:)]) {
        for (int row = 0; row < ROWS; row++) {
            for (int col = 0; col < COLS; col++) {
                //针对制定的行列进行描边
                NSRect rc;
                rc.origin.x = col * colStep;
                rc.origin.y = row * rowStep;
                rc.size.width = colStep;
                rc.size.height = rowStep;
                //描边
                [blue set];
                NSFrameRect(rc);
                //填充
                if ([self.delegate editView:self shouldCoverAtRow:row column:col])
                    [coverColor set];
                else
                    [clearColor set];
                
                NSRectFill(NSInsetRect(rc, 1, 1));
            }
        }
    }
    
    //对外轮廓进行描边
    [yellow set];
    NSFrameRect(bounds);
    
    //绘制拖拽矩形
    if (self.isDragging) {
        CGFloat width = fabs(self.drag.x - self.anchor.x);
        CGFloat height = fabs(self.drag.y - self.anchor.y);
        CGFloat x = fmin(self.drag.x, self.anchor.x);
        CGFloat y = fmin(self.drag.y, self.anchor.y);
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(x, y, width, height)];
        
        [[NSColor blueColor] set];
        [path stroke];
        [coverColor set];
        [path fill];
    }
}

- (BOOL)isFlipped
{
    return YES;
}

#pragma mark - private method
- (NSPoint)matrixFromLocation :(NSPoint)location
{
    NSSize size = self.bounds.size;
    NSPoint matrix = NSZeroPoint;
    //获取行
    CGFloat y = location.y;
    CGFloat yStep = size.height / ROWS;
    matrix.y = (int)(y / yStep);
    
    //获取列
    CGFloat x = location.x;
    CGFloat xStep = size.width / COLS;
    matrix.x = (int)(x / xStep);
    
    return matrix;
}

#pragma mark - event
- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    NSPoint locationInWnd = theEvent.locationInWindow;
    NSPoint locationInView = [self convertPoint:locationInWnd fromView:nil];
    
    //记录锚点,记录拖拽点
    self.anchor = locationInView;
    self.drag = locationInView;
    self.dragging = YES;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    
    NSPoint locationInWindow = theEvent.locationInWindow;
    NSPoint locationInView = [self convertPoint :locationInWindow fromView :nil];
    
    //更新拖拽点
    [self setDrag:locationInView];
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];

    self.dragging = NO;
    
    //通知取反
    if ([self.delegate respondsToSelector:@selector(alterCoverFromRowStart:colStart:toRowEnd:colEnd:editView:)]) {
        NSPoint anchor = self.anchor;
        NSPoint drag = self.drag;
        NSPoint anchorMatrix = [self matrixFromLocation:anchor];
        NSPoint dragMatrix = [self matrixFromLocation:drag];
        
        [self.delegate alterCoverFromRowStart :MIN(anchorMatrix.y,dragMatrix.y)
                                     colStart :MIN(anchorMatrix.x, dragMatrix.x)
                                     toRowEnd :MAX(anchorMatrix.y, dragMatrix.y)
                                       colEnd :MAX(anchorMatrix.x, dragMatrix.x)
                                     editView :self];
    }
}

@end
