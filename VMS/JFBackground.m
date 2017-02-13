//
//  JFBackground.m
//  VMS
//
//  Created by Jeff on 15/5/27.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "JFBackground.h"

@implementation JFBackground

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self drawBackground];
    // Drawing code here.
}

- (void)drawBackground
{
    NSGraphicsContext *ref = [NSGraphicsContext currentContext];
    [ref saveGraphicsState];
    
    NSBezierPath *boundsPath = [NSBezierPath bezierPathWithRect:self.bounds];
    if (self.backgroundColor) {
        [self.backgroundColor set];
        [boundsPath fill];
    }

    [ref restoreGraphicsState];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    [self setNeedsDisplay:YES];
}
@end
