//
//  OpenGLYUVRender.m
//  VMS
//
//  Created by mac_dev on 15/11/1.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "OpenGLYUVRender.h"

@interface OpenGLYUVRender()
@property (readwrite) GLuint textureY;
@property (readwrite) GLuint textureU;
@property (readwrite) GLuint textureV;
@property (readwrite) GLsizei textureW;
@property (readwrite) GLsizei textureH;
@end

@implementation OpenGLYUVRender

- (instancetype)init
{
    if (self = [super init]) {
        _program = [self buildProgram];
    }
    
    return self;
}

- (void)dealloc
{
    [self destroyTexture];
}

- (void)initTextureWithWidth :(GLsizei)width
                      height :(GLsizei)height;
{
    if (!self.textureY) {
        self.textureW = width;
        self.textureH = height;
        
        glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &_textureY);
        glBindTexture(GL_TEXTURE_2D, _textureY);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE,GL_STORAGE_SHARED_APPLE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, _textureW, _textureH, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, NULL);
        
        glGenTextures(1, &_textureU);
        glBindTexture(GL_TEXTURE_2D, _textureU);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, _textureW/2,_textureH/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, NULL);
        
        glGenTextures(1, &_textureV);
        glBindTexture(GL_TEXTURE_2D, _textureV);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, _textureW/2,_textureH/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, NULL);
        glDisable(GL_TEXTURE_2D);
    }
}

- (void)destroyTexture
{
    if (_textureY) {
        _textureW = _textureH = 0;
        glDeleteTextures(1, &_textureY);
        glDeleteTextures(1, &_textureU);
        glDeleteTextures(1, &_textureV);
        self.textureY = self.textureU = self.textureV = 0;
    }
}

- (GLuint)buildProgram
{
    GLint vertCompiled = 0;
    GLint fragCompiled= 0;
    GLint linked = 0;
    
    GLint v, f;
    GLuint program;
    const char *vs,*fs;
    
    static const char vertex_shader_source[] =
    "attribute  vec4 vertexIn;\n"
    "attribute  vec2 textureIn;\n"
    "varying  vec2 textureOut;\n"
    
    "void main(void)\n"
    "{\n"
    "    gl_Position = vertexIn;\n"
    "    textureOut = textureIn;\n"
    "}\n";
    
    static const char fragment_shader_source[] =
    "varying vec2 textureOut;\n"
    "uniform sampler2D tex_y;\n"
    "uniform sampler2D tex_u;\n"
    "uniform sampler2D tex_v;\n"
    "void main(void)\n"
    "{\n"
    "    vec3 yuv;\n"
    "    vec3 rgb;\n"
    "    yuv.x = texture2D(tex_y, textureOut).r;\n"
    "    yuv.y = texture2D(tex_u, textureOut).r - 0.5;\n"
    "    yuv.z = texture2D(tex_v, textureOut).r - 0.5;\n"
    "    rgb = mat3( 1,       1,         1,\n"
    "               0,       -0.39465,  2.03211,\n"
    "               1.13983, -0.58060,  0) * yuv;\n"
    "    gl_FragColor = vec4(rgb, 1);\n"
    "}\n";
    
    //Source code
    vs = vertex_shader_source;
    fs = fragment_shader_source;
    
    //Shader: step1
    v = glCreateShader(GL_VERTEX_SHADER);
    f = glCreateShader(GL_FRAGMENT_SHADER);
    //Shader: step2
    glShaderSource(v, 1, &vs,NULL);
    glShaderSource(f, 1, &fs,NULL);
    //Shader: step3
    glCompileShader(v);
    //Debug
    glGetShaderiv(v, GL_COMPILE_STATUS, &vertCompiled);
    glCompileShader(f);
    glGetShaderiv(f, GL_COMPILE_STATUS, &fragCompiled);
    
    //Program: 创建program
    program = glCreateProgram();
    //Program: 绑定shader到program上
    glAttachShader(program,v);
    glAttachShader(program,f);
    //Program: 链接program
    glLinkProgram(program);
    //Debug
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    //Program: 使用program
    glUseProgram(program);
    
    return program;
}

- (void)updateTexturePixels :(const void *)pixels
                      pitch :(int)pitch
                   srcWidth :(int)srcW
                  srcHeight :(int)srcH;
{
    if (!pixels) return;
    if (self.textureY) {
        unsigned char *plane[3];
        //YUV Data
        plane[0] = (unsigned char *)pixels;
        plane[1] = plane[0] + pitch * srcH;
        plane[2] = plane[1] + pitch * srcH/4;
        
        GLuint textureUniformY = glGetUniformLocation(_program, "tex_y");
        GLuint textureUniformU = glGetUniformLocation(_program, "tex_u");
        GLuint textureUniformV = glGetUniformLocation(_program, "tex_v");
        
        glEnable(GL_TEXTURE_2D);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _textureY);
        //设置像素存储模式
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ROW_LENGTH,(pitch / 1.0));
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, srcW, srcH, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pixels);
        glUniform1i(textureUniformY, 0);
        
        //UV
        glPixelStorei(GL_UNPACK_ROW_LENGTH, (pitch / 2));//更改像素存储格式
        pixels = (const void*)((const unsigned char*)pixels + srcH * pitch);
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, _textureU);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, srcW/2, srcH/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pixels);
        glUniform1i(textureUniformU, 1);
        
        pixels = (const void*)((const unsigned char*)pixels + (srcH * pitch)/4);
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, _textureV);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, srcW/2, srcH/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pixels);
        glUniform1i(textureUniformV, 2);
        glDisable(GL_TEXTURE_2D);
    }
}

- (void)renderClear
{
    glEnable(GL_TEXTURE_2D);
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glDisable(GL_TEXTURE_2D);
}

- (void)renderWithDstWidth :(GLsizei)dstW dstHeight :(GLsizei)dstH;
{
    @try {
        glEnable(GL_TEXTURE_2D);
        glViewport(0, 0, dstW, dstH);
        
        //物体表面坐标系
        static const GLfloat vertexCoords[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };
        //纹理表面坐标系
        static const GLfloat textureCoords[] = {
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f,  0.0f,
            1.0f,  0.0f,
        };
        glUseProgram(_program);
        // Update attribute values
        int vertexIn = glGetAttribLocation(_program, "vertexIn");
        int textureIn = glGetAttribLocation(_program, "textureIn");
        glEnableVertexAttribArray(vertexIn);
        glVertexAttribPointer(vertexIn, 2, GL_FLOAT, GL_FALSE, 0, vertexCoords);
        glEnableVertexAttribArray(textureIn);
        glVertexAttribPointer(textureIn, 2, GL_FLOAT, GL_FALSE, 0, textureCoords);
        
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glDisable(GL_TEXTURE_2D);
    } @catch (NSException *exception) {
        GLenum err = glGetError();
        
        NSLog(@"glError = %d",err);
    }
}


- (NSString *)errMsg :(uint32_t)code
{
    switch (code) {
        case GL_NO_ERROR:
            return @"GL_NO_ERROR";
        case GL_INVALID_ENUM:
            return @"GL_INVALID_ENUM";
        case GL_INVALID_VALUE:
            return @"GL_INVALID_VALUE";
        case GL_INVALID_OPERATION:
            return @"GL_INVALID_OPERATION";
        case GL_STACK_OVERFLOW:
            return @"GL_STACK_OVERFLOW";
        case GL_STACK_UNDERFLOW:
            return @"GL_STACK_UNDERFLOW";
        case GL_OUT_OF_MEMORY:
            return @"GL_OUT_OF_MEMORY";;
        default:
            return @"GL_UNKNOW_ERROR";
    }
}
@end
