//
//  NSTextFieldCell+CenterVertical.m
//  VMS
//
//  Created by mac_dev on 15/10/22.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NSTextFieldCell+CenterVertical.h"

@implementation NSTextFieldCell (CenterVertical)

- (void)setVerticalCentering:(BOOL)centerVertical
{
    @try { _cFlags.vCentered = centerVertical ? 1 : 0; }
    @catch(...) { NSLog(@"*** unable to set vertical centering"); }
}

@end
