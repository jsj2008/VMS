//
//  Image+Clip.h
//  VMS
//
//  Created by mac_dev on 15/6/1.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage(Clip)
- (NSImage *)imageClipedWithRect :(NSRect)rect;
@end