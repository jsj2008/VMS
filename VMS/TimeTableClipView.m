//
//  TimeTableClipView.m
//  VMS
//
//  Created by mac_dev on 16/8/8.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "TimeTableClipView.h"

@implementation TimeTableClipView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    id obj = self.subviews.lastObject;
    if ([obj isKindOfClass:[TimeTableView class]]) {
        [obj modifyFrameRect];
    }
}

@end
