//
//  CheckboxHeaderCell.m
//  VMS
//
//  Created by mac_dev on 15/6/11.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "CheckboxHeaderCell.h"

#define kXLocationOffset    1
@implementation CheckboxHeaderCell

- (id)init
{
    if (self = [super init]) {
        bkColor = nil;
        cellCheckBox = [[NSButtonCell alloc] init];
        [cellCheckBox setTitle:@""];
        [cellCheckBox setButtonType:NSSwitchButton];
        [cellCheckBox setBordered:NO];
        [cellCheckBox setImagePosition:NSImageLeft];
        [cellCheckBox setAlignment:NSLeftTextAlignment];
        [cellCheckBox setObjectValue:[NSNumber numberWithInt:0]];
        [cellCheckBox setControlSize:NSRegularControlSize];
        [self setStringValue:@""];
    }
    
    return self;
}

- (void)setTitle:(NSString *)title
{
    [cellCheckBox setTitle:title];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
}

//- (void)setState:(NSInteger)state
//{
//    [cellCheckBox setState:state];
//}

- (BOOL)getState
{
    return [[cellCheckBox objectValue] boolValue];
}

- (void)onClick
{
    BOOL state = ![[cellCheckBox objectValue] boolValue];
    [cellCheckBox setObjectValue:[NSNumber numberWithBool:state]];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect newFrame = CGRectMake(cellFrame.origin.x + kXLocationOffset,
                                 cellFrame.origin.y,
                                 cellFrame.size.width,
                                 cellFrame.size.height);
    
    [super drawWithFrame:cellFrame inView:controlView];
    [cellCheckBox drawWithFrame:newFrame inView:controlView];
}

@end
