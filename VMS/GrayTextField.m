//
//  GrayTextField.m
//  TFEnable
//
//  Created by mac_dev on 16/8/19.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "GrayTextField.h"

@implementation GrayTextField

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self setDrawsBackground:YES];
    [self setBackgroundColor:enabled?[NSColor controlColor] : [NSColor windowBackgroundColor]];
}

@end
