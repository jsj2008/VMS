//
//  ScheduledRecording.m
//  VMS
//
//  Created by mac_dev on 15/7/27.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "RecordCenter.h"
#import "sys/time.h"
#import "DiskManager.h"

#define KEY_MANUAL_VIDEO_FILE_WRITTER       @"scheduled_video_file_writter"
#define KEY_SCHEDULED_VIDEO_FILE_WRITER     @"manual_video_file_writter"

#define TIMEOUT    dispatch_time(DISPATCH_TIME_NOW,0.002*NSEC_PER_SEC)

#define SCAN_DEBUG              0
#define LOOP_DEBUG              1
#define RECORD_CENTER_DEBUG     0



#define TRACE_SCAN(MSG)   if (SCAN_DEBUG) {\
NSLog(@"录像中心:%@",MSG);\
}

#define TRACE_CHANNEL(ID,LABEL,MSG) if (RECORD_CENTER_DEBUG) {\
NSLog(@"录像中心:通道(%d）,%@,%@",ID,LABEL,MSG);\
}


@implementation RFile

- (void)cache
{
    if (!self.begin && !self.end) {
        NSInteger var1 = 0;
        NSDate *var2 = nil;
        NSDate *var3 = nil;
        
        [self.url.path.lastPathComponent getVideoType:&var1
                                            beginDate:&var2
                                              endDate:&var3];
        
        self.begin = var2;
        self.end = var3;
    }
}

@end


@interface RecordingState : NSObject

- (id)initWithChannel :(Channel *)channel;

@property (nonatomic,strong) CDevice *device;
@property (nonatomic,strong) Channel *channel;
@property (nonatomic,strong) VideoRecorder *recorder;
@property (nonatomic,assign) int connections;
@property (nonatomic,assign) int cancels;
@property (nonatomic,assign) BOOL shouldOpen;
@property (nonatomic,assign) FOSSTREAM_TYPE manualRecordStreamType;

@end

@implementation RecordingState

- (id)initWithChannel :(Channel *)channel;
{
    //TODO :初始化路径
    if (self = [super init]) {
        self.channel = channel;
        self.recorder = [[VideoRecorder alloc] initWithChannel:channel];
    }
    
    return self;
}

@end


static RecordCenter    *sharedRecordCenter = nil;
static dispatch_once_t  pred;

@interface RecordCenter() {
    int _weekday;
}

@property (strong,nonatomic) NSArray *scheduledRecordTasks;
@property (strong,nonatomic) NSMutableDictionary *recordingMap;
@property (strong,nonatomic) NSMutableArray *observers;

#if OS_OBJECT_HAVE_OBJC_SUPPORT == 1
@property (nonatomic,strong) dispatch_queue_t scanQueue;
#else
@property (nonatomic,assign) dispatch_queue_t scanQueue;
#endif

@end

@implementation RecordCenter

#pragma mark - Init
+(RecordCenter *)sharedRecordCenter
{
    dispatch_once(&pred, ^{
        sharedRecordCenter = [[super allocWithZone:NULL] init];
    });
    return sharedRecordCenter;
}

- (id)init
{
    if (self = [super init]) {
        @synchronized (self) {
            //等待开始信号
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleDatabaseChanged:)
                                                         name:DATABASE_CHANGED_NOTIFICATION
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleRecordingSettingChanged:)
                                                         name:RECORDING_SETTING_DID_CHANGE_NOTIFIC object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleConnectionStateChangeNotification:)
                                                         name:CONNECTION_STATE_DID_CHANGE_NOTIFICATION
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleDeviceReloadNotification:)
                                                         name:DEVICE_RELOAD_NOTIFICATION
                                                       object:nil];
            [[DispatchCenter sharedDispatchCenter] addObserver:self];
            //加载通道信息，和定时任务
            [self setRecording_setting:[[VMSRecordSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]]];
            [self loadChannelInfo];
            [self setScheduledRecordTasks:nil];
        }
    }
    return self;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedRecordCenter];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)dealloc
{
    //移除观察者
    [[DispatchCenter sharedDispatchCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NOTIFICATION
- (void)handleRecordingSettingChanged :(NSNotification *)aNotific
{
    @synchronized (self) {
        NSArray *allValues = self.recordingMap.allValues;
        VMSRecordSetting *rs = [[VMSRecordSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
        
        for (RecordingState *state in allValues) {
            [state.recorder setRs:rs];
        }
    }
}


- (void)handleDatabaseChanged :(NSNotification *)aNotific
{
    @synchronized (self) {
        NSDictionary    *userInfo       = aNotific.userInfo;
        VMS_DATABASE_OP op              = (VMS_DATABASE_OP)[[userInfo valueForKey:NOTIFI_KEY_DB_OP] unsignedIntegerValue];
        CDevice         *device         = [userInfo valueForKey:NOTIFI_KEY_DEVICE];
    
        NSLog(@"录像中心:设备(%d),处理数据库变动通知",device.uniqueId);
        switch (op) {
            case VMS_DEVICE_REMOVE: {
                for (Channel *channel in device.children) {
                    long            chnId       = channel.uniqueId;
                    NSString        *key        = [NSString stringWithFormat:@"%ld",chnId];
                    RecordingState  *rState     = [self.recordingMap valueForKey:key];
                    VideoRecorder   *recorder   = rState.recorder;
                    
                    [recorder stop:AllRecord];
                    [self.recordingMap setValue:nil forKey:key];
                }
            }
                break;
                
            case VMS_DISCARD:
                [self shutdownScheduledRecording];
                break;
                
            case VMS_DEVICE_ADD:
            case VMS_DEVICE_UPDATE:
            default:
                break;
        }
        
        //重载通道信息和计划任务以及录像配置文件
        [self loadScheduledTasks];
        [self loadChannelInfo];
    }
}

#pragma mark - Public API(所有的公共方法需要加锁确保线程安全)
- (NSString *)labelWithRecordType :(RecordType)type
{
    switch (type) {
        case ScheduledRecord:
            return @"计划录像";
            
        case ManualRecord:
            return @"手动录像";
            
        case AlarmRecord:
            return @"报警录像";
            
        default:
            return @"未知录像";
    }
}

//报警录像会对视频数据进行强引用，会向中心发起请求
- (void)switchRecordingState :(BOOL)state withChannelId :(int)channelId type :(RecordType)type
{
    if (channelId < 0) return;
    
    @synchronized (self) {
        NSString            *key    = [NSString stringWithFormat:@"%d",channelId];
        RecordingState      *rState = [self.recordingMap valueForKey:key];
        DispatchCenter      *center = [DispatchCenter sharedDispatchCenter];
        dispatch_queue_t    queue   = dispatch_get_current_queue();
        NSString            *lable  = [self labelWithRecordType:type];
        
        if (rState) {
            VideoRecorder *recorder = rState.recorder;
            BOOL isRecording = [recorder isRecording:type];
            
            if (state) {
                TRACE_CHANNEL(channelId, lable,@"开启录像");
                
                if (isRecording) {
                    TRACE_CHANNEL(channelId, lable,@"正在录像");
                }
                else {
                    TRACE_CHANNEL(channelId,lable ,@"准备开启录像");
                    if (rState.connections & type) {
                        TRACE_CHANNEL(channelId, lable,@"正在连接中......");
                    }
                    else {
                        TRACE_CHANNEL(channelId, lable,@"向中心发起请求");
                        //开启报警录像
                        [center startRealTimeVideoFromDevice:rState.device
                                                     channel:rState.channel.logicId
                                                  streamType:RECORD_STREAM_TYPE
                                                       queue:queue
                                        withCompletionHandle:^(BOOL success)
                        {
                            @synchronized (self) {
                                rState.connections &= ~type;
                
                                if (success) {
                                    if (rState.cancels & type) {
                                        //出同步块，解死锁
                                        [center stopRealTimeVideoFromDevice:rState.device
                                                                    channel:rState.channel.logicId
                                                                 streamType:RECORD_STREAM_TYPE];
                                        
                                        
                                        rState.cancels &= ~type;
                                        TRACE_CHANNEL(channelId, lable,@"已经取消");
                                    }
                                    else {
                                        [recorder start:type];
                                        TRACE_CHANNEL(channelId, lable,@"开启成功!");
                                    }
                                }
                                else {
                                    TRACE_CHANNEL(channelId, lable,@"开启失败!");
                                }
                                
                                [self reportRecordingStateFromChannelId:channelId];
                            }
                        }];
                    }
                }
            }
            else {
                if (rState.connections & type) {
                    TRACE_CHANNEL(channelId, lable,@"取消连接")
                    rState.cancels |= type;
                }
                else if (isRecording) {
                    TRACE_CHANNEL(channelId, lable,@"关闭")
                    //出同步块，解死锁
                    [center stopRealTimeVideoFromDevice:rState.device channel:rState.channel.logicId streamType:RECORD_STREAM_TYPE];
                    [recorder stop:type];
                    [self reportRecordingStateFromChannelId:channelId];
                }
                else {
                    TRACE_CHANNEL(channelId, lable,@"尚未开启")
                }
            }
        }
    }
}

- (int)queryStateWithChannelId :(int)cId recordType :(RecordType)type
{
    int state = RECORD_OFF;
    
    if (cId >= 0) {
        @synchronized (self) {
            NSString        *key = [NSString stringWithFormat:@"%d",cId];
            RecordingState  *rState = [self.recordingMap valueForKey:key];
            
            if (rState) {
                BOOL isRecording = [rState.recorder isRecording:type];
                
                if (isRecording) {
                    state = RECORD_ON;
                }
                else {
                    if (type == AllRecord) {
                        state = RECORD_OFF;
                    }
                    else {
                        state = (rState.connections & (1 << type))? RECORD_CONNECTING : RECORD_OFF;
                    }
                }
            }
        }
    }
    
    return state;
}

- (void)scanTasks
{
    dispatch_async(self.scanQueue, ^{
        @autoreleasepool {
            @synchronized (self) {
                TRACE_SCAN(@"开始扫描");
                NSDate *now = [NSDate date];
                NSDate *now_time = [now time];
                
                //如果换了一天,需要重新取回任务
                int weekday = (int)[now weekDay];
                if (weekday != _weekday) {
                    self.scheduledRecordTasks = nil;
                    _weekday = weekday;
                }
                
                //遍历通道，重置shouldOpen;
                TRACE_SCAN(@"关闭各通道打开开关");
                NSArray *allRState = self.recordingMap.allValues;
                for (RecordingState *rState in allRState)
                    [rState setShouldOpen:NO];
                
                //遍历任务
                //每个任务会有指定的通道，起始时间，终止时间，遍历这些任务，通知中心做相应的事情
                TRACE_SCAN(@"查询录像计划");
                for (ScheduledTask *task in self.scheduledRecordTasks) {
                    NSString        *key = [NSString stringWithFormat:@"%d",task.channelId];
                    RecordingState  *rState = [self.recordingMap valueForKey:key];
                    NSArray         *ranges =  [task parser];
                    
                    for (DateRange *range in ranges) {
                        if ([range isContainDate:now_time]) {
                            rState.shouldOpen = true;
                            break;
                        }
                    }
                }
                
                for (RecordingState *rState in allRState) {
                    [self switchRecordingState:rState.shouldOpen
                                 withChannelId:rState.channel.uniqueId
                                          type:ScheduledRecord];
                }
                TRACE_SCAN(@"结束扫描");
            }
        }
    });
}

- (void)loopRecord
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        @autoreleasepool {
            
            VMSRecordSetting *rs = nil;
            
            @synchronized (self) {
                rs = self.recording_setting;
            }
            
            if ([DiskManager diskUsage] >= DISK_TOLERANCE) {
                if (self.recording_setting.enableLoopRecord) {
                    //执行循环录像
                    [self excuteLoopRecordTrickWithRecordSetting:rs];
                }
                else {
                    //发出用户警告
                    [self deliverDiskSpaceNotEnoughNotification];
                }
            }
        }
    });
}

- (void)excuteLoopRecordTrickWithRecordSetting :(VMSRecordSetting *)rs
{
    if (LOOP_DEBUG) {
        NSLog(@"开始执行循环录像");
    }
    
    NSDate *t1 = [NSDate date];    //按照时间对文件进行排序
    NSArray *videoFiles = [self videoFilesInPath:rs.recordingPathName];
    NSArray *sortedVideoFiles = [videoFiles sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        RFile *f1 = obj1;
        RFile *f2 = obj2;
        
        [f1 cache];
        [f2 cache];
        
        return [f1.begin compare:f2.begin];
    }];
    NSDate *t2 = [NSDate date];
    
    if (LOOP_DEBUG) {
        NSLog(@"sort cost %f",[t2 timeIntervalSinceDate:t1]);
    }
    
    
    //从头至尾的顺序删除制定大小的录像文件
    NSInteger delSize = 1024 * 1024 * rs.loopRecordDeleteFileSize;
    NSInteger count = [sortedVideoFiles count];
    NSFileManager *manager = [NSFileManager defaultManager];
    for (int idx = 0; idx < count; idx++) {
        RFile       *rFile = [sortedVideoFiles objectAtIndex:idx];
        NSError     *err;
        NSInteger   size = [[manager attributesOfItemAtPath:rFile.url.path
                                                      error:&err] fileSize];
        
        if (rFile.begin == nil || rFile.end == nil)
            continue;
        
        if (delSize <= 0)
            break;
        
        if (!err) {
            [manager removeItemAtURL:rFile.url error:&err];
            if (!err) {
                //减去该文件大小
                delSize -= size;
            }
        }
        else {
            NSLog(@"remove file error:%@",err);
        }
    }
    
    NSDate *t3 = [NSDate date];
    if (LOOP_DEBUG) {
        NSLog(@"complete cost %f",[t3 timeIntervalSinceDate:t1]);
    }
    
    if (LOOP_DEBUG) {
        NSLog(@"结束执行循环录像");
    }
}

- (NSArray *)videoFilesInPath :(NSString *)path
{
    if (path) {
        NSURL *url = [NSURL URLWithString:path];
        NSFileManager *manager = [NSFileManager defaultManager];
        NSDirectoryEnumerator *enumerator =
        [manager enumeratorAtURL:url
      includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                         options:NSDirectoryEnumerationSkipsHiddenFiles
                    errorHandler:^BOOL(NSURL *url, NSError *error) {
                        
                        if (error) {
                            NSLog(@"[Error] %@ (%@)", error, url);
                            return NO;
                        }
                        return YES;
                    }];
        
        NSMutableArray *mutableFileURLs = [NSMutableArray array];
        for (NSURL *fileURL in enumerator) {
            NSString *filename;
            [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];
            
            NSNumber *isDirectory;
            [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
            
            // Skip directories with '_' prefix, for example
            if ([filename hasPrefix:@"_"] && [isDirectory boolValue]) {
                [enumerator skipDescendants];
                continue;
            }
            
            if (![isDirectory boolValue]) {
                RFile *rFile = [[RFile alloc] init];
                
                rFile.url = fileURL;
                [mutableFileURLs addObject:rFile];
            }
        }
        
        return [NSArray arrayWithArray:mutableFileURLs];
    }
    
    return nil;
}

- (void)deliverDiskSpaceNotEnoughNotification
{
    static NSDate *latestDt = nil;
    NSDate *now = [NSDate date];
    
    if ((nil == latestDt) || ([now timeIntervalSinceDate:latestDt] >= 1800)) {
        latestDt = now;
        
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        
        notification.title = @"系统磁盘空间不足，录像功能将受限";
        notification.informativeText = @"系统设置里面开启循环录像功能";
        notification.soundName = NSUserNotificationDefaultSoundName;
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

//是否呈现通知给用户，这里如果不呈现，会一直累加
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

#pragma mark - REPORT && SHUTDOWN
- (void)reportRecordingStateFromChannelId :(int)channelId
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RECORD_STATE_DID_CHANGE_NOTIFICATION
                                                        object:self
                                                      userInfo:@{KEY_RECORD_CHID : [NSNumber numberWithInt:channelId]}];
}

- (void)shutdownScheduledRecording
{
    //遍历每个通道，依次关闭定时录像
    NSArray *allValues = [self.recordingMap allValues];
    for (RecordingState *state in allValues) {
        //关闭写者
        VideoRecorder *recorder = state.recorder;
        if ([recorder isRecording:ScheduledRecord]) {
            //向中心请求关闭视频流
            [[DispatchCenter sharedDispatchCenter] stopRealTimeVideoFromDevice:state.channel.device
                                                                       channel:state.channel.logicId
                                                                    streamType:RECORD_STREAM_TYPE];
            [recorder stop:ScheduledRecord];
        }
        //广播通知出去
        [self reportRecordingStateFromChannelId:state.channel.uniqueId];
    }
}

#pragma mark - DISPATCH CENTER DELEGATE(中心回调需要加锁确保线程安全)
- (void)didRecivedData:(void *)bytes
                length:(int)lenght
                  type:(int)type
             timeStamp:(double)timeStamp
             channelId:(int)channel_id
            streamType:(FOSSTREAM_TYPE)streamType
{
    //当前操作在其它线程执行
    @synchronized(self) {
        if (self.recording_setting.enable && streamType == RECORD_STREAM_TYPE) {
            NSString        *key = [NSString stringWithFormat:@"%d",channel_id];
            RecordingState  *rState = [self.recordingMap valueForKey:key];
            
            [rState.recorder inputData:bytes length:lenght type:type];
        }
    }
}

- (void)handleConnectionStateChangeNotification :(NSNotification *)aNotific
{
    int  devId = [[aNotific.userInfo valueForKey:KEY_EVENT_DEVICE_ID] intValue];
    int  logicId = [[aNotific.userInfo valueForKey:KEY_EVENT_CHANNEL_ID] intValue];
    BOOL state  = [[aNotific.userInfo valueForKey:KEY_EVENT_CONNECTION_STATE] boolValue];
    
    @synchronized(self) {
        
        if (!state) {
            NSArray *channelStates = self.recordingMap.allValues;
            
            for (RecordingState *rs in channelStates) {
                if ((rs.device.uniqueId == devId) &&
                    (rs.channel.logicId == logicId)) {
                    //关闭录像
                    [rs.recorder stop:AllRecord];
                    [self reportRecordingStateFromChannelId:rs.channel.uniqueId];
                }
            }
        }
    }
}

- (void)handleDeviceReloadNotification :(NSNotification *)aNotific
{
    //该函数在中心每个设备单独的线程中执行，
    int devId = [[aNotific.userInfo valueForKey:KEY_EVENT_DEVICE_ID] intValue];
    //主线城对该代码块枷锁
    @synchronized(self) {
        NSArray *channelStates = self.recordingMap.allValues;
        
        for (RecordingState *rs in channelStates) {
            CDevice *device = rs.device;
            
            if ((device.uniqueId == devId)) {
                VideoRecorder *recorder = rs.recorder;
                RecordType recordTypes[] = {
                    ScheduledRecord,
                    ManualRecord,
                    AlarmRecord
                };
                
                for (int i = 0; i < 3; i++) {
                    if ([recorder isRecording:recordTypes[i]]) {
                        [[DispatchCenter sharedDispatchCenter] stopRealTimeVideoFromDevice:device
                                                                                   channel:rs.channel.logicId
                                                                                streamType:RECORD_STREAM_TYPE];
                    
                        [recorder stop:recordTypes[i]];
                    }
                }
            }
        }
    }
}
#pragma mark - load
//计划录像任务
- (void)loadScheduledTasks
{
    VMSDatabase *db     = [VMSDatabase sharedVMSDatabase];
    NSDate      *now    = [NSDate date];
    int         weekday = (int)[now weekDay];
    
    self.scheduledRecordTasks = [db fetchScheduledTasksWithWeekday:weekday entity:@"t_rec_plan"];
}

//加载所有通道信息
- (void)loadChannelInfo
{
    VMSDatabase *db             = [VMSDatabase sharedVMSDatabase];
    NSArray     *devices        = [db fetchDevices];
    
    for (CDevice *device in devices) {
        NSArray *channels = [db fetchChannelsWithDevice:device];
        for (Channel *channel in channels) {
            NSString        *key    = [NSString stringWithFormat:@"%d",channel.uniqueId];
            RecordingState  *state  = [self.recordingMap valueForKey :key];
            
            if (!state) {
                state = [[RecordingState alloc] initWithChannel:channel];
                [self.recordingMap setValue:state forKey:key];
            }
            state.device = device;
            state.channel = channel;
        }
    }
}

#pragma mark - getter and setter
- (NSArray *)scheduledRecordTasks
{
    if (!_scheduledRecordTasks) {
        _scheduledRecordTasks = [[VMSDatabase sharedVMSDatabase] fetchScheduledTasksWithWeekday:_weekday entity:@"t_rec_plan"];
    }
    
    return _scheduledRecordTasks;
}

- (NSMutableDictionary *)recordingMap
{
    if (!_recordingMap) {
        _recordingMap = [[NSMutableDictionary alloc] init];
    }
    
    return _recordingMap;
}

- (dispatch_queue_t)scanQueue
{
    if (!_scanQueue) {
        _scanQueue = dispatch_queue_create("com.foscam.vms.video_recorder.scan_queue", DISPATCH_QUEUE_SERIAL);
    }
    
    return _scanQueue;
}
@end
