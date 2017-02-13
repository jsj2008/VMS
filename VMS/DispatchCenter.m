//
//  DispatchCenter.m
//  VMS
//
//  Created by mac_dev on 15/7/13.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "DispatchCenter.h"
#import <arpa/inet.h>
#import "XMLHelper.h"

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)


#define debug  0
#define TRACE if (debug) {\
NSLog(@"Running in %@,'%@'",[self class],NSStringFromSelector(_cmd));\
}

static DispatchCenter *sharedDispatchCenter = nil;
static dispatch_once_t pred;

static void fileEventCallback(long realHandle,
                              FOSNVR_PBEVENT event,
                              void *userInfo)
{
    @autoreleasepool {
        DeviceUser *user = (__bridge DeviceUser *)userInfo;
        [sharedDispatchCenter nvrReceivedPBEvent:event deviceId:user.deviceId];
    }
}

static void fileDataCallback(long realHandle,
                             int ch,
                             unsigned int dataType,
                             unsigned char *buffer,
                             unsigned long bufferSize,
                             void *userData,
                             double pt)
{
    @autoreleasepool {
        DeviceUser *user = (__bridge DeviceUser *)userData;
        int chnId = [(RealInfo *)user.realInfos[ch] chnId];
        
        [sharedDispatchCenter networkReceivedData:buffer
                                           length:(int)bufferSize
                                             type:dataType
                                        timeStamp:pt
                                        channelId:chnId
                                       streamType:FOSSTREAM_MAIN
                                       sourceType:1];
        //NSLog(@"ch=%d,pt=%lf",ch,pt);
    }
}

static void dataCallback(long realHandle,
                         unsigned int dataType,
                         unsigned char *buffer,
                         unsigned long bufferSize,
                         void *userData,
                         double pt)
{
    @autoreleasepool {
        RealInfo *info       = (__bridge RealInfo *)userData;
        [sharedDispatchCenter networkReceivedData:buffer
                             length:(int)bufferSize
                               type:dataType
                          timeStamp:pt
                          channelId:info.chnId
                         streamType:info.streamType
                         sourceType:0];
        
//        unsigned char *buf = buffer;
//        int type = *(buf + 4)&0x1f;
//        switch (type) {
//            case 7:
//            case 8: {
//                NSLog(@"");
//            }
//                break;
//                
//            default:
//                break;
//        }
        
        //NSLog(@"%d,%d,%d,%d,%d,%d,%lu",*buf,*(buf + 1),*(buf + 2),*(buf + 3),*(buf + 4),*(buf + 4)&0x1f,bufferSize);
    }
}

static void ipcEventCallback(long userId,void *netEvent ,void *userData)
{
    @autoreleasepool {
        DeviceUser      *user = (__bridge DeviceUser *)(userData);
        DispatchCenter  *center     = sharedDispatchCenter;
        int            devId       = [user deviceId];
        
        [center ipcReceivedEvent:netEvent deviceId:devId];
    }
}

static void nvrEventCallback(long userId,void *netEvent,void *userData)
{
    @autoreleasepool {
        DeviceUser      *user = (__bridge DeviceUser *)(userData);
        DispatchCenter  *center     = sharedDispatchCenter;
        int            devId       = [user deviceId];
        
        [center nvrReceivedEvent:netEvent deviceId:devId];
    }
}



@interface FosAbility()

@end

@implementation FosAbility

- (id)copyWithZone:(NSZone *)zone
{
    FosAbility *copy = [[self class] allocWithZone:zone];
    
    copy.model = self.model;
    copy.wifiType = self.wifiType;
    copy.sdFlag = self.sdFlag;
    copy.outdoorFlag = self.outdoorFlag;
    copy.ptFlag = self.ptFlag;
    copy.zoomFlag = self.zoomFlag;
    copy.rs485Flag = self.rs485Flag;
    copy.ioAlarmFlag = self.ioAlarmFlag;
    copy.onvifFlag = self.onvifFlag;
    copy.p2pFlag = self.p2pFlag;
    copy.wpsFlag = self.wpsFlag;
    copy.audioFlag = self.audioFlag;
    copy.talkFlag = self.talkFlag;
    
    return copy;
}

- (id)initWithProductAllInfo :(FOS_PRODUCTALLINFO *)info
{
    if (self = [super init]) {
        self.model = info->model;
        self.wifiType = info->wifiType;
        self.sdFlag = info->sdFlag;
        self.outdoorFlag = info->outdoorFlag;
        self.ptFlag = info->ptFlag;
        self.zoomFlag = info->zoomFlag;
        self.rs485Flag = info->rs485Flag;
        self.ioAlarmFlag = info->ioAlarmFlag;
        self.onvifFlag = info->onvifFlag;
        self.p2pFlag = info->p2pFlag;
        self.wpsFlag = info->wpsFlag;
        self.audioFlag = info->audioFlag;
        self.talkFlag = info->talkFlag;
    }
    
    return self;
}

- (id)initWithNvrAbility :(FOSNVR_Ability*)info
{
    if (self = [super init]) {
        self.model = info->model;
        self.wifiType = info->wifiType;
        self.sdFlag = info->sdFlag;
        self.outdoorFlag = info->outdoorFlag;
        self.ptFlag = info->ptFlag;
        self.zoomFlag = info->zoomFlag;
        self.rs485Flag = info->rs485Flag;
        self.ioAlarmFlag = info->ioAlarmFlag;
        self.onvifFlag = info->onvifFlag;
        self.p2pFlag = info->p2pFlag;
        self.wpsFlag = info->wpsFlag;
        self.audioFlag = info->audioFlag;
        self.talkFlag = info->talkFlag;
    }
    
    return self;
}

@end
/*
 *下面这些对象存储设备和通道状态
 */
@interface DeviceNode()
@property(readwrite) int deviceId;
@property(readwrite) int devType;
@property(readwrite) NSArray *chns;
@end

@implementation DeviceNode
- (instancetype)initWithDeviceId :(int)devId
                        channels :(NSArray *)chns
                         devType :(int)type
{
    if (self = [super init]) {
        self.deviceId = devId;
        self.chns = chns;
        self.online = NO;
        self.queue = dispatch_queue_create([[NSString stringWithFormat:@"com.vms.dispatch_center.device%d",devId] UTF8String], DISPATCH_QUEUE_SERIAL);
        self.chnEnable = 0;
        self.devType = type;
        self.abilities = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (NSMutableArray *)users
{
    if (!_users) {
        _users = [[NSMutableArray alloc] init];
    }
    
    return _users;
}


- (void)reportChannelOnlineState:(BOOL)state withDeviceId :(int)dId channelId :(int)cId
{
    NSMutableDictionary *userInfo =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:dId],KEY_EVENT_DEVICE_ID, nil];
    
    [userInfo setValue:[NSNumber numberWithInt:cId] forKey:KEY_EVENT_CHANNEL_ID];
    [userInfo setValue:[NSNumber numberWithInt:state] forKey:KEY_EVENT_CONNECTION_STATE];
    [[NSNotificationCenter defaultCenter] postNotificationName:CONNECTION_STATE_DID_CHANGE_NOTIFICATION
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)setOnline:(BOOL)online
{
    if (online != _online) {
        _online = online;
        NSMutableDictionary *userInfo =
        [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:_online],KEY_DEVICE_STATE, [NSNumber numberWithLong:self.deviceId],KEY_EVENT_DEVICE_ID,nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_ONLINE_STATE_DID_CHANGE_NOTIFICATION
                                                            object:self
                                                          userInfo:userInfo];
        
        if (self.devType == IPC) {
            [self reportChannelOnlineState:_online withDeviceId:self.deviceId channelId:0];
        }
        else if (self.devType == NVR && !_online) {
            //如果nvr离线，通知所有通道离线消息
            for (int i = 0; i < self.chns.count; i++) {
                [self reportChannelOnlineState:NO withDeviceId:self.deviceId channelId:i];
            }
        }
    }
}

@end


@interface DeviceUser()

@property(readwrite) DeviceNode *deviceNode;

@end

@implementation DeviceUser
- (instancetype)initWithDeviceNode:(DeviceNode *)node
{
    if (self = [super init]) {
        //准备创建real info
        NSMutableArray *realInfos = [[NSMutableArray alloc] init];
        for (int i = 0; i < node.chns.count; i++) {
            int chnId = [[node.chns objectAtIndex:i] intValue];
            [realInfos addObject:[[RealInfo alloc] initWithChannelId:chnId index:i]];
        }
        self.realInfos  = [NSArray arrayWithArray:realInfos];
        self.refCnt     = 1;
        self.userId     = -1;
        self.hPlayback  = -1;
        self.deviceNode = node;
    }
    
    return self;
}

- (int)deviceId
{
    return self.deviceNode? self.deviceNode.deviceId : -1;
}

@end


@interface RealInfo()

@property(readwrite) int chnId;
@property(readwrite) int chnIdx;

@end

@implementation RealInfo

- (instancetype)initWithChannelId :(int)chnId index :(int)idx
{
    if (self = [super init]) {
        self.chnId = chnId;
        self.chnIdx = idx;
        self.refCnt = 0;
        self.hReal = -1;
        self.streamType = FOSSTREAM_MAIN;
    }
    
    return self;
}

@end


@interface DispatchCenter()
@property (strong,nonatomic) NSMutableArray *pbObservers;//回放观察者
@property (strong,nonatomic) NSMutableArray *observers;//调度中心内部维护观察者列表，向各个观察者发送通告消息.
@property (strong,nonatomic) NSMutableDictionary *channelMap;
@property (strong,nonatomic) NSMutableDictionary *deviceMap;

@end

@implementation DispatchCenter

#pragma mark - public API

+(DispatchCenter *)sharedDispatchCenter
{
    dispatch_once(&pred, ^{
        sharedDispatchCenter = [[super allocWithZone:NULL] init];
        sharedDispatchCenter.mutex = [[NSLock alloc] init];
        if (!FOSCAM_NET_Init() || !FOSCAM_NVR_Init()) {
            NSLog(@"Failed to init FOSCAM_NET_SDK");
            exit(0);
        }
    });
    return sharedDispatchCenter;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedDispatchCenter];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)dealloc
{
    [self cleanUp];
}

- (void)cleanUp
{
    FOSCAM_NET_Cleanup();
    FOSCAM_NVR_Cleanup();
}

- (void)addPBObserver:(id<DispatchProtocal>)observer
{
    @synchronized(self){
        [self.pbObservers addObject:observer];
    }
}

- (void)removePBObserver:(id<DispatchProtocal>)observer
{
    @synchronized(self){
        [self.pbObservers removeObject:observer];
    }
}

- (void)addObserver:(id<DispatchProtocal>)observer
{
    @synchronized(self){
        [self.observers addObject:observer];
    }
}

- (void)removeObserver:(id<DispatchProtocal>)observer
{
     @synchronized(self){
         [self.observers removeObject:observer];
     }
}


//同步进行登录测试
+ (long)loginDeviceSync :(CDevice *)device channelCnt :(int *)chnCnt result :(int *)result;
{
    *result = FOSCMDRET_FAILD;
    //进行登进登出操作，查看设备是否在线
    LOGIN_DATA loginData;
    loginData.port          = device.port;
    loginData.connectType   = [device.serialNumber isEqualToString:@""]? FOSCNTYPE_IP : FOSCNTYPE_P2P;
    
    NSArray *srcs = @[device.userName,device.userPsw,device.ip,device.serialNumber,device.macAddress];
    char *dests[5] = {loginData.user,loginData.psw,loginData.ip,loginData.uid,loginData.mac};
    int  maxLen[5] = {128,128,128,32,20};
    
    
    for (int i = 0; i < 5; i++) {
        BOOL cpyRet = [srcs[i] getCString:dests[i] maxLength:maxLen[i] encoding:NSASCIIStringEncoding];
        
        if (!cpyRet) {
            NSLog(@"detected buffer overflow");
            return -1;
        }
    }
    
    long userId = -1;
    switch (device.type) {
        case IPC: {
            userId = FOSCAM_NET_Login(&loginData);
            *chnCnt = (userId >= 0)? 1 : 0;
            *result = loginData.result;
        }
            break;

        case NVR: {
            userId = FOSCAM_NVR_Login(&loginData);
            *chnCnt = (userId >= 0)? FOSCAM_NVR_GetChannelCount(userId):0;
            *result = loginData.result;
        }
            break;
            
        default:
            break;
    }
    
    return userId;
}

+ (void)logoutDeviceSync :(CDevice *)device withUserId :(long)userId
{
    switch (device.type) {
        case IPC:
            FOSCAM_NET_Logout(userId);
            break;
            
        case NVR:
            FOSCAM_NVR_Logout(userId);
            break;
            
        default:
            break;
    }
}

+ (NSString *)foscamReturnMessage :(FOSCMD_RESULT)code
{
    switch (code) {
        case FOSCMDRET_OK:
            return NSLocalizedString(@"success", nil);
            
        case FOSCMDRET_FAILD:
            return NSLocalizedString(@"Failed", nil);
        
        case FOSUSRRET_USRNAMEORPWD_ERR:
        case FOSUSRRET_USRPWD_ERR:
            return NSLocalizedString(@"user name or password is incorrect", nil);
            
        case FOSCMDRET_EXCEEDMAXUSR:
            return NSLocalizedString(@"maximum number of users exceeded", nil);
            
        case FOSCMDRET_NO_PERMITTION:
            return NSLocalizedString(@"no permition", nil);
            
        case FOSCMDRET_UNSUPPORT:
            return NSLocalizedString(@"unsupport", nil);
            
        case FOSCMDRET_BUFFULL:
            return NSLocalizedString(@"buffer full", nil);
            
        case FOSCMDRET_ARGS_ERR:
            return NSLocalizedString(@"parameter error", nil);
            
        case FOSCMDRET_NOLOGIN:
            return NSLocalizedString(@"no login", nil);
            
        case FOSCMDRET_NOONLINE:
            return NSLocalizedString(@"the device is offline", nil);
            
        case FOSCMDRET_ACCESSDENY:
            return NSLocalizedString(@"access deny", nil);
            
        case FOSCMDRET_DATAPARSEERR:
            return NSLocalizedString(@"data parser error", nil);
            
        case FOSCMDRET_USRNOTEXIST:
            return NSLocalizedString(@"user not exist", nil);
            
        case FOSCMDRET_SYSBUSY:
            return NSLocalizedString(@"system busy", nil);
            
        case FOSCMDRET_NEED_SET_PASSWORD:
            return NSLocalizedString(@"need set password", nil);
            
        case FOSCMDRET_USR_LOCKED:
            return NSLocalizedString(@"locked", nil);
            
        case FOSCMDRET_APITIMEERR:
            return NSLocalizedString(@"api timeout", nil);
            
        case FOSCMDRET_INTERFACE_CANCEL_BYUSR:
            return NSLocalizedString(@"interface cacel by user", nil);
            
        case FOSCMDRET_TIMEOUT:
            return NSLocalizedString(@"time out", nil);
            
        case FOSCMDRET_HANDLEERR:
            return NSLocalizedString(@"handle error", nil);
            
        case FOSCMDRET_UNKNOW:
        default:
            return NSLocalizedString(@"unknow error", nil);
    }
}

+ (bool)modifyDeviceLoginInfo :(CDevice *)device
                   withUserId :(long)userId
                         user :(NSString *)user
                          psw :(NSString *)pwd
{
    const int maxLength = 128;
    char	buf2[maxLength] = {0};
    char    buf4[maxLength] = {0};
    
    [user getCString:buf2 maxLength:maxLength encoding:NSASCIIStringEncoding];
    [pwd getCString:buf4 maxLength:maxLength encoding:NSASCIIStringEncoding];
    
    switch (device.type) {
        case IPC:
            return FOSCAM_NET_ModifyLoginInfo(userId,buf2,buf4);
            
        case NVR: {
            int len = 1024;
            char xml[len];
            
            if (FOSCAM_NVR_ModifyLoginInfo(userId, buf2, buf4, xml, &len)) {
                NSError *err = nil;
                NSDictionary *dict = [XMLHelper parserCGIXml:[NSString stringWithCString:xml encoding:NSASCIIStringEncoding] error:&err];
                
                if (!err) {
                    NSNumber *result = [dict valueForKey:KEY_XML_RESULT];
                    return result && (result.intValue == 0);
                }
            }
        }
            break;
        default:
            break;
    }
    
    return false;
}


//异步进行登录测试
+ (void)testDeviceValid :(CDevice *)device withCompletingHandle :(void (^)(BOOL state,int code))complete
{
    //异步提交任务到队列中
    dispatch_queue_t bkQueue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bkQueue, ^{
        //进行登进登出操作，查看设备是否在线
        LOGIN_DATA loginData;
        
        loginData.port          = device.port;
        loginData.connectType   = [device.serialNumber isEqualToString:@""]? FOSCNTYPE_IP : FOSCNTYPE_P2P;
        strcpy(loginData.user, [device.userName UTF8String]);
        strcpy(loginData.psw, [device.userPsw UTF8String]);
        strcpy(loginData.ip, [device.ip UTF8String]);
        strcpy(loginData.uid, [device.serialNumber UTF8String]);
        strcpy(loginData.mac, [device.macAddress UTF8String]);
        
        
        long user_id = -1;
        switch (device.type) {
            case IPC: {
                user_id = FOSCAM_NET_Login(&loginData);
                FOSCAM_NET_Logout(user_id);
            }
                break;
                
            case NVR: {
                user_id = FOSCAM_NVR_Login(&loginData);
                FOSCAM_NVR_Logout(user_id);
            }
                break;
            default:
                break;
        }
        
        if (debug) {
            NSLog(@"设备中心:正在对设备%d,进行异步登陆测试结果%d",device.uniqueId,user_id>=0);
        }
        
        complete(user_id >= 0,loginData.result);
    });
}

+ (void)searchDevicesWithCompletingHandle :(void (^)(NSArray *devices))complete
{
    //We call the method in another thread to avoid block the ui thread.
    dispatch_queue_t bkQueue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bkQueue, ^{
        long                numOfDevice = 256 ;
        FOSDISCOVERY_NODE   discoveries[numOfDevice];
        NSStringEncoding    enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        
        if (FOSCAM_NET_Search(discoveries,  &numOfDevice)) {
            NSLog(@"Foscam_net_search called success! found %ld devices",numOfDevice);
            //The numOfDevice returns the device we have discorvered.
            NSMutableArray *devices = [[NSMutableArray alloc] init];//FOS_NET_DISCOVERY_NODE node[numOfDevice];
            
            for (int idx = 0; idx < numOfDevice; idx++) {
                struct in_addr      ip;
                FOSDISCOVERY_NODE   discovery   = discoveries[idx];
                ip.s_addr                       = discovery.ip;
                DEVICE_TYPE         dev_type    = IPC;
                int                 channelCnt  = 1;
                
                switch (discovery.type) {
                    case FOSIPC_H264:
                    case FOSIPC_MJ:
                        dev_type = IPC;
                        break;
                    case FOSNVR:
                        dev_type = NVR;
                        channelCnt = 4;
                        break;
                    case FOS_UNKNOW:
                    default:
                        dev_type = UNKNOW;
                        break;
                }
                
                if (dev_type != UNKNOW) {
                    [devices addObject: [[CDevice alloc] initWithUniqueId:-1
                                                                     name:[NSString stringWithCString:discovery.name encoding:enc]
                                                                     type:dev_type
                                                                       ip:[NSString stringWithCString:inet_ntoa(ip) encoding:NSASCIIStringEncoding]
                                                                     port:discovery.port
                                                                 userName:@"admin"
                                                                  userPsw:@""
                                                                 rtspPort:discovery.mediaPort
                                                               macAddress:[NSString stringWithCString:discovery.mac encoding:NSASCIIStringEncoding]
                                                             serialNumber:[NSString stringWithCString:discovery.uid encoding:NSASCIIStringEncoding]
                                                             decorderType:0
                                                             channelCount:channelCnt
                                                                    Group:nil]];
                }
            }
            
            complete([NSArray arrayWithArray:devices]);
        } else {
            
            if (debug) {
                NSLog(@"Error occurred while discovering devices");
            }
        }
    });
}


/*-------------------------Interface With NVR && IPC--------------------------*/
#pragma mark - private fuctions

//登录设备，并返回user id
- (long)loginDevice :(CDevice *)dev withUserInfo :(DeviceUser *)user
{
    //检查设备
    if (!dev || dev.uniqueId < 0)
        return -1;
    
    //准备登录
    LOGIN_DATA loginData;
    loginData.port          = dev.port;
    loginData.connectType   = [dev.serialNumber isEqualToString:@""]? FOSCNTYPE_IP : FOSCNTYPE_P2P;
    strcpy(loginData.user, [dev.userName UTF8String]);
    strcpy(loginData.psw, [dev.userPsw UTF8String]);
    strcpy(loginData.ip, [dev.ip UTF8String]);
    strcpy(loginData.uid, [dev.serialNumber UTF8String]);
    strcpy(loginData.mac, [dev.macAddress UTF8String]);
    
    long userId = -1;
    switch (dev.type) {
        case IPC:
            userId = FOSCAM_NET_Login(&loginData);
            FOSCAM_NET_SetEventCB(userId, ipcEventCallback, (__bridge void *)(user));
            break;
        case NVR:
            userId = FOSCAM_NVR_Login(&loginData);
            FOSCAM_NVR_SetEventCB(userId, nvrEventCallback,(__bridge void *)(user));
            break;
        default:
            break;
    }
    
    return userId;
}

//登出设备
- (void)logoutDevice :(CDevice *)dev
          withUserId :(long)userId
{
    //检查设备
    if (!dev || dev.uniqueId < 0 || userId < 0)
        return;
    
    switch (dev.type) {
        case IPC:
            FOSCAM_NET_Logout(userId);
            break;
        case NVR:
            FOSCAM_NVR_Logout(userId);
            break;
        default:
            break;
    }
}

- (void)checkoutIpcAbilityWithUser :(DeviceUser *)user
{
    if (user && user.userId >= 0) {
        FOSCAM_NET_CONFIG config;
        FOS_PRODUCTALLINFO info;
        config.info = &info;
        
        if (FOSCAM_NET_GetConfig(user.userId, FOSCAM_NET_CONFIG_PRODUCT_INFO, &config)) {
            FosAbility *ability = [[FosAbility alloc] initWithProductAllInfo:&info];
            [user.deviceNode.abilities setValue:ability forKey:@"0"];
        }
    }
}

//预览设备，并返回real handle
- (long)realPlayDevice :(CDevice *)dev
            withUserId :(long)userId
            streamType :(FOSSTREAM_TYPE)type
              realInfo :(RealInfo *)info
{
    long realHandle = -1;
    
    if (dev && (dev.uniqueId >= 0)) {
        //检查设备
        if (info && (info.chnIdx >= 0) && (info.chnIdx < dev.channelCount)) {
            //检查通道
            //准备预览
            void            *userInfo   = (__bridge void *)(info);
            PREVIEW_INFO    previewInfo;
            
            previewInfo.streamType      = type;
            previewInfo.channel         = info.chnIdx;
            
            switch (dev.type) {
                case IPC:
                    realHandle = FOSCAM_NET_RealPlay(userId, &previewInfo, (NET_DataCallBack)dataCallback, userInfo);
                    break;
                case NVR:
                    realHandle = FOSCAM_NVR_RealPlay(userId, &previewInfo, (FOSCAM_NVR_DataCB)dataCallback, userInfo);
                    break;
                default:
                    break;
            }
        }
    }
    return realHandle;
}

//停止预览设备
- (void)stopRealPlayDevice :(CDevice *)dev
                withUserId :(long)userId
            withRealHandle :(long)hReal
{
    //检查设备
    if (!dev || dev.uniqueId < 0 || hReal < 0)
        return;
    
    if (userId < 0 || hReal < 0)
        return;
    
    switch (dev.type) {
        case IPC:
            FOSCAM_NET_StopRealPlay(userId);
            break;
        case NVR:
            FOSCAM_NVR_StopRealPlay(userId, hReal);
            break;
        default:
            break;
    }
}

#pragma mark - public api
- (void)startRealTimeVideoFromDevice :(CDevice *)device
                             channel :(int)chn
                          streamType :(FOSSTREAM_TYPE)streamType
                               queue :(dispatch_queue_t)queue
                withCompletionHandle :(void (^)(BOOL success))complete
{
    if (debug) {
        NSLog(@"Running in %@,'%@'.device.type=%ld,chn=%d",[self class],NSStringFromSelector(_cmd),(long)device.type,chn);
    }
    
    if (!device || device.uniqueId < 0) return;
    if (chn < 0 || chn >= device.channelCount) return;
    
    //互斥访问设备表
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    
    if (!node) {
        //结点不存在，添加记录
        NSMutableArray *chns = [[NSMutableArray alloc] init];
        for (int i = 0; i < device.channelCount; i++) {
            [chns addObject:[NSNumber numberWithLong:[(Channel *)device.children[i] uniqueId]]];
        }
        node = [[DeviceNode alloc] initWithDeviceId:device.uniqueId
                                           channels:chns
                                            devType:device.type];
        [self.channelMap setValue:node forKey:key];
    }
    [self.mutex unlock];
    
    //异步提交到任务队列中
    dispatch_async(node.queue, ^{
    
        BOOL openable = NO;
        if (device.type == IPC)
            openable = node.isOnline;
        else if (device.type == NVR)
            openable = node.isOnline && (node.chnEnable & (1 << chn));

        BOOL success = NO;
        if (openable) {
            /*
             *1、遍历所有的用户，直到发现一个用户，该用户这一路通道引用计数为0，或者正在播放相同码
             *流类型的视频.
             *2、如果找到了这样的用户，还要查看这个用户是否已经用来播放实时视频了.(如果没有，在成
             *功打开实时视频的时候,需要对该用户增加引用计数，代表该用户正在被实时视频所占用)
             */
            DeviceUser  *curUser    = nil;
            BOOL        isOpenedForRealPlay = NO;
            
            for (DeviceUser *user in node.users) {
                
                assert(chn < user.realInfos.count);
                assert(user.userId >= 0);
    
                //找到有效用户(已登录)
                RealInfo *realInfo = user.realInfos[chn];
                assert(realInfo.refCnt >= 0);
                
                
                if (realInfo.streamType == streamType) {
                    curUser = user;
                    
                    //查看该用户是否已经在使用
                    for (RealInfo *ri in curUser.realInfos) {
                        if (ri.refCnt > 0) {
                            isOpenedForRealPlay = YES;
                            break;
                        }
                    }
                    break;
                }
            }
            
            if (!curUser) {
                for (DeviceUser *user in node.users) {
                    RealInfo *realInfo = user.realInfos[chn];
                    if (realInfo.refCnt == 0) {
                        curUser = user;
                        
                        //查看该用户是否已经在使用
                        for (RealInfo *ri in curUser.realInfos) {
                            if (ri.refCnt > 0) {
                                isOpenedForRealPlay = YES;
                                break;
                            }
                        }
                        break;
                    }
                }
            }
            
            /*
             *1、如果存在当前用户，查看是否已经打开了实时视频流,如果没有打开，通知底层打开实时视频
             *流(增加这一通道的引用计数，记录hReal、streamType,如果此用户尚未打开实时视频流，需
             *要对该用户增加一次登陆引用),如果发现该路已经在播放实时视频流了，增加该路实时视频流的
             *引用.
             *2、如果不存在这样的用户，需要新建一个用户(新建的用户，自动对该用户登陆引用计数加1),
             *通知底层，对该新用户做登陆操作，如果登陆成功，如果当前设备没有用户在使用且设备类型是
             *(nvr)，增加该用户的登陆引用计数，用作长连接.通知底层对该用户尝试打开实时视频流,如果
             *成功:该路视频引用计数增加1,并且记录下hReal,streamType,否则:减少对该用户的登陆引用
             *计数.最后查看这个新用户的登陆引用计数.如果为0.通知底层，做登出操作，如果大于0,添加
             *该用户到设备结点下.
             */
            RealInfo *realInfo = nil;
            if (curUser) {
                //查看通道是否在预览
                realInfo = curUser.realInfos[chn];
                if (realInfo.hReal < 0) {
                    //尝试预览
                    long realHandle = [self realPlayDevice:device withUserId:curUser.userId streamType:streamType realInfo:realInfo];
                    if (realHandle >= 0) {
                        realInfo.hReal = realHandle;
                        realInfo.streamType = streamType;
                        realInfo.refCnt += 1;
                        
                        if (!isOpenedForRealPlay) {
                            curUser.refCnt += 1;
                        }
                    }
                }
                else {
                    ++realInfo.refCnt;
                }
            }
            else {
                //准备新用户
                DeviceUser *newUser = [[DeviceUser alloc] initWithDeviceNode:node];
                newUser.userId = [self loginDevice:device withUserInfo:newUser];
                
                if (newUser.userId >= 0) {
                    newUser.deviceNode.online = YES;
                    //是否做长连接
                    if ((device.type == NVR) && (node.users.count == 0)) {
                        newUser.refCnt++;
                    }
                    
                    //尝试预览
                    realInfo = newUser.realInfos[chn];
                    long realHandle = [self realPlayDevice:device withUserId:newUser.userId streamType:streamType realInfo:realInfo];
                    if (realHandle >= 0) {
                        //预览成功了，
                        realInfo.hReal = realHandle;
                        realInfo.streamType = streamType;
                        realInfo.refCnt += 1;
                    }
                    else {
                        //考虑预览失败
                        newUser.refCnt--;
                    }
                    
                    //查看该用户的登陆引用计数
                    if (newUser.refCnt == 0)
                        [self logoutDevice:device withUserId:newUser.userId];
                    else {
                        [node.users addObject:newUser];
                        //获取能力集
                        if (device.type == IPC) {
                            [self checkoutIpcAbilityWithUser:newUser];
                        }
                    }
                }
            }
            
            success = (realInfo.refCnt > 0);
        }
        
        [self traceDeviceState:node];
        dispatch_async(queue, ^{
            complete(success);
        });
    });
}


- (void)stopRealTimeVideoFromDevice :(CDevice *)device
                            channel :(int)chn
                         streamType :(FOSSTREAM_TYPE)streamType
{
    if (debug) {
        NSLog(@"Running in %@,'%@'",[self class],NSStringFromSelector(_cmd));
    }
    
    if (!device || device.uniqueId < 0) return;
    if (chn < 0 || chn >= device.channelCount) return;
    
    //互斥查找设备表
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    if (node) {
        dispatch_async(node.queue, ^{
            /*
             *1、遍历结点下的所有用户，找到正在播放视频的通道
             *2、减少该通道的引用计数，当引用计数为0的时候，通知底层做登出操作.
             *3、产看该用户的其它通道，是否在播放实时流，如果没有，该用户的登陆引用计数减1,
             *4、如果该用户的登陆引用计数为0，通知底层做登出操作，同时从设备结点下移除该用户
             */
            DeviceUser  *curUser = nil;
            for (DeviceUser *user in node.users) {
                
                if (user.userId < 0)
                    continue;
                assert(chn < user.realInfos.count);
                RealInfo *realInfo = user.realInfos[chn];
                
                if (realInfo.hReal >= 0 && realInfo.streamType == streamType) {
                    assert(realInfo.refCnt > 0);
                    //存在空闲通道
                    curUser = user;
                    //减少该路引用
                    if (--realInfo.refCnt == 0) {
                        //准备停止实时播放
                        [self stopRealPlayDevice:device withUserId:curUser.userId withRealHandle:realInfo.hReal];
                        realInfo.hReal = -1;
                        
                        //查看该用户是否已经停止实时流
                        BOOL isOpenRealPlay = NO;
                        for (RealInfo *realInfo in curUser.realInfos) {
                            if (realInfo.hReal >= 0) {
                                isOpenRealPlay = YES;
                                break;
                            }
                        }
                        
                        //如果已经没有通道进行实时流了，减少该用户的登陆引用计数
                        if (!isOpenRealPlay) {
                            curUser.refCnt--;
                        }
                        
                        if (0 == curUser.refCnt) {
                            [self logoutDevice:device withUserId:curUser.userId];
                            [node.users removeObject:curUser];
                        }
                    }
                    break;
                }
            }
            [self traceDeviceState:node];
        });
    }
}

#pragma mark - trace device state
- (void)traceDeviceState :(DeviceNode *)node
{
#if debug
    NSString *head = @"===========================================Dispatch Center Info===========================================";
    NSString *tail = @"==========================================================================================================";
    NSString *content = [NSString stringWithFormat:@"\
--->dev_id   :%d\n\
--->dev_type :%d\n\
--->user_cnt :%ld\n\
--->online   :%d\n",node.deviceId,node.devType,node.users.count,node.isOnline];
    
    NSString *userInfo = @"";
    for (DeviceUser *user in node.users) {
        userInfo = [NSString stringWithFormat:@"%@--->user%ld\n\
------>refCnt:%d\n",userInfo,user.userId,user.refCnt];
        
        NSString *chnInfo = @"";
        for (RealInfo *realInfo in user.realInfos) {
            chnInfo = [NSString stringWithFormat:@"%@------>real%ld\n\
--------->refCnt:%d\n\
--------->streamType:%d\n",chnInfo,realInfo.hReal,realInfo.refCnt,realInfo.streamType];
        }
        
        userInfo = [userInfo stringByAppendingString:chnInfo];
    }
    
    content = [content stringByAppendingString:userInfo];
    NSLog(@"\n\n%@\n%@\n%@\n\n",head,content,tail);
#endif
}


#pragma mark - playback
- (BOOL)startPlaybackVideoFromDevice :(CDevice *)device
                            channels :(int)channels
                                  st :(unsigned)st
                                  et :(unsigned)et
{
    if (!device || device.uniqueId < 0 || device.type != NVR) return NO;
    if (channels <= 0) return NO;
    
    //互斥访问设备表
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    
    if (!node) {
        //结点不存在，添加记录
        NSMutableArray *chns = [[NSMutableArray alloc] init];
        for (int i = 0; i < device.channelCount; i++) {
            [chns addObject:[NSNumber numberWithLong:[(Channel *)device.children[i] uniqueId]]];
        }
        node = [[DeviceNode alloc] initWithDeviceId:device.uniqueId
                                           channels:chns
                                            devType:device.type];
        [self.channelMap setValue:node forKey:key];
    }
    [self.mutex unlock];
    
    //同步提交到任务队列中
    __block BOOL success = NO;
    if (node) {
        dispatch_sync(node.queue, ^{
            //寻找空闲用户
            DeviceUser  *pbUser    = nil;
            for (DeviceUser *user in node.users) {
                assert(user.userId >= 0);
        
                if (user.hPlayback < 0) {
                    pbUser = user;
                    break;
                }
            }
            
            if (pbUser) {
                PLAYBACK_INFO pbInfo;
                pbInfo.channels = channels;
                pbInfo.st = st;
                pbInfo.et = et;
                pbInfo.offset = 0;
                //尝试打开回放
                long hPlayback = FOSCAM_NVR_StatPlayback(pbUser.userId, &pbInfo, (FOSCAM_NVR_FILEDataCB)fileDataCallback,(FOSCAM_NVR_FILEEventCB)fileEventCallback,(__bridge void *)(pbUser));
                if (hPlayback >= 0) {
                    pbUser.hPlayback = hPlayback;
                    success = YES;
                }
            }
        });
    }
    
    return success;
}

- (void)sendPlaybackCmd :(FOSNVR_PBCMD)cmd value :(int)value forDevice :(CDevice *)device
{
    if (!device || device.uniqueId < 0) return;
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    if (node) {
        dispatch_async(node.queue, ^{
            DeviceUser  *curUser = nil;
            for (DeviceUser *user in node.users) {
                //此处断言用户必定已经登录,并且通道号不越界
                assert(user.userId >= 0);
                
                if (user.hPlayback >= 0) {
                    //存在回放用户
                    curUser = user;
                    break;
                }
            }
            
            if (curUser) {
                FOSCAM_NVR_SendPlaybackCmd(curUser.userId, curUser.hPlayback,cmd, value);
            }
        });
    }
}

- (void)stopPlaybackVideoFromDevice :(CDevice *)device
{
    if (!device || device.uniqueId < 0) return;
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    if (node) {
        dispatch_async(node.queue, ^{
            DeviceUser  *curUser = nil;
            for (DeviceUser *user in node.users) {
                assert(user.userId >= 0);
                if (user.hPlayback >= 0) {
                    curUser = user;
                    break;
                }
            }
            
            if (curUser) {
                FOSCAM_NVR_StopPlayback(curUser.userId, curUser.hPlayback);
                curUser.hPlayback = -1;
            }
        });
    }
}

- (int)searchRecordFilesWithStartTime :(long long)st
                              endTime :(long long)et
                                 type :(FOSNVR_RECORDTYPE)type
                             channels :(int)chs
                           fromDevice :(CDevice *)dev
{
    __block int nodeCnt = 0;
    if (dev) {
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%d",dev.uniqueId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        [self.mutex unlock];
        
        
        dispatch_sync(node.queue, ^{
            //向第一个用户发送ptz命令
            if (node.users.count > 0) {
                DeviceUser *curUser = node.users[0];
                //查看该用户是否连接上
                if (curUser.userId >= 0 && node.isOnline) {
                    if (!FOSCAM_NVR_SearchRecordFiles(curUser.userId,
                                                      chs,
                                                      st,
                                                      et,
                                                      type,
                                                      &nodeCnt)) {
                        nodeCnt = 0;
                    }
                }
            }
        });
    }
    
    return nodeCnt;
}

- (BOOL)getRecordNodeInfo :(FOSNVR_RecordNode *)recordNode
                    atIdx :(int)idx
               fromDevice :(CDevice *)dev
{
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",dev.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    __block BOOL success = NO;
    
    if (dev) {
        __block FOSNVR_RecordNode tmp;
        dispatch_sync(node.queue, ^{
            //向第一个用户发送ptz命令
            if (node.users.count > 0) {
                DeviceUser *curUser = node.users[0];
                //查看该用户是否连接上
                if (curUser.userId >= 0 && node.isOnline) {
                    success = FOSCAM_NVR_GetRecordNodeInfo(curUser.userId, idx, &tmp);
                }
            }
        });
        
        if (success) {
            *recordNode = tmp;
        }
    }
    
    return success;
}

- (BOOL)getIpcList :(FOSNVR_IpcNode *)ipcNode size :(int *)size fromNvr :(CDevice *)dev
{
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",dev.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
     __block BOOL success = NO;
    
    if (node) {
        dispatch_sync(node.queue, ^{
            //向第一个用户发送ptz命令
            if (node.users.count > 0) {
                DeviceUser *curUser = node.users[0];
                //查看该用户是否连接上
                if (curUser.userId >= 0 && node.isOnline) {
                    success = FOSCAM_NVR_GetIPCList(curUser.userId, ipcNode, size);
                }
            }
        });
    }
    
    return success;
}

#pragma mark - download
- (void)setDownloadPath :(char *)path forDevice:(CDevice *)device
{
    if (!device || device.uniqueId < 0) return;
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    if (node) {
        dispatch_sync(node.queue, ^{
            if (node.users.count > 0) {
                DeviceUser  *curUser = [node.users firstObject];
                if (curUser.userId >= 0) {
                    FOSCAM_NVR_SetDownloadPath(curUser.userId, path);
                }
            }
        });
    }
}

- (BOOL)downloadRecordFile :(NSValue *)val count :(int)cnt fromDevice:(CDevice *)device
{
    if (!device || device.uniqueId < 0) return NO;
    
    //互斥查找设备表
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    __block BOOL success = NO;
    __block FOSNVR_RecordNode recordNode;
    [val getValue:&recordNode];
    if (node) {
        dispatch_sync(node.queue, ^{
            if (node.users.count > 0) {
                DeviceUser  *curUser = [node.users firstObject];
                if (curUser && (curUser.userId >= 0)) {
                    success = FOSCAM_NVR_DownloadRecord(curUser.userId, &recordNode, cnt);
                }
            }
        });
    }
    
    return success;
}

- (void)downloadCancel:(CDevice *)device
{
    if (!device || device.uniqueId < 0) return;
    
    //互斥查找设备表
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    if (node) {
        dispatch_sync(node.queue, ^{
            
            if (node.users.count > 0) {
                DeviceUser  *curUser = [node.users firstObject];
                if (curUser.userId >= 0) {
                    FOSCAM_NVR_DownLoadCancel(curUser.userId);
                }
            }
        });
    }
}


#pragma mark - PTZ
- (int)sendPTZControlCommand:(PTZ_CMD)ptzCommand
                     toDevice:(CDevice *)device
                      channel:(int)chn
{
    if (!device) {
        return -1;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    __block int result = 0;
    //向第一个用户发送ptz命令
    dispatch_sync(node.queue, ^{
        //是否有用户登录
        if (node.users.count > 0) {
            DeviceUser *curUser = node.users[0];
            //此处断言该用户登录成功
            assert(curUser.userId >= 0);
            //查看该用户是否连接上
            if (node.isOnline) {
                switch (device.type) {
                    case IPC:
                        result = FOSCAM_NET_PTZ(curUser.userId, ptzCommand);
                        break;
                    case NVR: {
                        if (node.chnEnable & (1 << chn)) {
                            FOSCAM_NVR_PTZ(curUser.userId, chn, ptzCommand);
                        }
                    }
                        break;
                    default:
                        break;
                }
            }
        }
    });
    
    return result;
}

#pragma mark - set & get config
- (void)beginConfigDevice :(CDevice *)device
                    queue :(dispatch_queue_t)queue
     withCompletionHandle :(void (^)(BOOL success))complete
{
    TRACE
    if (device) {
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        
        if (!node) {
            //结点不存在，添加记录
            NSMutableArray *chns = [[NSMutableArray alloc] init];
            for (int i = 0; i < device.channelCount; i++) {
                [chns addObject:[NSNumber numberWithLong:[(Channel *)device.children[i] uniqueId]]];
            }
            node = [[DeviceNode alloc] initWithDeviceId:device.uniqueId
                                               channels:chns
                                                devType:device.type];
            [self.channelMap setValue:node forKey:key];
        }
        [self.mutex unlock];
        
        dispatch_async(node.queue, ^{
            //查看用户登录数
            BOOL success = NO;
            DeviceUser *curUser = nil;
            
            if (node.users.count == 0) {
                DeviceUser *newUser = [[DeviceUser alloc] initWithDeviceNode:node];
                newUser.userId  = [self loginDevice:device withUserInfo:newUser];
                
                if (newUser.userId >= 0) {
                    success = YES;
                    node.online = YES;
                    [node.users addObject:newUser];
                    if (device.type == IPC) {
                        [self checkoutIpcAbilityWithUser:newUser];
                    }
                }
            } else {
                //已经有用户登录了,对第一个用户增加引用
                success = YES;
                curUser = node.users[0];
                curUser.refCnt += 1;
            }
            
            dispatch_async(queue, ^{
                complete(success);
            });
        });
    }
}

- (void)endConfigDevice :(CDevice *)device
{
    if (device) {
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        [self.mutex unlock];
        
        dispatch_async(node.queue, ^{
            DeviceUser *curUser = nil;
            
            if (node.users.count > 0) {
                curUser = node.users[0];
                //查看该用户是否已经没有在引用了
                if (--curUser.refCnt == 0) {
                    //注销该用户
                    [self logoutDevice:device withUserId:curUser.userId];
                    [node.users removeObject:curUser];
                }
            }
            
            [self traceDeviceState:node];
        });
    }
}


- (BOOL)getConfig :(void *)config
          forType :(int)type
       fromDevice :(CDevice *)device
{
    __block BOOL        success     = NO;
    
    if (device) {
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        [self.mutex unlock];
        
        //这里要同步等待
        dispatch_sync(node.queue, ^{
            //向第一个用户发送ptz命令
            if (node.users.count > 0) {
                DeviceUser *curUser = node.users[0];
                //查看该用户是否连接上
                if (curUser.userId >= 0 && node.isOnline) {
                    switch (device.type) {
                        case IPC:
                            success = FOSCAM_NET_GetConfig(curUser.userId, type, config);
                            break;
                        case NVR:
                            success = FOSCAM_NVR_GetConfig(curUser.userId, type, config);
                            break;
                        default:
                            break;
                    }
                }
            }
        });
    }
    
    return success;
}

- (BOOL)setConfig :(void *)config
          forType :(int)type
         toDevice :(CDevice *)device
{
    __block BOOL        success     = NO;
    
    if (device) {
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        [self.mutex unlock];
        
        //这里要同步等待
        dispatch_sync(node.queue, ^{
            //向第一个用户发送ptz命令
            if (node.users.count > 0) {
                DeviceUser *curUser = node.users[0];
                //查看该用户是否连接上
                if (curUser.userId >= 0 && node.isOnline) {
                    switch (device.type) {
                        case IPC:
                            success = FOSCAM_NET_SetConfig(curUser.userId, type, config);
                            break;
                        case NVR:
                            success = FOSCAM_NVR_SetConfig(curUser.userId, type, config);
                            break;
                        default:
                            break;
                    }
                }
            }
        });
    }
    
    return success;
}

#pragma mark - talk
//对讲功能暂时仅支持IPC
- (BOOL)switchTalking :(BOOL)state device :(CDevice *)dev channel :(int)chn
{
    __block BOOL        success     = NO;
    
    if (dev && dev.type == IPC) {
        
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%d",dev.uniqueId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        [self.mutex unlock];
        
        if (node) {
            //这里要同步等待
            dispatch_sync(node.queue, ^{
                //向第一个用户发送ptz命令
                if (node.users.count > 0) {
                    DeviceUser *curUser = node.users[0];
                    //查看该用户是否连接上
                    if (curUser.userId >= 0 && node.isOnline) {
                        success = state? FOSCAM_NET_OpenTalk(curUser.userId) : FOSCAM_NET_CloseTalk(curUser.userId);
                    }
                }
            });
        }
    }
    
    return success;
}

- (void)sendTalkingData :(char *)data
                 length :(int)len
               toDevice :(CDevice *)dev
                channel :(int)chn
{
    if (!dev) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%d",dev.uniqueId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    //这里要同步等待
    dispatch_sync(node.queue, ^{
        //向第一个用户发送
        if (node.users.count > 0) {
            DeviceUser *curUser = node.users[0];
            //查看该用户是否连接上
            if (curUser.userId >= 0 && node.isOnline) {
                switch (dev.type) {
                    case IPC:
                        FOSCAM_NET_Talk(curUser.userId, data, len);
                        break;
                    case NVR:
                        break;
                    default:
                        break;
                }
            }
        }
    });
}

#pragma mark - reload
- (void)logoutDevice :(CDevice *)dev needReset :(BOOL)reset
{
    if (debug) {
        NSLog(@"Running in class %@ selector '%@'",self.className,NSStringFromSelector(_cmd));
    }
    
    if (dev) {
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%d",dev.uniqueId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        [self.mutex unlock];
        
        dispatch_async(node.queue, ^{
            for (DeviceUser *user in node.users) {
                [self logoutDevice:dev withUserId:user.userId];
            }
            
            node.online = NO;
            
            //给出通知
            [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_RELOAD_NOTIFICATION
                                                                object:self
                                                              userInfo:@{KEY_EVENT_DEVICE_ID : [NSNumber numberWithLong:node.deviceId]}];
            
            if (reset) {
                [node.users removeAllObjects];
            }
        });
    }
}

- (void)reLoadDevice :(CDevice *)dev withCompletionHandle :(void (^)(BOOL success))complete;
{
    if (debug) {
        NSLog(@"Running in class %@ selector '%@'",self.className,NSStringFromSelector(_cmd));
    }
    
    if (dev) {
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%d",dev.uniqueId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        [self.mutex unlock];
        
        dispatch_async(node.queue, ^{
            
            //重登入
            NSMutableArray *invalidUsers = [NSMutableArray array];
            for (DeviceUser *user in node.users) {
                //恢复登录
                if (user.userId >= 0) {
                    long userId = -1;
                    int ticket = 3;
                    
                    do {
                        
                        usleep(2000000);
                        userId = [self loginDevice:dev withUserInfo:user];
                        ticket--;
                        
                    }while ((ticket > 0) && (userId < 0));
                    
                    user.userId = userId;
                    node.online = (userId >= 0);
                    
                    if (userId >= 0) {
                        //重新实时
                        NSLog(@"重新登录成功!");
                        for (RealInfo *realInfo in user.realInfos) {
                            if (realInfo.hReal >= 0) {
                                long realHandle = [self realPlayDevice:dev
                                                            withUserId:user.userId
                                                            streamType:realInfo.streamType
                                                              realInfo:realInfo];
                                realInfo.hReal = realHandle;
                            }
                        }
                    }
                    else {
                        NSLog(@"重新登录失败!");
                        [invalidUsers addObject:user];
                    }
                    
                    if (debug) {
                        NSLog(@"重新登录设备devId=%d,新的userId=%ld",dev.uniqueId,user.userId);
                    }
                }
            }
            
            //移除所有的无效用户
            [invalidUsers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [node.users removeObject:obj];
            }];

            complete(YES);
        });
    }
}

#pragma mark - private
- (void)doLoginTestWithDevice :(CDevice *)dev node :(DeviceNode *)node
{
    if (debug) {
        NSLog(@"Running in %@,'%@'",[self class],NSStringFromSelector(_cmd));
    }
    
    BOOL isOnline = node.isOnline;
    DeviceUser *newUser = [[DeviceUser alloc] initWithDeviceNode:node];
    newUser.userId = [self loginDevice:dev withUserInfo:newUser];
    
    if (newUser.userId >= 0) {
        switch (dev.type) {
            case IPC:
                FOSCAM_NET_Logout(newUser.userId);
                break;
            case NVR: {
                //对nvr进行操作时，如果还没有用户对其进行引用，这里增加一个用户，保持长期登录.
                //否则，登出新用户
                if (node.users.count == 0) {
                    [node.users addObject:newUser];
                    if (dev.type == IPC) {
                        [self checkoutIpcAbilityWithUser:newUser];
                    }
                }
                else {
                    FOSCAM_NVR_Logout(newUser.userId);
                }
            }
                break;
            default:
                break;
        }
        
        isOnline = YES;
    }
    else {
        isOnline = NO;
    }
    
    //状态是否发生改变
    node.online = isOnline;
}

- (void)onConnectionChangeWithDevId :(long)devId state:(BOOL)state
{
    TRACE
    if (devId >= 0) {
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%ld",devId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        [self.mutex unlock];
        
        BOOL var = state;
        dispatch_async(node.queue, ^{
            node.online = var;
        });
    }
}

- (void)onChannelEnableChangeWithDevId :(long)devId
                       videoCompatible :(FOSNVR_IPCVideoST_Compatible *)compatible
{
    TRACE
    if (devId < 0) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%ld",devId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    FOSNVR_IPCVideoST_Compatible *var = malloc(sizeof(FOSNVR_IPCVideoST_Compatible));
    memcpy(var, compatible, sizeof(FOSNVR_IPCVideoST_Compatible));
    
    dispatch_async(node.queue, ^{
        NSMutableDictionary *userInfo =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:devId],KEY_EVENT_DEVICE_ID, nil];
        
        for (int chn = 0; chn < 32; chn++) {
            FOSNVR_ConnectConfig connectConfig = var->connectcfg[chn];
            BOOL state = (connectConfig.enCh == 1)? (connectConfig.state == 1) : NO;
            BOOL bitEnable = node.chnEnable & (1<<chn);
            
            if (state != bitEnable) {
                node.chnEnable = state? (node.chnEnable | (1 << chn)) : (node.chnEnable & ~(1 << chn));
                [userInfo setValue:[NSNumber numberWithInt:chn] forKey:KEY_EVENT_CHANNEL_ID];
                [userInfo setValue:[NSNumber numberWithInt:state] forKey:KEY_EVENT_CONNECTION_STATE];
                [[NSNotificationCenter defaultCenter] postNotificationName:CONNECTION_STATE_DID_CHANGE_NOTIFICATION
                                                                    object:self
                                                                  userInfo:userInfo];
            }
        }
        
        free(var);
    });
}


- (BOOL)verifyChannel :(int)cId alarmReceivableWithNode :(DeviceNode *)node
{
    TRACE
    BOOL alarmRejected = node.chnAlarmRejected & (1 << cId);
    if (!alarmRejected) {
        //拒绝下1s接收到的报警信号,并在1s后开始接收该通道报警信号
        node.chnAlarmRejected |= 1 << cId;
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ALARM_INTERVAL * NSEC_PER_SEC));
        dispatch_after( when, node.queue, ^{
            node.chnAlarmRejected &= ~(1 << cId);
        });
        
        return YES;
    }
    
    return  NO;
}


- (void)onDevice :(long)dId channel :(int)cId alarmAppearWithNode :(DeviceNode *)node
{
    TRACE
    if ([self verifyChannel:cId alarmReceivableWithNode:node]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ALARM_STATE_DID_CHANGE_NOTIFICATION
                                                            object:self
                                                          userInfo:@{KEY_EVENT_DEVICE_ID  :[NSNumber numberWithLong:dId],
                                                                     KEY_EVENT_CHANNEL_ID :[NSNumber numberWithInt:cId],
                                                                     KEY_ALARM_STATE      :[NSNumber numberWithBool:YES]}];
        
        BOOL bitEnable = node.chnAlarm & (1<<cId);
        if (!bitEnable) {
            node.chnAlarm |= 1 << cId;
            
            dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ALARM_DURATION * NSEC_PER_SEC));
            dispatch_after(when,node.queue,^{
                node.chnAlarm &= ~(1 << cId);
              
                [[NSNotificationCenter defaultCenter] postNotificationName:ALARM_STATE_DID_CHANGE_NOTIFICATION
                                                                    object:self
                                                                  userInfo:@{KEY_EVENT_DEVICE_ID  :[NSNumber numberWithLong:dId],
                                                                             KEY_EVENT_CHANNEL_ID :[NSNumber numberWithInt:cId],
                                                                             KEY_ALARM_STATE      :[NSNumber numberWithBool:NO]}];
            });
        }
    }
}

- (void)onChannelAbilityChangeWithDevId :(long)dId nvrAbility :(FOSNVR_Ability *)nvrAblility
{
    if (dId < 0) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%ld",dId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    FOSNVR_Ability *var = (FOSNVR_Ability *)malloc(sizeof(FOSNVR_Ability));
    memcpy(var, nvrAblility, sizeof(FOSNVR_Ability));
    
    dispatch_async(node.queue, ^{
        FosAbility *ability = [[FosAbility alloc] initWithNvrAbility:var];
        [node.abilities setValue:ability forKey:[NSString stringWithFormat:@"%d",var->chn]];
        
        free(var);
    });
}

- (void)onChannelAlarmAppearWithDevId :(long)dId alarmState :(FOSNVR_AlarmState *)state
{
    if (dId < 0) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%ld",dId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    FOSNVR_AlarmState *var = malloc(sizeof(FOSNVR_AlarmState));
    memcpy(var, state, sizeof(FOSNVR_AlarmState));
    
    dispatch_async(node.queue, ^{
        
        for (int chn = 0; chn < 32; chn++) {
            int mask = 1 << chn;
            if ((mask & var->AlarmIO) ||
                (mask & var->AlarmMV)){
                
                [self onDevice:dId channel:chn alarmAppearWithNode:node];
            }
        }
        
        free(var);
    });
}

- (void)onDeviceAlarmAppearWithId :(long)dId
{
    if (dId < 0) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%ld",dId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    dispatch_async(node.queue, ^{
        [self onDevice:dId channel:0 alarmAppearWithNode:node];
    });
}

- (void)onDeviceImageParamChangeWithId :(long)dId imgParam :(FOSIMAGE *)param
{
    TRACE
    if (dId < 0) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%ld",dId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    NSData *data = [NSData dataWithBytes:param length:sizeof(FOSIMAGE)];
    
    dispatch_async(node.queue, ^{
        NSMutableDictionary *userInfo =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:dId],KEY_EVENT_DEVICE_ID, nil];
        [userInfo setValue:data forKey:KEY_IMAGE_PARAM];
        [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_IMAGE_PARAM_DID_CHANGE_NOTIFICATION
                                                            object:self
                                                          userInfo:userInfo];
    });
}

- (void)onDeviceMirrorFlipChangeWithId :(long)dId mirrorFlip :(FOSMIRRORFLIP *)mirrorFlip
{
    TRACE
    if (dId < 0) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%ld",dId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    NSData *data = [NSData dataWithBytes:mirrorFlip length:sizeof(FOSMIRRORFLIP)];
    
    dispatch_async(node.queue, ^{
        NSMutableDictionary *userInfo =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:dId],KEY_EVENT_DEVICE_ID, nil];
        [userInfo setValue:data forKey:KEY_MIRROR_FLIP];
        [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_MIRROR_FLIP_DID_CHANGE_NOTIFICATION
                                                            object:self
                                                          userInfo:userInfo];
    });
}

- (void)onDevicePowerFrequencyChangeWithId :(long)dId powerFrequency :(FOSPWRFREQ *)pwrfreq
{
    TRACE
    if (dId < 0) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%ld",dId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    NSData *data = [NSData dataWithBytes:pwrfreq length:sizeof(FOSPWRFREQ)];
    dispatch_async(node.queue, ^{
        NSMutableDictionary *userInfo =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:dId],KEY_EVENT_DEVICE_ID, nil];
        [userInfo setValue:data forKey:KEY_PWRFREQ];
        [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_POWER_FREQUENCY_DID_CHANGE_NOTIFICATION
                                                            object:self
                                                          userInfo:userInfo];
    });
}

- (void)onDeviceIRCutStateChangeWithId :(long)dId ircurState :(FOSIRCUTSTATE *)state
{
    TRACE
    if (dId < 0) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%ld",dId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    NSData *data = [NSData dataWithBytes:state length:sizeof(FOSIRCUTSTATE)];
    dispatch_async(node.queue, ^{
        NSMutableDictionary *userInfo =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:dId],KEY_EVENT_DEVICE_ID, nil];
        [userInfo setValue:data forKey:KEY_IRCUT_STATE];
        [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_IRCUT_STATE_DID_CHANGE_NOTIFICATION
                                                            object:self
                                                          userInfo:userInfo];
    });
}


- (void)onDeviceCruiseMapChangeWithId :(long)dId cruiseMap :(FOSCRUISEMAP *)map
{
    TRACE
    if (dId < 0 || map->cnt > FOS_MAX_CURISEMAP_COUNT) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%ld",dId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    NSData *data = [NSData dataWithBytes:map length:sizeof(FOSCRUISEMAP)];
    dispatch_async(node.queue, ^{
        NSMutableDictionary *userInfo =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:dId],KEY_EVENT_DEVICE_ID, nil];
        [userInfo setValue:data forKey:KEY_CRUISE_MAP];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_CRUISE_MAP_DID_CHANGE_NOTIFICATION
                                                            object:self
                                                          userInfo:userInfo];
    });
}

- (void)onDevicePresetPtChangeWithId :(long)dId presetPoint:(FOSPRESETPOINT *)presetPt
{
    TRACE
    if (dId < 0) {
        return;
    }
    
    [self.mutex lock];
    NSString    *key    = [NSString stringWithFormat :@"D%ld",dId];
    DeviceNode  *node   = [self.channelMap valueForKey:key];
    [self.mutex unlock];
    
    NSData *data = [NSData dataWithBytes:presetPt length:sizeof(FOSPRESETPOINT)];
    dispatch_async(node.queue, ^{
        NSMutableDictionary *userInfo =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:dId],KEY_EVENT_DEVICE_ID, nil];
        [userInfo setValue:data forKey:KEY_PRESET_PT];
        [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_PRESET_POINT_DID_CHANGE_NOTIFICATION
                                                            object:self
                                                          userInfo:userInfo];
    });
}

#pragma mark - online test
//测试设备是否在线,主动修改设备在线状态
- (void)testOnlineUseDevice :(CDevice *)device
{
    if (debug) {
        NSLog(@"Running in %@,'%@'",[self class],NSStringFromSelector(_cmd));
    }
    
    if (device) {
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        
        if (!node) {
            //结点不存在，添加记录
            NSMutableArray *chns = [[NSMutableArray alloc] init];
            for (int i = 0; i < device.children.count; i++) {
                [chns addObject:[NSNumber numberWithLong:[(Channel *)device.children[i] uniqueId]]];
            }
            node = [[DeviceNode alloc] initWithDeviceId:device.uniqueId
                                               channels:chns
                                                devType:device.type];
            [self.channelMap setValue:node forKey:key];
        }
        [self.mutex unlock];
        
        dispatch_async(node.queue, ^{
            assert(node.users.count >= 0);
            if (!node.isOnline || (node.users.count == 0)) {
                [self doLoginTestWithDevice:device node:node];
            }
        });
    }
}

#pragma mark - event
//处理IPC网络事件
//仅处理IPC连接状态、报警事件、断线重练事件
- (void)ipcReceivedEvent :(FOSEVET_DATA *)event
                deviceId :(int)devId
{
    if (NULL == event)
        return;
    
    switch (event->id) {
        case NETSTATE_RECONNECTRESULT:
            [self onConnectionChangeWithDevId:devId state:YES];
            break;
            
        case NETSTATE_CONNECTERROR_EVENT_CHG:
            [self onConnectionChangeWithDevId:devId state:NO];
            break;
            
        case ALARM_EVENT_CHG: {
            FOSALARM *alarm = (FOSALARM*)event->data;
            switch(alarm->alarmType)
            {
                case 0: // motion detect
                case 2: // io
                    [self onDeviceAlarmAppearWithId:devId];
                    break;
                case 1: // sound
                case 3: // temperature
                case 4: // humidity
                    break;
            }
        }
            break;
        case IMAGE_EVENT_CHG: {
            FOSIMAGE *imgParam = (FOSIMAGE *)event->data;
            [self onDeviceImageParamChangeWithId:devId imgParam:imgParam];
        }
            break;
        case MIRRORFLIP_EVENT_CHG:{
            FOSMIRRORFLIP *mirrorFlip = (FOSMIRRORFLIP *)event->data;
            [self onDeviceMirrorFlipChangeWithId:devId mirrorFlip:mirrorFlip];
        }
            break;
        case PWRFREQ_EVENT_CHG: {
            FOSPWRFREQ *pwrfreq = (FOSPWRFREQ *)event->data;
            [self onDevicePowerFrequencyChangeWithId:devId powerFrequency:pwrfreq];
        }
            break;
        case IRCUT_EVENT_CHG: {
            FOSIRCUTSTATE *ircutState = (FOSIRCUTSTATE *)event->data;
            [self onDeviceIRCutStateChangeWithId:devId ircurState:ircutState];
        }
            break;
        case CRUISE_EVENT_CHG: {
            FOSCRUISEMAP *cruiseMap = (FOSCRUISEMAP *)event->data;
            [self onDeviceCruiseMapChangeWithId:devId cruiseMap:cruiseMap];
        }
            break;
        case PRESET_EVENT_CHG: {
            FOSPRESETPOINT *presetPt = (FOSPRESETPOINT *)event->data;
            [self onDevicePresetPtChangeWithId:devId presetPoint:presetPt];
        }
            break;
        case GET_ALL_PRODUCT_INFO: {
            //FOS_PRODUCTALLINFO *info = (FOS_PRODUCTALLINFO *)event->data;
            
        }
            break;
        default:
            break;
    }
}

- (void)nvrReceivedPBEvent:(FOSNVR_PBEVENT)event deviceId:(int)devId
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:devId],KEY_EVENT_DEVICE_ID, [NSNumber numberWithInt:event],KEY_EVENT_TYPE,nil];
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:PB_NOTIFICATION
                                                                                         object:self
                                                                                       userInfo:userInfo]];
}

//处理NVR网络事件
//仅处理NVR下通道连接状态、报警事件、断线重连事件
-(void)nvrReceivedEvent :(FOSNVR_EvetData *)event
               deviceId :(int)devId
{
    if (NULL == event)
        return;

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:devId],KEY_EVENT_DEVICE_ID, nil];
    
    switch (event->id) {
        case FOSNVR_EVENT_VIDEO_STATE_CHG:
            [self onChannelEnableChangeWithDevId:devId videoCompatible:(FOSNVR_IPCVideoST_Compatible *)event->data];
            break;
        case FOSNVR_EVENT_ALARM_STATE_CHG:
            [self onChannelAlarmAppearWithDevId:devId alarmState:(FOSNVR_AlarmState *)event->data];
            break;
            
        case FOSNVR_EVENT_NVR_DLRECORD_PROGRESS:{
            NSNotification *aNotific = [NSNotification notificationWithName:RECORD_FILE_DOWNLOAD_PROGRESS_NOTIFICATION
                                                                     object:self
                                                                   userInfo:userInfo];
            FOSNVR_DownloadProgress *dldProgress = (FOSNVR_DownloadProgress *)event->data;
            [userInfo setValue:[NSNumber numberWithFloat:dldProgress->progress] forKey:KEY_PROGRESS];
            [userInfo setValue:[NSNumber numberWithInt:dldProgress->index] forKey:KEY_INDEX];
            [[NSNotificationCenter defaultCenter] postNotification:aNotific];
        }
            break;
        case FOSNVR_EVENT_ABILITY_CHG: {
            [self onChannelAbilityChangeWithDevId:devId nvrAbility:(FOSNVR_Ability *)event->data];
        }
            break;
        default:
            break;
    }

    
}


//接收到来自指定通道的数据，指挥中心完成数据打包和转发
//向每一个接收者发送数据包
- (void)networkReceivedData :(void *)buffer
                     length :(int)length
                        type:(int)type
                  timeStamp :(double)time_stamp
                  channelId :(int)channelId
                 streamType :(FOSSTREAM_TYPE)streamType
                 sourceType :(int)sourceType
{
    //test code
    //NSLog(@"Frame With Size %d Did Recieve",length);
    //Report
    @synchronized(self) {
        NSArray *observers = nil;
        switch (sourceType) {
            case 0:
                observers = self.observers;
                break;
            case 1:
                observers = self.pbObservers;
                break;
            default:
                break;
        }
        
        for (id<DispatchProtocal> observer in observers) {
            if ([observer respondsToSelector:@selector(didRecivedData:length:type:timeStamp:channelId:streamType:)]) {
                [observer didRecivedData:buffer
                                  length:length
                                    type:type
                               timeStamp:time_stamp
                               channelId:channelId
                              streamType:streamType];
            }
        }
    }
//    if (debug && type == DATA_TYPE_VIDEO_H264) {
//        char test1[5];
//        [data getBytes:test1 range:NSMakeRange(0, 5)];
//        NSLog(@"接收到ChannelID = %d的数据,(%d,%d,%d,%d,%d),长度%lu",channelId,test1[0],test1[1],test1[2],test1[3],test1[4],(unsigned long)data.length);
//    }
}


//获取设备
- (FosAbility *)abilityOfDevice :(CDevice *)device channel :(int)ch
{
    FosAbility *ablility = nil;
    
    if (device && ch >= 0) {
        [self.mutex lock];
        NSString    *key    = [NSString stringWithFormat :@"D%d",device.uniqueId];
        DeviceNode  *node   = [self.channelMap valueForKey:key];
        
        if (node.users.count > 0) {
            ablility = [[node.abilities valueForKey:[NSString stringWithFormat:@"%d",ch]] copy];
        }
        
        [self.mutex unlock];
    }
    return ablility;
}

#pragma mark - setter and getter
- (NSMutableArray *)observers
{
    if (!_observers) {
        _observers = [[NSMutableArray alloc] init];
    }
    
    return _observers;
}

- (NSMutableArray *)pbObservers
{
    if (!_pbObservers) {
        _pbObservers = [[NSMutableArray alloc] init];
    }
    
    return _pbObservers;
}

- (NSMutableDictionary *)channelMap
{
    if (!_channelMap) {
        _channelMap = [[NSMutableDictionary alloc] init];
    }
    
    return _channelMap;
}
@end

