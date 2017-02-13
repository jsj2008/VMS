//
//  VMSTabView.m
//  VMS
//
//  Created by mac_dev on 15/11/25.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VMSTabView.h"

@implementation VMSTabView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    BOOL respond = YES;
    if ([self.delegate respondsToSelector:@selector(shouldRespondHitTestForView:)]) {
        respond = [self.delegate shouldRespondHitTestForView:self];
    }
    
    if (respond) return [super hitTest:aPoint];
    else return self;
}
@end
