//
//  CheckboxHeaderCell.h
//  VMS
//
//  Created by JeffChou on 15/6/11.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//  使用自定义的Checkbox接管绘图，
//  双层绘图，底层使用父cell,上层使用checkbox cell
//  重写- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
//

#import <Cocoa/Cocoa.h>



@interface CheckboxHeaderCell : NSTableHeaderCell
{
    NSButtonCell *cellCheckBox;
    NSColor *bkColor;
}

- (void)setTitle:(NSString *)title;
- (void)setBackgroundColor:(NSColor *)backgroundColor;
//- (void)setState:(NSInteger)state;
- (BOOL)getState;
- (void)onClick;
@end
