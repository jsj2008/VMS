//
//  AVPLAYLayer.m
//  VMS
//
//  Created by mac_dev on 2016/11/28.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "AVPLAYLayer.h"

@implementation AVPLAYLayer

#pragma mark - public
- (instancetype)init
{
    if (self = [super init]) {
        self.port = -1;
    }
    
    return self;
}

- (bool)getData :(void **)pixels pitch :(int *)pitch width :(int *)width height :(int *)height
{
    return AVPLAY_GetDecodedData(self.port, pixels, pitch, width, height);
}

- (NSImage *)snap
{
    NSImage *img = nil;
    
    AVPLAY_DecodeLock(self.port);
    
    void *pixels = NULL;
    int pitch = 0;
    int width = 0;
    int height = 0;
    
    if (AVPLAY_GetSnapData(self.port, &pixels, &pitch, &width, &height)) {
        char *szNewRGBData = malloc(sizeof(char) * 3 * width * height);
        
        for(int i = 0;i < height;i++)
            memcpy(szNewRGBData+ i * width * 3,pixels+(height -i - 1) * width * 3,width * 3);
  
        
        //转换为NSImage
        CGBitmapInfo    bitmapInfo  = kCGBitmapByteOrderDefault;
        CFDataRef       imgData     = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
                                                                  pixels,
                                                                  pitch*height,
                                                                  kCFAllocatorNull);
        CGDataProviderRef   provider = CGDataProviderCreateWithCFData(imgData);
        CGColorSpaceRef     colorSpace = CGColorSpaceCreateDeviceRGB();
        CGImageRef          cgImage = CGImageCreate(width,
                                                    height,
                                                    8,
                                                    24,
                                                    pitch,
                                                    colorSpace,
                                                    bitmapInfo,
                                                    provider,
                                                    NULL,
                                                    NO,
                                                    kCGRenderingIntentDefault);
        CGColorSpaceRelease(colorSpace);
        img = [[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(width, height)];
        CGImageRelease(cgImage);
        CGDataProviderRelease(provider);
        CFRelease(imgData);
        free(szNewRGBData);
        //[img flipImageVertically];
    }
    
    AVPLAY_DecodeUnLock(self.port);
    
    return img;
}

#pragma mark - draw
- (void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    AVPLAY_DecodeLock(self.port);
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
    AVPLAY_DecodeUnLock(self.port);
}



@end
