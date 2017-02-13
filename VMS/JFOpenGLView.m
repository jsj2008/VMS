//
//  JFOpenGLView.m
//  VMS
//
//  Created by mac_dev on 15/5/21.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "JFOpenGLView.h"
@interface JFOpenGLView()

@property (weak) id target;
@property (assign) SEL action;
@end

@implementation JFOpenGLView

#pragma mark - Public API
- (void)setTarget :(id)target action :(SEL)action
{
    if (target) {
        self.target = target;
        self.action = action;
    }
}

#pragma mark - Action
- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    //NSPoint pt = theEvent.locationInWindow;
    [self.target performSelector:self.action withObject:theEvent];
}

#pragma mark - Draw
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
//    if (!self.connected) {
//        NSGraphicsContext *ref = [NSGraphicsContext currentContext];
//        [ref saveGraphicsState];
//        
//        ///draw background
//        CGRect openGLViewFrame = self.bounds;
//        
//        NSBezierPath *openGLViewFramePath = [NSBezierPath bezierPathWithRect:openGLViewFrame];
//        [openGLViewFramePath addClip];
//        [[NSColor blackColor] set];
//        [openGLViewFramePath fill];
//        
//        ///draw text
//        CGRect textFrame = CGRectMake(0, (self.bounds.size.height ) /2.0 - 16 ,
//                                      self.bounds.size.width, 16);
//        NSMutableParagraphStyle *phStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
//        [phStyle setAlignment:NSCenterTextAlignment];
//        
//        NSFont *font = [NSFont fontWithName:@"Times" size:15];
//        NSDictionary *textAttributes = @{NSFontAttributeName : font,
//                                         NSForegroundColorAttributeName : [NSColor  whiteColor],
//                                         NSParagraphStyleAttributeName : phStyle};
//        NSString *text = @"no vidio";
//        [text drawInRect:textFrame withAttributes:textAttributes];
//        
//        [ref restoreGraphicsState];
//    }
//测试SDL 窗口是否覆盖
//    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(self.bounds, 10, 10)];
//    [[NSColor redColor] set];
//    [path stroke];
}


@end
