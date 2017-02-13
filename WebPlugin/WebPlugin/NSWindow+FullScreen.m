//
//  NSWindow+FullScreen.m
//  WebPlugin
//
//  Created by mac_dev on 15/11/11.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NSWindow+FullScreen.h"

@implementation NSWindow (FullScreen)
- (BOOL)isFullScreen
{
    return (([self styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask);
}
@end
