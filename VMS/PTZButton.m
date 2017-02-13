//
//  PTZButton.m
//  VMS
//
//  Created by mac_dev on 15/10/16.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "PTZButton.h"

@implementation PTZButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)mouseDown:(NSEvent *)theEvent
{
    id<PTZButtonDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector :@selector(ptzButtonDown:)]) {
        [delegate ptzButtonDown:self];
    }
    
    [super mouseDown:theEvent];
    [self mouseUp:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    id<PTZButtonDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(ptzButtonUp:)]) {
        [delegate ptzButtonUp:self];
    }
    
    [super mouseUp:theEvent];
}
@end
