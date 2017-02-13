//
//  OpenGLVidGridLayer.h
//  VMS
//
//  Created by mac_dev on 15/10/30.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <Cocoa/Cocoa.h>
#import "OpenGLYUVRender.h"

#define WIDGETS_HEIGHT  16.0
#define FRAME_BUFFER_SIZE   1024*1024*4
typedef struct{
    unsigned char pixels[FRAME_BUFFER_SIZE];
    int pitch;
    int width;
    int height;
}YUVFrame;

@interface OpenGLVidGridLayer : CAOpenGLLayer {
    YUVFrame *_yuv420Frame;
}

@property (nonatomic,assign,readonly) NSInteger port;

@property (nonatomic,strong) NSLock *lock;
@property (nonatomic,strong,readonly) OpenGLYUVRender *render;
@property (nonatomic,assign,getter=isInSingleViewMode) BOOL inSingleViewMode;
- (instancetype)initWithPort :(NSInteger)port;
- (void)dealloc;
- (void)copyFrame :(const void *)pixels
            pitch :(int)pitch
            width :(int)width
           height :(int)height;
- (void)clear;
@end
