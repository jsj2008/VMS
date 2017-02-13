//
//  OpenGLVidGridLayer.m
//  VMS
//
//  Created by mac_dev on 15/10/30.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "OpenGLVidGridLayer.h"

@interface OpenGLVidGridLayer()

@property (readwrite) NSInteger vId;
@property (readwrite) OpenGLYUVRender *render;
@property (nonatomic,assign) BOOL shouldClear;

@end


@implementation OpenGLVidGridLayer

#pragma mark - public api
- (instancetype)initWithVId:(NSInteger)vId
{
    if (self = [super init]) {
        self.vId = vId;
        self.asynchronous = NO;
        CATextLayer *textLayer = [CATextLayer layer];
        textLayer.fontSize = 11;
        [self addSublayer:textLayer];
    }
    return self;
}

- (bool)getData :(void **)pixels pitch :(int *)pitch width :(int *)width height :(int *)height
{
    return false;
}

- (NSImage *)snap
{
    return nil;
}

- (void)clear
{
    self.shouldClear = YES;
    [self setNeedsDisplay];
}

#pragma mark - private
-(CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask
{
    // The default is fine for this demonstration.
    CGLPixelFormatAttribute attributes[] =
    {
        kCGLPFADoubleBuffer,
        kCGLPFADepthSize, 24,
        // Must specify the 3.2 Core Profile to use OpenGL 3.2
        #if ESSENTIAL_GL_PRACTICES_SUPPORT_GL3
            kCGLPFAOpenGLProfile,
            kCGLOGLPVersion_3_2_Core,
#endif
            0
            };
    CGLPixelFormatObj pixelFormatObj = NULL;
    GLint numPixelFormats = 0;
    CGLChoosePixelFormat(attributes, &pixelFormatObj, &numPixelFormats);
    if(pixelFormatObj == NULL)
        NSLog(@"Error: Could not choose pixel format!");
    return pixelFormatObj;
}

- (BOOL)canDrawInCGLContext:(CGLContextObj)ctx
                pixelFormat:(CGLPixelFormatObj)pf
               forLayerTime:(CFTimeInterval)t
                displayTime:(const CVTimeStamp *)ts
{
    return YES;
}

- (void)drawInCGLContext:(CGLContextObj)ctx
             pixelFormat:(CGLPixelFormatObj)pf
            forLayerTime:(CFTimeInterval)t
             displayTime:(const CVTimeStamp *)ts
{
    CGLSetCurrentContext(ctx);
    
    OpenGLYUVRender *render = self.render;
    
    [render renderClear];
    
    void *pixels = NULL;
    int pitch = 0;
    int width = 0;
    int height = 0;
    
    if (!self.isHidden && !self.shouldClear && [self getData:&pixels pitch:&pitch width:&width height:&height]) {
        NSRect bounds = self.bounds;
        
        
        
        if (!render.textureY ||
            (render.textureW != width) ||
            (render.textureH != height)) {
            //数据帧大小发生改变，需要重新生成纹理
            [render destroyTexture];
            [render initTextureWithWidth:width height:height];
        }
        
        [render updateTexturePixels:pixels pitch:pitch srcWidth:width srcHeight:height];
        [render renderWithDstWidth:bounds.size.width dstHeight:bounds.size.height];
    }
    
    self.shouldClear = NO;
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime: ts];
}

#pragma mark - setter && getter
- (OpenGLYUVRender *)render
{
    if (!_render) {
        _render = [[OpenGLYUVRender alloc] init];
    }
    
    return _render;
}

@end
