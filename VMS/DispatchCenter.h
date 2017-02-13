//
//  DispatchCenter.h
//  VMS
//
//  Created by mac_dev on 15/7/13.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../FoscamNetSDK/IPC/FoscamNetSDK.h"
#import "../FoscamNetSDK/NVR/FoscamNvrNetSDK.h"
#import "../FoscamNetSDK/IPCSDK_for_mac150629/include/fossdk.h"
#import "../FoscamNetSDK/IPCSDK_for_mac150629/include/FosNvrDef.h"
#import "CDevice.h"
#import "Channel.h"

typedef enum {
    IPC,
    NVR,
    UNKNOW,
}DEVICE_TYPE;

typedef struct TAG_VIDEO_DATA {
    void *buffer;
    int length;
    int type;
    double time_stamp;
}VIDEO_DATA;



@class DispatchCenter;//声明

#define DEVICE_ONLINE_STATE_DID_CHANGE_NOTIFICATION     @"device online state did change notification"
#define CONNECTION_STATE_DID_CHANGE_NOTIFICATION        @"connection state did change notification"
#define DEVICE_IMAGE_PARAM_DID_CHANGE_NOTIFICATION      @"device image param did change notification"
#define DEVICE_MIRROR_FLIP_DID_CHANGE_NOTIFICATION      @"device mirror flip did change notification"
#define DEVICE_POWER_FREQUENCY_DID_CHANGE_NOTIFICATION  @"device power frequency did change notification"
#define DEVICE_IRCUT_STATE_DID_CHANGE_NOTIFICATION      @"device ircut state did change notification"
#define DEVICE_CRUISE_MAP_DID_CHANGE_NOTIFICATION       @"device cruise map did change notification"
#define DEVICE_PRESET_POINT_DID_CHANGE_NOTIFICATION     @"device preset point did change notification"
#define DEVICE_RELOAD_NOTIFICATION                      @"device reload notificationf"


#define ALARM_STATE_DID_CHANGE_NOTIFICATION             @"alarm state did change notificaiton"
#define RECORD_FILE_DOWNLOAD_PROGRESS_NOTIFICATION      @"record file download progress notification"
#define PB_NOTIFICATION                                 @"playback notification"

#define KEY_EVENT_DEVICE_ID                                   @"device_id"
#define KEY_EVENT_TYPE                                        @"event_type"
#define KEY_EVENT_CHANNEL_ID                                  @"channel_id"
#define KEY_EVENT_CONNECTION_STATE                            @"connection_state"
#define KEY_DEVICE_STATE                                      @"device_state"
#define KEY_ALARM_STATE                                       @"alarm_state"
#define KEY_IMAGE_PARAM                                       @"image_param"
#define KEY_MIRROR_FLIP                                       @"mirror_flip"
#define KEY_PWRFREQ                                           @"pwrfreq"
#define KEY_IRCUT_STATE                                       @"ircut_state"
#define KEY_CRUISE_MAP                                        @"curise_map"
#define KEY_PRESET_PT                                         @"preset point"
#define KEY_USER_INFO                                         @"user_info"
#define KEY_PROGRESS                                          @"progress"
#define KEY_INDEX                                             @"index"

#define ALARM_INTERVAL  1//报警信号间隔
#define ALARM_DURATION  120//报警持续时间

@protocol DispatchProtocal<NSObject>
@optional

- (void)didRecivedData :(void *)bytes
                length :(int)lenght
                  type :(int)type
             timeStamp :(double)timeStamp
             channelId :(int)channel_id
            streamType :(FOSSTREAM_TYPE)streamType;

- (void)didReconnectedChannelId :(int)channelId
                     streamType :(FOSSTREAM_TYPE)streamType;
- (void)didDisconnectChannelId :(int)channelId
                    streamType :(FOSSTREAM_TYPE)streamType;
- (void)didReciveAlarm :(int) alarmType
             channelId :(int) channelId
            streamType :(FOSSTREAM_TYPE)streamType;

- (void)connectionStateDidChange :(NSNotification *)aNotific;
@end



//能力集
@interface FosAbility : NSObject<NSCopying>

@property(nonatomic,assign) int model;
@property(nonatomic,assign) int wifiType;
@property(nonatomic,assign) int sdFlag;
@property(nonatomic,assign) int outdoorFlag;
@property(nonatomic,assign) int ptFlag;
@property(nonatomic,assign) int zoomFlag;		
@property(nonatomic,assign) int rs485Flag;
@property(nonatomic,assign) int ioAlarmFlag;
@property(nonatomic,assign) int onvifFlag;
@property(nonatomic,assign) int p2pFlag;
@property(nonatomic,assign) int wpsFlag;
@property(nonatomic,assign) int audioFlag;
@property(nonatomic,assign) int talkFlag;

- (id)copyWithZone:(NSZone *)zone;
- (id)initWithProductAllInfo :(FOS_PRODUCTALLINFO *)info;
- (id)initWithNvrAbility :(FOSNVR_Ability*)nvrAbility;
@end

/*
 *使用字典+数组+数组三层存储结构来纪录通道访问信息
 *设备与设备之间并行处理
 *同一设备，不同用户通道间，串行处理
 */
@interface DeviceNode : NSObject

- (instancetype)initWithDeviceId :(int)devId
                        channels :(NSArray *)chns
                         devType :(int)type;

#if OS_OBJECT_HAVE_OBJC_SUPPORT == 1
@property (nonatomic,strong) dispatch_queue_t queue;
#else
@property (nonatomic,assign) dispatch_queue_t queue;
#endif

@property(nonatomic,strong) NSMutableArray *users;//支持多用户访问设备
@property(nonatomic,assign,readonly) int deviceId;
@property(nonatomic,assign,readonly) int devType;
@property(nonatomic,strong,readonly) NSArray *chns;
@property(nonatomic,assign,getter=isOnline) BOOL online;//设备是否在线
@property(nonatomic,assign) int chnEnable;//通道是否可用
@property(nonatomic,assign) int chnAlarmRejected;//通道是否拒绝报警信号(1s的触发间隔)
@property(nonatomic,assign) int chnAlarm;//通道是否产生了报警
@property(nonatomic,strong) NSMutableDictionary *abilities;//能力集

@end


@interface DeviceUser : NSObject

- (instancetype)initWithDeviceNode :(DeviceNode *)node;
- (int)deviceId;

@property(nonatomic,weak,readonly) DeviceNode *deviceNode;//保持对设备信息结点的引用
@property(nonatomic,assign) long userId;
@property(nonatomic,assign) long hPlayback;
@property(nonatomic,assign) int refCnt;
@property(nonatomic,strong) NSArray *realInfos;

@end


@interface RealInfo : NSObject

- (instancetype)initWithChannelId :(int)chnId index :(int)idx;

@property(nonatomic,assign,readonly) int chnId;
@property(nonatomic,assign,readonly) int chnIdx;
@property(nonatomic,assign) int refCnt;
@property(nonatomic,assign) long hReal;
@property(nonatomic,assign) FOSSTREAM_TYPE streamType;

@end


typedef struct
{
    void *config;
    int type;
}FOSCAM_CONFIG;


@interface DispatchCenter : NSObject
@property (nonatomic,strong) NSLock *mutex;
//Public API
+ (DispatchCenter *)sharedDispatchCenter;
- (void)cleanUp;

- (void)addPBObserver:(id<DispatchProtocal>)observer;
- (void)removePBObserver:(id<DispatchProtocal>)observer;
- (void)addObserver:(id<DispatchProtocal>)observer;
- (void)removeObserver:(id<DispatchProtocal>)observer;
+ (void)searchDevicesWithCompletingHandle :(void (^)(NSArray *devices))complete;
//测试设备是否合法，并返回设备通道数,通道数>0时，合法，否则不合法
+ (long)loginDeviceSync :(CDevice *)device channelCnt :(int *)chnCnt result :(int *)result;
+ (void)logoutDeviceSync :(CDevice *)device withUserId :(long)userId;
+ (NSString *)foscamReturnMessage :(FOSCMD_RESULT)code;
+ (bool)modifyDeviceLoginInfo :(CDevice *)device
                   withUserId :(long)userId
                         user :(NSString *)user
                          psw :(NSString *)pwd;
+ (void)testDeviceValid :(CDevice *)device withCompletingHandle :(void (^)(BOOL state,int code))complete;

//网络接收到了来自指定通道的一帧数据，附带时间戳.
- (void)networkReceivedData :(void *)buffer
                     length :(int)length
                       type :(int)data_type
                  timeStamp :(double)time_stamp
                  channelId :(int)channelId
                 streamType :(FOSSTREAM_TYPE)streamType
                 sourceType :(int)sourceType;

- (void)startRealTimeVideoFromDevice :(CDevice *)device channel :(int)chn streamType :(FOSSTREAM_TYPE)streamType queue :(dispatch_queue_t)queue withCompletionHandle :(void (^)(BOOL success))complete;
- (void)stopRealTimeVideoFromDevice :(CDevice *)device channel :(int)chn streamType :(FOSSTREAM_TYPE)streamType;
- (BOOL)startPlaybackVideoFromDevice :(CDevice *)device channels :(int)channels st :(unsigned)st et :(unsigned)et;
- (void)beginConfigDevice :(CDevice *)device queue :(dispatch_queue_t)queue withCompletionHandle :(void (^)(BOOL success))complete;
- (void)endConfigDevice :(CDevice *)device;
- (void)sendPlaybackCmd :(FOSNVR_PBCMD)cmd value :(int)value forDevice :(CDevice *)device;
- (void)stopPlaybackVideoFromDevice :(CDevice *)device;
- (void)setDownloadPath :(char *)path forDevice:(CDevice *)dev;
- (BOOL)downloadRecordFile :(NSValue *)nodes count :(int)cnt fromDevice:(CDevice *)dev;
- (void)downloadCancel:(CDevice *)dev;
- (int)sendPTZControlCommand :(PTZ_CMD)ptzCommand toDevice :(CDevice *)device channel :(int)chn;
- (BOOL)getConfig :(void *)config forType :(int)type fromDevice :(CDevice *)device;
- (BOOL)setConfig :(void *)config forType :(int)type toDevice :(CDevice *)device;
- (FosAbility *)abilityOfDevice :(CDevice *)device channel :(int)ch;
- (BOOL)switchTalking :(BOOL)state device :(CDevice *)dev channel :(int)chn;
- (void)sendTalkingData :(char *)data length :(int)len toDevice :(CDevice *)dev channel :(int)chn;
- (void)testOnlineUseDevice :(CDevice *)device;
- (void)ipcReceivedEvent :(FOSEVET_DATA *)event deviceId :(int)devId;
- (void)nvrReceivedEvent :(FOSNVR_EvetData *)event deviceId :(int)devId;
- (void)nvrReceivedPBEvent:(FOSNVR_PBEVENT)event deviceId:(int)devId;
- (BOOL)getRecordNodeInfo :(FOSNVR_RecordNode *)node atIdx :(int)idx fromDevice :(CDevice *)dev;
- (BOOL)getIpcList :(FOSNVR_IpcNode *)node size :(int *)size fromNvr :(CDevice *)dev;
- (void)logoutDevice :(CDevice *)dev needReset :(BOOL)reset;
- (void)reLoadDevice :(CDevice *)device withCompletionHandle :(void (^)(BOOL success))complete;
- (int)searchRecordFilesWithStartTime :(long long)st endTime :(long long)et type :(FOSNVR_RECORDTYPE)type channels :(int)chs fromDevice :(CDevice *)dev;

@end
