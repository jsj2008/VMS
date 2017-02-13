//
//  VideoPlayController.m
//  VMS
//
//  Created by mac_dev on 15/11/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VideoPlayController.h"

@implementation VideoPort

- (instancetype)initWithLayer:(OpenGLVidGridLayer *)layer
{
    if (self = [super init]) {
        self.layer = layer;
        self.streamType = FOSSTREAM_MAIN;
        self.channel = nil;
    }
    
    return self;
}

@end


static void render(const void *data,
                   int lineSize,
                   int port,
                   int videoW,
                   int videoH,
                   void *userData)
{
    VideoPlayController *controller = (__bridge VideoPlayController *)(userData);
    
    if (controller) {
        //让层进行渲染
        VideoPort *videoPort = [controller VideoPortAtIdx:port];
        OpenGLVidGridLayer *layer = (OpenGLVidGridLayer *)videoPort.layer;
        [layer copyFrame:data pitch:lineSize width:videoW height:videoH];
        dispatch_async(dispatch_get_main_queue(), ^{
            [layer setNeedsDisplay];
        });
    }
}


@interface VideoPlayController()
@property (readwrite) NSInteger type;
@property (nonatomic,strong) NSMutableArray *videoPorts;
@end

@implementation VideoPlayController

#pragma mark - publick api
- (instancetype)initWithType :(NSInteger)type
{
    if (self = [super init]) {
        self.type = type;
        AVPLAY_Init();
    }
    
    return self;
}

- (void)dealloc
{
    AVPLAY_Cleanup();
}

- (int)freePort
{
    int freePort = -1;
    NSInteger count = self.videoPorts.count;
    for (int port = 0; port < count; port++) {
        VideoPort *videoPort = self.videoPorts[port];
        if (!videoPort.channel) {
            freePort = port;
            break;
        }
    }
    
    return freePort;
}

- (void)addVideoPort :(VideoPort *)videoPort
{
    if (!self.videoPorts) {
        self.videoPorts = [[NSMutableArray alloc] init];
    }
    
    if (videoPort) [self.videoPorts addObject:videoPort];
}

- (VideoPort *)VideoPortAtIdx :(NSInteger)idx
{
    return self.videoPorts[idx];
}
//开始接收指定通道的数据
- (void)startAcceptDataFromChannel :(Channel *)channel
                          withPort :(int)port
{
    VideoRecorder *recorder = [VideoRecorder sharedVideoRecorder];
    VideoPort *videoPort = self.videoPorts[port];
    NSString *title = [NSString stringWithFormat:@"窗口%d  %@",port,[channel name]];
    BOOL recordingState = [recorder queryRecordingStateForChannelId :(int)channel.uniqueId];
    //更新port层
    OpenGLVidGridLayer *layer = videoPort.layer;

//    [self.recording setImage:[NSImage imageNamed :recordingState?@"Recording On" : @"Recording Off"]];
//    self.talk.enabled = YES;
//    self.snap.enabled = YES;
//    self.listen.enabled = YES;
//    self.record.enabled = YES;
//    self.recording.enabled = YES;
//    self.close.enabled = YES;
    if (!videoPort.channel) {
        AVPLAY_SetPlayType(port, self.type);
        AVPLAY_Play(port, NULL,render,NULL ,(__bridge void *)(self));
    } else//refresh
        AVPLAY_Release(port);
    videoPort.channel = channel;
}
//结束接收指定通道的数据
- (void)stopAcceptDataWithPort :(int)port
{
    VideoRecorder *recorder = [VideoRecorder sharedVideoRecorder];
    VideoPort *videoPort = self.videoPorts[port];
//    [self.recording setImage:[NSImage imageNamed:@"Recording Off"]];
//    [self.videoInfoTextField setStringValue :[NSString stringWithFormat:@"窗口%d",port]];
//    [self.record setState :NSOffState];
//    [self.listen setState :NSOffState];
//    self.snap.enabled = NO;
//    self.talk.enabled = NO;
//    self.listen.enabled = NO;
//    self.record.enabled = NO;
//    self.recording.enabled = NO;
//    self.close.enabled = NO;
    videoPort.audioGrabber = nil;
    //关闭手动录像
    [recorder switchManualRecordingState:NO withChannelId:(int)videoPort.channel.uniqueId];
    AVPLAY_Stop(port);
}
//获取指定端口码流类型
- (void)adaptStreamTypeForPort
{
    
}


- (FOSSTREAM_TYPE)streamTypeOfPort :(int)port
{
    VideoPort *videoPort = self.videoPorts[port];
    return videoPort.streamType;
}


#pragma mark - dispatch center protocol
- (void)didRecivedVideoData :(NSData *)data
                       type :(int)type
                  timeStamp :(double)timeStamp
                  channelId :(int)channel_id
                 streamType :(FOSSTREAM_TYPE)stream_type
{
    //轮询VideoPort
    NSInteger count = self.videoPorts.count;
    for (NSInteger port = 0;port < count;port++) {
        VideoPort *videoPort = self.videoPorts[port];
        Channel *channel = videoPort.channel;
        FOSSTREAM_TYPE streamType = videoPort.streamType;
        if (channel.uniqueId == channel_id &&
            streamType == stream_type) {
            NSLog(@"窗口%ld正在播放%@码流",port,(streamType == FOSSTREAM_MAIN)? @"主":@"子");
            switch (type) {
                case DATA_TYPE_AUDIO_PCM://音频流数据
                    AVPLAY_InputAudioData(port, (unsigned char *)data.bytes, data.length, timeStamp);
                    break;
                case DATA_TYPE_VIDEO_H264://视频流数据
                    AVPLAY_InputVideoData(port, (unsigned char *)data.bytes, data.length, timeStamp);
                    //                char test1[5];
                    //                [data getBytes:test1 range:NSMakeRange(0, 5)];
                    //                NSLog(@"%d,%d,%d,%d,%d,%ld,%d,%d",test1[0],test1[1],test1[2],test1[3],test1[4],data.length,channel_id,self.streamType);
                    break;
                default:
                    break;
            }
        }
    }
}

- (void)didRemoveChannelId:(int)channelId
                streamType:(FOSSTREAM_TYPE)stream_type
{
    //轮询VideoPort
    NSInteger count = self.videoPorts.count;
    for (NSInteger port = 0;port < count;port++) {
        VideoPort *videoPort = self.videoPorts[port];
        Channel *channel = videoPort.channel;
        FOSSTREAM_TYPE streamType = videoPort.streamType;
        if (channel &&
            channel.uniqueId == channelId &&
            streamType == stream_type) {
            [self stopAcceptDataWithPort:port];
        }
    }
}

#pragma mark - video player protocol
- (void)videoPlayer:(VideoPlayer *)player
        didReadData:(NSData *)data
               type:(int)type
          timeStamp:(double)timeStamp
          channelId:(int)channelId
{
    NSInteger count = self.videoPorts.count;
    for (NSInteger port = 0;port < count;port++) {
        VideoPort *videoPort = self.videoPorts[port];
        Channel *channel = videoPort.channel;
        if (channel.uniqueId == channelId) {
            switch (type) {
                case 0://音频流数据
                    AVPLAY_InputAudioData(port, (unsigned char *)data.bytes, data.length, timeStamp);
                    break;
                case 1://视频流数据
                    AVPLAY_InputVideoData(port, (unsigned char *)data.bytes, data.length, timeStamp);
                    char test1[5];
                    [data getBytes:test1 range:NSMakeRange(0, 5)];
                    // NSLog(@"Input Video data");
                    NSLog(@"%d,%d,%d,%d,%d,%ld",test1[0],test1[1],test1[2],test1[3],test1[4],data.length);
                    break;
                default:
                    break;
            }
            NSLog(@"type = %d",type);
        }
    }
}

#pragma mark - audio grabber protocol
- (void)audioDataArrived:(NSData *)data
{
//    Channel *channel = self.channel;
//    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
//    
//    if (channel && self.audioGrabber) {
//        //准备数据
//        FOSCAM_NET_TALK_DATA talkData;
//        talkData.data = (char *)data.bytes;
//        talkData.len = (int)data.length;
//        
//        FOSCAM_NET_CONFIG config;
//        config.info = &talkData;
//        [center setConfig :&config forType:FOSCAM_NET_CONFIG_VIDEO_TALK_DATA channel :channel];
//        
//        NSLog(@"Speek");
//    }
}
@end
