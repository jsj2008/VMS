//
//  JFVideoView.m
//  VMS
//
//  Created by Jeff on 15/5/17.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "JFVideoView.h"
@interface JFVideoView()
@end

@implementation JFVideoView


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self drawToolbar];
    //[self drawOpenGLView];
}

- (void)drawToolbar
{
    CGContextRef ref = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ref);
    
    CGRect bounds = self.bounds;
    NSBezierPath *frame = [NSBezierPath bezierPathWithRect:bounds];
    [frame addClip];
    [[NSColor grayColor] setFill];
    [NSBezierPath fillRect:bounds];
    
    CGContextRestoreGState(ref);
}

@end
