//
//  OpenGLVidGridLayer.m
//  VMS
//
//  Created by mac_dev on 15/10/30.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "OpenGLVidGridLayer.h"

@interface OpenGLVidGridLayer()
@property (readwrite) NSInteger port;
@property (readwrite) OpenGLYUVRender *render;
@end


@implementation OpenGLVidGridLayer

#pragma mark - public api
- (instancetype)initWithPort:(NSInteger)port
{
    if (self = [super init]) {
        self.port = port;
        self.asynchronous = NO;
        self.lock = [[NSLock alloc] init];
        CATextLayer *textLayer = [CATextLayer layer];
        textLayer.fontSize = 11;
        [self addSublayer:textLayer];
    }
    return self;
}

- (void)dealloc
{
    free(_yuv420Frame);
}

- (void)copyFrame :(const void *)pixels
            pitch :(int)pitch
            width :(int)width
           height :(int)height
{
    [self.lock lock];
    YUVFrame *yuv420Frame = [self yuv420Frame];
    memcpy(yuv420Frame->pixels, pixels, 3 * width * height / 2);
    yuv420Frame->pitch = pitch;
    yuv420Frame->width = width;
    yuv420Frame->height = height;
    [self.lock unlock];
}

- (void)clear
{
    free(_yuv420Frame);
    _yuv420Frame = NULL;
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
    [self.lock lock];
    CGLSetCurrentContext(ctx);
    
    OpenGLYUVRender *render = self.render;
    
    [render renderClear];
    if (!self.isHidden && _yuv420Frame) {
        YUVFrame *yuv420Frame = [self yuv420Frame];
        const void *pixels = yuv420Frame->pixels;
        int pitch = yuv420Frame->pitch;
        int fWidth = yuv420Frame->width;
        int fHeight = yuv420Frame->height;
        NSRect bounds = self.bounds;
        
        
        if (!render.textureY ||
            (render.textureW != fWidth) ||
            (render.textureH != fHeight)) {
            //数据帧大小发生改变，需要重新生成纹理
            [render destroyTexture];
            [render initTextureWithWidth:fWidth height:fHeight];
        }
        
        [render updateTexturePixels:pixels pitch:pitch srcWidth:fWidth srcHeight:fHeight];
        [render renderWithDstWidth:bounds.size.width dstHeight:bounds.size.height];
    }
    
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime: ts];
    [self.lock unlock];
}

#pragma mark - setter && getter
- (YUVFrame *)yuv420Frame
{
    if (!_yuv420Frame) {
        _yuv420Frame = (YUVFrame *)malloc(sizeof(YUVFrame)*1);
        memset(_yuv420Frame->pixels, 0, FRAME_BUFFER_SIZE);
        _yuv420Frame->height = 0;
        _yuv420Frame->width = 0;
        _yuv420Frame->pitch = 0;
    }
    return _yuv420Frame;
}

- (OpenGLYUVRender *)render
{
    if (!_render) {
        _render = [[OpenGLYUVRender alloc] init];
    }
    
    return _render;
}

@end
