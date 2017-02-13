//
//  TBButton.m
//  
//
//  Created by mac_dev on 16/3/28.
//
//

#import "TBButton.h"

@implementation TBButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

//在接收到鼠标按下的事件后，沿着响应者链传递下去，让其它组件也有机会处理这个事件.
- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    [self.nextResponder mouseDown:theEvent];
}
@end
