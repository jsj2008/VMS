//
//  AVSourceServer.m
//  VMS
//
//  Created by mac_dev on 15/11/12.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "AVSourceServer.h"

@interface AVSourceState : NSObject

- (id)initWithChannel :(Channel *)chn;
@property (nonatomic,strong) Channel* channel;
@property (nonatomic,assign,getter = isVideoOpened) BOOL videoOpened;
@property (nonatomic,assign,getter = isAudioOpened) BOOL audioOpened;
@end

@implementation AVSourceState

- (instancetype)initWithChannel:(Channel *)chn
{
    if (self = [super init]) {
        self.channel = chn;
        self.videoOpened = NO;
        self.audioOpened = NO;
    }
    
    return self;
}
@end


@interface AVSourceServer()
@property (nonatomic,strong) NSMutableDictionary *avSourceStates;
@property (nonatomic,strong) NSArray *devices;
@end

@implementation AVSourceServer
#pragma mark - public api
- (instancetype)init
{
    if (self = [super init]) {
        [[DispatchCenter sharedDispatchCenter] addObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDatabaseChanged:)
                                                     name:DATABASE_CHANGED_NOTIFICATION
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[DispatchCenter sharedDispatchCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (int)openVideo :(int)chnId
{
    NSMutableDictionary *avStates = self.avSourceStates;
    NSString *identifier = [NSString stringWithFormat:@"C%d",chnId];
    AVSourceState *chnState = [avStates valueForKey:identifier];
    Channel *channel = chnState.channel;
    
    
    if (channel && !chnState.isVideoOpened) {
        [[DispatchCenter sharedDispatchCenter] startRealTimeVideoFromDevice:channel.device
                                                                    channel:(int)channel.logicId
                                                                 streamType:FOSSTREAM_SUB
                                                                      queue:dispatch_get_main_queue()
                                                       withCompletionHandle:^(BOOL success)
         {
             chnState.videoOpened = success;
         }];
    }
    
    //返回值无效
    return -1;
}

- (void)closeVideo :(int)chnId
{
    NSMutableDictionary *avStates = self.avSourceStates;
    NSString        *key = [NSString stringWithFormat:@"C%d",chnId];
    AVSourceState   *chnState = [avStates valueForKey:key];
    Channel         *channel = chnState.channel;
    
    if (channel && chnState.isVideoOpened) {
        [[DispatchCenter sharedDispatchCenter] stopRealTimeVideoFromDevice:channel.device
                                                                   channel:(int)channel.logicId
                                                                streamType:FOSSTREAM_SUB];
        chnState.videoOpened = NO;
    }
}

- (int)openAudio :(int)chnId
{
    NSMutableDictionary *avStates = self.avSourceStates;
    NSString *identifier = [NSString stringWithFormat:@"C%d",chnId];
    AVSourceState *chnState = [avStates valueForKey:identifier];
    
    //视频打开的情况下，允许打开音频
    if (chnState.channel && chnState.videoOpened) {
        chnState.audioOpened = YES;
    }
    
    //返回值无效
    return -1;
}

- (void)closeAudio :(int)chnId
{
    NSMutableDictionary *avStates = self.avSourceStates;
    NSString *identifier = [NSString stringWithFormat:@"C%d",chnId];
    AVSourceState *chnState = [avStates valueForKey:identifier];
    
    if (chnState.channel) {
        chnState.audioOpened = NO;
    }
}

- (void)ptzControlWithChannel :(Channel *)chn
                         type :(int)type
                       param1 :(int)param1
                       param2 :(int)param2
                       param3 :(int)param3
                       param4 :(int)param4
                       param5 :(const char *)param5
{
    NSMutableDictionary *avStates = self.avSourceStates;
    NSString *key = [NSString stringWithFormat:@"C%d",chn.uniqueId];
    AVSourceState *chnState = [avStates valueForKey:key];
    
    if (chnState.channel && chnState.videoOpened) {
        PTZ_CMD cmd;
        cmd.param1 = param1;
        cmd.param2 = param2;
        cmd.param3 = param3;
        cmd.param4 = param4;
        cmd.param5 = (char*)param5;
        cmd.ptzCmd = type;
        [[DispatchCenter sharedDispatchCenter] sendPTZControlCommand:cmd toDevice:chn.device channel:(int)chn.logicId];
    }
}


//- (void)ptzControll :(int)chnId
//               type :(int)type
//             param1 :(int)param1
//             param2 :(int)param2
//             param3 :(int)param3
//             param4 :(int)param4
//             param5 :(const char *)param5
//{
//    NSMutableDictionary *avStates = self.avSourceStates;
//    NSString *identifier = [NSString stringWithFormat:@"C%d",chnId];
//    AVSourceState *chnState = [avStates valueForKey:identifier];
//    
//    if (chnState.channel && chnState.videoOpened) {
//        PTZ_CMD cmd;
//        cmd.param1 = param1;
//        cmd.param2 = param2;
//        cmd.param3 = param3;
//        cmd.param4 = param4;
//        cmd.param5 = (char*)param5;
//        cmd.ptzCmd = type;
//        [[DispatchCenter sharedDispatchCenter] sendPTZControlCommand:cmd toChannelWithId:chnId];
//    }
//}

#pragma mark - database notification
- (void)handleDatabaseChanged :(NSNotification *)aNotific
{
    //数据库发生了改变,应该做些什么呢?
    NSDictionary *userInfo = aNotific.userInfo;
    NSUInteger op = [[userInfo valueForKey:NOTIFI_KEY_DB_OP] unsignedIntegerValue];
    CDevice *device = [userInfo valueForKey:NOTIFI_KEY_DEVICE];
  
    
    switch (op) {
        case VMS_DEVICE_ADD:
            break;
            
        case VMS_DEVICE_REMOVE:{
            for (Channel *channel in device.children) {
                [self closeVideo:(int)channel.uniqueId];
            }
        }
            break;
        case VMS_DEVICE_UPDATE:
            return;//Ignore
            
        case VMS_SHEDULE_RECORD_UPDATE:
            return;//Ignore
            
        default:
            break;
    }
    
    //重新加载通道、设备、组信息
    [self setAvSourceStates:nil];
}

- (void)handleRecordingSettingChanged :(NSNotification *)aNotific
{
    //通知所有Recorder
}
#pragma mark - dispatch center protocol
- (void)didRecivedVideoData:(NSData *)data
                       type:(int)type
                  timeStamp:(double)timeStamp
                  channelId:(int)chnId
                 streamType:(FOSSTREAM_TYPE)streamType
{
    AvSourceCallBack *delegate = self.delegate;
    NSMutableDictionary *avStates = self.avSourceStates;
    NSString *identifier = [NSString stringWithFormat:@"C%d",chnId];
    AVSourceState *chnState = [avStates valueForKey:identifier];

    
    if (chnState.channel && delegate &&
        streamType == FOSSTREAM_SUB) {
        switch (type) {
            case DATA_TYPE_AUDIO_PCM:
                if (chnState.isAudioOpened)
                    delegate->on_audio_data(chnId, (void *)data.bytes, (int)data.length, timeStamp);
                break;
            case DATA_TYPE_VIDEO_H264:
                if (chnState.isVideoOpened)
                    delegate->on_video_data(chnId, (void *)data.bytes, (int)data.length, timeStamp);
                break;
            default:
                break;
        }
    }
}


#pragma mark - private
- (NSMutableDictionary *)buildAVSourceStateMap
{
    NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
    
    //首先取回所有设备
    VMSDatabase *database = [VMSDatabase sharedVMSDatabase];
    NSArray *devices = [database fetchDevices];
    //从设备中取回所有通道
    for (CDevice *device in devices) {
        NSArray *channels = [database fetchChannelsWithDevice:device];
        for (Channel *channel in channels) {
            NSString *identifier = [NSString stringWithFormat:@"C%d",channel.uniqueId];
            //查看记录是否存在
            AVSourceState *state = [map valueForKey:identifier];
            
            if (state) {
                //更新节点通道信息
                state.channel = channel;
            } else {
                //新建节点信息
                state = [[AVSourceState alloc] initWithChannel:channel];
            }
            [map setValue :state forKey:identifier];
        }
    }

    self.devices = devices;
    return map;
}

#pragma mark - setter && getter
- (NSMutableDictionary *)avSourceStates
{
    if (!_avSourceStates)
        _avSourceStates = [self buildAVSourceStateMap];
    
    return _avSourceStates;
}
@end
