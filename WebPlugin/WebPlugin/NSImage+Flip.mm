//
//  NSImage+Flip.m
//  VMS
//
//  Created by mac_dev on 15/11/23.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NSImage+Flip.h"

@implementation NSImage (Flip)

- (void)flipImageVertically {
    NSAffineTransform *flipper = [NSAffineTransform transform];
    NSSize dimensions = self.size;
    [self lockFocus];
    
    [flipper scaleXBy:1.0 yBy:-1.0];
    [flipper set];
    
    [self drawAtPoint:NSMakePoint(0,-dimensions.height)
             fromRect:NSMakeRect(0,0, dimensions.width, dimensions.height)
            operation:NSCompositeCopy fraction:1.0];
    
    [self unlockFocus];
}

- (void)flipImageHorizontally {
    NSAffineTransform *flipper = [NSAffineTransform transform];
    NSSize dimensions = self.size;
    [self lockFocus];
    
    [flipper scaleXBy:-1.0 yBy:1.0];
    [flipper set];
    
    [self drawAtPoint:NSMakePoint(-dimensions.height,0)
             fromRect:NSMakeRect(0,0, dimensions.width, dimensions.height)
            operation:NSCompositeCopy fraction:1.0];
    
    [self unlockFocus];
}
@end
