//
//  VideoPlayController.h
//  VMS
//
//  Created by mac_dev on 15/11/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DispatchCenter.h"
#import "../libplay/libplay/avplay_sdk.h"
#import "../VidGridLayer/VidGridLayer/OpenGLVidGridLayer.h"
#import "VideoRecorder.h"
#import "VideoPlayer.h"
#import "AudioGrabber.h"

@interface VideoPort : NSObject

@property (nonatomic,strong) OpenGLVidGridLayer *layer;
@property (nonatomic,assign) FOSSTREAM_TYPE streamType;
@property (nonatomic,strong) Channel *channel;
@property (nonatomic,strong) AudioGrabber *audioGrabber;
- (instancetype)initWithLayer :(OpenGLVidGridLayer *)layer;
@end


@interface VideoPlayController : NSObject<DispatchProtocal,
VideoRecorderProtocol,VideoPlayerProtocol,AudioGrabberProtocol>
@property (nonatomic,assign,readonly) NSInteger type;//播放类型AVPLAY_TYPE_FILE | AVPLAY_TYPE_STREAM

- (instancetype)initWithType :(NSInteger)type;
- (void)dealloc;
- (int)freePort;
- (void)addVideoPort :(VideoPort *)videoPort;
- (VideoPort *)VideoPortAtIdx :(NSInteger)idx;
//获取屏幕坐标点所对应的端口号
- (int)portForPoint :(NSPoint)screenPoint;
- (BOOL)isFreePort :(int)port;
//开始接收指定通道的数据
- (void)startAcceptDataFromChannel :(Channel *)channel
                          withPort :(int)port;
//结束接收指定通道的数据
- (void)stopAcceptDataWithPort :(int)port;
//获取指定端口码流类型
- (void)adaptStreamTypeForPort;
- (FOSSTREAM_TYPE)streamTypeOfPort :(int)port;
//
- (void)toggleListen :(NSInteger)port
               state :(BOOL)state;
- (void)toggleTalk :(NSInteger)port
             state :(BOOL)state;
@end
