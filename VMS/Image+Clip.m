//
//  Image+Clip.m
//  VMS
//
//  Created by mac_dev on 15/6/1.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "Image+Clip.h"

@implementation NSImage(Clip)
- (NSImage *)imageClipedWithRect :(NSRect)rect
{
    CGImageRef imageRef = [self CGImageForProposedRect:nil context:nil hints:nil];
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(imageRef, rect);
    NSImage *croppedImage = [[NSImage alloc] initWithCGImage:croppedImageRef size:NSZeroSize];
    CGImageRelease(croppedImageRef);
    return croppedImage;
}
@end
