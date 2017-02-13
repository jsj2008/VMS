//
//  OpenGLYUVRender.h
//  VMS
//
//  Created by mac_dev on 15/11/1.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/gl.h>

@interface OpenGLYUVRender : NSObject {
    GLuint _program;
    unsigned char *buffer;
}

@property (nonatomic,assign,readonly) GLuint textureY;
@property (nonatomic,assign,readonly) GLuint textureU;
@property (nonatomic,assign,readonly) GLuint textureV;
@property (nonatomic,assign,readonly) GLsizei textureW;
@property (nonatomic,assign,readonly) GLsizei textureH;

- (instancetype)init;
- (void)dealloc;
- (void)initTextureWithWidth :(GLsizei)width height :(GLsizei)height;
- (void)destroyTexture;
- (GLuint)buildProgram;
- (void)updateTexturePixels :(const void *)pixels
                      pitch :(int)pitch
                   srcWidth :(int)srcWidth
                  srcHeight :(int)srcHeight;
- (void)renderClear;
- (void)renderWithDstWidth :(GLsizei)dstW dstHeight :(GLsizei)dstH;
- (NSString *)errMsg :(uint32_t)code;

@end
