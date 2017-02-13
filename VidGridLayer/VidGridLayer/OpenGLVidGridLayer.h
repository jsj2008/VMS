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
#define FRAME_BUFFER_SIZE   1024*1024*8

@interface OpenGLVidGridLayer : CAOpenGLLayer

@property (nonatomic,assign,readonly) NSInteger vId;
@property (nonatomic,strong,readonly) OpenGLYUVRender *render;
@property (nonatomic,assign,getter=isInSingleViewMode) BOOL inSingleViewMode;

- (instancetype)initWithVId :(NSInteger)vId;
- (void)clear;


//重写下面的方法，为渲染提供数据
- (bool)getData :(void **)pixels pitch :(int *)pitch width :(int *)width height :(int *)height;
- (NSImage *)snap;

@end
