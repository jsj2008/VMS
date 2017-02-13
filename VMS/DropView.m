//
//  DropView.m
//  VMS
//
//  Created by mac_dev on 15/9/17.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "DropView.h"

@implementation DropView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

#pragma mark - dragging destination protocol
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ([NSImage canInitWithPasteboard:[sender draggingPasteboard]]) {
        return NSDragOperationCopy;
    }
    
    return NSDragOperationDelete;
}
@end
