//
//  VMSTableView.m
//  VMS
//
//  Created by mac_dev on 16/8/24.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "VMSTableView.h"

@implementation VMSTableView

- (void)mouseDown:(NSEvent *)theEvent {
    
    NSPoint globalLocation = [theEvent locationInWindow];
    NSPoint localLocation = [self convertPoint:globalLocation fromView:nil];
    NSInteger clickedRow = [self rowAtPoint:localLocation];
    
    [super mouseDown:theEvent];
    
    if (clickedRow != -1) {
        if ([self.extendedDelegate respondsToSelector:@selector(tableView:didClickedRow:)]) {
            [self.extendedDelegate tableView:self didClickedRow:clickedRow];
        }
    }
}

@end
