//
//  ScheduledRecording.m
//  VMS
//
//  Created by mac_dev on 15/7/27.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VideoRecorder.h"
#import "sys/time.h"

#define KEY_MANUAL_VIDEO_FILE_WRITTER       @"scheduled_video_file_writter"
#define KEY_SCHEDULED_VIDEO_FILE_WRITER     @"manual_video_file_writter"

#define TIMEOUT    dispatch_time(DISPATCH_TIME_NOW,0.002*NSEC_PER_SEC)
#define debug   0

static VideoRecorder *sharedVideoRecorder = nil;
static dispatch_once_t pred;
@interface RecordingState()

@property (readwrite) Channel *channel;
@end

@implementation RecordingState

- (id)initWithChannel:(Channel *)channel
{
    if (self = [super init]) {
        self.channel = channel;
    }
    
    return self;
}

- (dispatch_queue_t)writeFileQueue
{
    if (!_writeFileQueue) {
        NSString *lable = [NSString stringWithFormat:@"com.VMS.Recorder.Channel%ld.WriteFileQueue",self.channel.uniqueId];
        _writeFileQueue = dispatch_queue_create([lable UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    
    return _writeFileQueue;
}

@end




@interface VideoRecorder() {
    NSInteger _weekday;
}

@property (strong,nonatomic) NSArray *scheduledRecordTasks;

@property (strong,nonatomic) dispatch_semaphore_t startSignal;//开始信号量
@property (strong,nonatomic) NSMutableDictionary *recordingMap;
@property (strong,nonatomic) NSMutableArray *observers;
@property (strong,atomic) dispatch_semaphore_t syncSignal;
@property (strong,nonatomic) NSLock *mapLock;//用来锁录像字典
@property (strong,nonatomic) NSLock *writerLock;
@end

@implementation VideoRecorder
#pragma mark - Init
+(VideoRecorder *)sharedVideoRecorder
{
    dispatch_once(&pred, ^{
        sharedVideoRecorder = [[super allocWithZone:NULL] init];
    });
    return sharedVideoRecorder;
}

- (id)init
{
    if (self = [super init]) {
        self.syncSignal = dispatch_semaphore_create(0);
        self.mapLock = [[NSLock alloc] init];
        self.writerLock = [[NSLock alloc] init];
        self.recording_setting =
        [[VMSRecordSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
        //等待开始信号
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDatabaseChanged:)
                                                     name:DATABASE_CHANGED_NOTIFICATION
                                                   object:nil];
        [[DispatchCenter sharedDispatchCenter] addObserver:self];
        //加载通道信息，和定时任务
        [self loadChannelInfo];
        [self setScheduledRecordTasks:nil];
    }
    return self;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedVideoRecorder];
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

#pragma mark - notification
- (void)handleDatabaseChanged :(NSNotification *)aNotific
{
    [self.mapLock lock];
    
    NSDictionary *userInfo = aNotific.userInfo;
    VMS_DATABASE_OP op = [[userInfo valueForKey:NOTIFI_KEY_DB_OP] unsignedIntegerValue];
    Channel *channel = [userInfo valueForKey:NOTIFI_KEY_CHANNEL];
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    NSInteger chnId = channel.uniqueId;
    NSString *identifier = [NSString stringWithFormat:@"%ld",chnId];
    RecordingState *recordingState = [self.recordingMap valueForKey:identifier];
    
    switch (op) {
        case VMS_CHANNEL_ADD: {
            //向地图中
        }
            break;
            
        case VMS_CHANNEL_REMOVE: {
            //向中心发送停止请求，并且移除该条记录
            //查看是否在计划录像
            VideoFileWriter *scheduledVideoWrite = recordingState.scheduledVideoWriter;
            if (scheduledVideoWrite) {
                //同知中心关闭这路视频
                [center stopRealTimeVideoFromChannelId:(int)chnId streamType:FOSSTREAM_MAIN];
                [scheduledVideoWrite terminateWriting];
                [recordingState setScheduledVideoWriter :nil];
                //[self.recordingMap setValue:nil forKey:identifier];
            }
            
            dispatch_queue_t queue = recordingState.writeFileQueue;
            dispatch_async(queue, ^{
                //查看是否在报警录像中
                VideoFileWriter *alarmVideoWriter = recordingState.alarmVideoWriter;
                if (alarmVideoWriter) {
                    [alarmVideoWriter terminateWriting];
                    //通知中心关闭这路视频
                    [center stopRealTimeVideoFromChannelId:(int)chnId streamType:FOSSTREAM_MAIN];
                    [recordingState setAlarmVideoWriter:nil];
                }
            });
        }
            break;
            
        case VMS_CHANNEL_UPDATE:
            break;
            
        default:
            break;
    }
    
    //重载通道信息和计划任务以及录像配置文件
    [self loadScheduledTasks];
    [self loadChannelInfo];
    [self setRecording_setting:[[VMSRecordSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]]];//解档
    [self.mapLock unlock];
}

#pragma mark - Public API
- (void)switchManualRecordingState :(BOOL)state withChannelId :(int)channelId;
{
    NSString *identifier = [NSString stringWithFormat:@"%d",channelId];
    RecordingState *recordingState = [self.recordingMap valueForKey:identifier];
    if (recordingState) {
        VideoFileWriter *writer = recordingState.manualVideoWriter;
        if (!state && writer) recordingState.manualVideoWriter = nil;
        if (state && !writer) {
            //状态置为On,并且没有在手动录像
            VIDEO_FILE_CONSTRAINT constraint;
            NSString *path = [NSString stringWithFormat:@"%@/%d",self.recording_setting.recordingPathName,channelId];
            constraint.type = self.recording_setting.recordingRestrict + 1;//1-按时间打包    2-按文件大小打包   3-任意一种打包
            constraint.time_interval_max = self.recording_setting.recordingTime * 60;
            constraint.length_max = self.recording_setting.recordingSize * 1024*1024;
            writer = [[VideoFileWriter alloc] initWithFileConstraint:constraint type:1 path :path];
            writer.delegate = self;
            recordingState.manualVideoWriter = writer;
        }
    }
    
    //Report
    BOOL stateQuery = [self queryRecordingStateForChannelId:channelId];
    for (id<VideoRecorderProtocol> observer in self.observers) {
        if ([observer respondsToSelector:@selector(channelWithId:didChangeRecordingState:)]) {
            [observer channelWithId:channelId didChangeRecordingState :stateQuery];
        }
    }
}

- (void)switchAlarmRecordingState :(BOOL)state withChannelId :(int)channelId
{
    NSString *identifier = [NSString stringWithFormat:@"%d",channelId];
    RecordingState *recordingState = [self.recordingMap valueForKey:identifier];
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    
    if (recordingState) {
        __block VideoFileWriter *writer = recordingState.alarmVideoWriter;
        if (!state && writer) {
            //关闭报警录像
            [writer terminateWriting];
            [recordingState setAlarmVideoWriter:nil];
            //release
            [center stopRealTimeVideoFromChannelId:channelId
                                        streamType:FOSSTREAM_MAIN];
        }
        
        if (state && !writer) {
            //开启报警录像
            [center startRealTimeVideoFromChannel:recordingState.channel
                                       streamType:FOSSTREAM_MAIN
                             withCompletionHandle:^(BOOL success) {
                                 if (success) {
                                     //开启报警录像
                                     VIDEO_FILE_CONSTRAINT constraint;
                                     NSString *path = [NSString stringWithFormat:@"%@/%d",self.recording_setting.recordingPathName,channelId];
                                     constraint.type = self.recording_setting.recordingRestrict + 1;//1-按时间打包    2-按文件大小打包   3-任意一种打包
                                     constraint.time_interval_max = self.recording_setting.recordingTime * 60;
                                     constraint.length_max = self.recording_setting.recordingSize * 1024*1024;
                                     writer = [[VideoFileWriter alloc] initWithFileConstraint:constraint type:2 path :path];
                                     writer.delegate = self;
                                     recordingState.alarmVideoWriter = writer;
                                     //开启定时器,
                                     int timerInterval = self.recording_setting.alarmRecordTimerInterval;
                                     dispatch_queue_t queue = recordingState.writeFileQueue;
                                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timerInterval * NSEC_PER_SEC)), queue, ^{
                                         [self switchAlarmRecordingState:NO withChannelId:channelId];
                                     });
                                 }
                             }];
        }
    }
    
    //Report
    BOOL stateQuery = [self queryRecordingStateForChannelId:channelId];
    for (id<VideoRecorderProtocol> observer in self.observers) {
        if ([observer respondsToSelector:@selector(channelWithId:didChangeRecordingState:)]) {
            [observer channelWithId:channelId didChangeRecordingState :stateQuery];
        }
    }
}

- (void)addObserver:(id<VideoRecorderProtocol>)observer
{
    [self.observers addObject:observer];
}

- (void)removeObserver:(id<VideoRecorderProtocol>)observer
{
    [self.observers removeObject:observer];
}

- (BOOL)queryRecordingStateForChannelId :(int)channelId
{
    BOOL isRecording = NO;
    
    //dispatch_semaphore_wait(self.syncSignal, DISPATCH_TIME_FOREVER);
    NSString *identifier = [NSString stringWithFormat:@"%d",channelId];
    RecordingState *recordingState = [self.recordingMap valueForKey:identifier];
    
    if (recordingState) {
        isRecording |= (recordingState.manualVideoWriter != nil);
        isRecording |= (recordingState.scheduledVideoWriter != nil);
        isRecording |= (recordingState.alarmVideoWriter != nil);
    }
    
    //dispatch_semaphore_signal(self.syncSignal);
    
    return isRecording;
}




- (void)scanTasks
{
    //为保证计划的实时性，这里创建一个专用队列，用于扫描计划任务
    static dispatch_queue_t scanQueue = nil;
    if (!scanQueue) {
        scanQueue = dispatch_queue_create("com.VMS.VideoRecorder.scanQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async(scanQueue, ^{
        @try {
            //Do the tasks
            NSString *recordingPathName = self.recording_setting.recordingPathName;
            //获取了当前时间
            NSDate *now = [NSDate date];
            NSDate *now_time = [now time];
            
            //如果换了一天,需要重新取回任务
            NSInteger weekday = [now weekDay];
            if (weekday != _weekday) {
                self.scheduledRecordTasks = nil;
                _weekday = weekday;
            }
            
            [self.mapLock lock];
            //遍历通道，重置shouldOpen;
            NSArray *allRecordingState = self.recordingMap.allValues;
            for (RecordingState *recordingState in allRecordingState)
                [recordingState setShouldOpen:NO];
            
            //遍历任务
            //每个任务会有指定的通道，起始时间，终止时间，遍历这些任务，通知中心做相应的事情
            for (ScheduledTask *task in self.scheduledRecordTasks) {
                
                NSString *identifier = [NSString stringWithFormat:@"%ld",task.channelId];
                RecordingState *recordingState = [self.recordingMap valueForKey:identifier];
                //如果有符合的时间段，shouldOpen = ture
                NSArray *ranges =  [task parser];
                for (DateRange *range in ranges) {
                    if ([range isContainDate:now_time]) {
                        recordingState.shouldOpen = true;
                        break;
                    }
                }
            }
            
            //再次遍历通道，根据shouldOpen做相应的事情;
            for (RecordingState *recordingState in allRecordingState) {
                Channel *chn = recordingState.channel;
                VideoFileWriter *scheduledVideoWriter = recordingState.scheduledVideoWriter;
                BOOL shouldOpen = recordingState.shouldOpen;
                if (shouldOpen) {
                    //查看是否还未打开
                    if (!scheduledVideoWriter) {
                        //查看是否正在连接
                        if (!recordingState.isConnecting) {
                            //通知中心打开
                            [recordingState setConnecting :YES];
                            [[DispatchCenter sharedDispatchCenter] startRealTimeVideoFromChannel :chn
                                                                                      streamType :FOSSTREAM_MAIN
                                                                            withCompletionHandle :^(BOOL success)
                             {
                                 if (success) {
                                     VIDEO_FILE_CONSTRAINT constraint;
                                     NSString *path = [NSString stringWithFormat:@"%@/%ld",recordingPathName,chn.uniqueId];
                                     constraint.type = self.recording_setting.recordingRestrict + 1;//1-按时间打包    2-按文件大小打包   3-任意一种打包
                                     constraint.time_interval_max = self.recording_setting.recordingTime * 60;
                                     constraint.length_max = self.recording_setting.recordingSize * 1024 * 1024;
                                     recordingState.scheduledVideoWriter =
                                     [[VideoFileWriter alloc] initWithFileConstraint:constraint type:0 path :path];
                                     recordingState.scheduledVideoWriter.delegate = self;
                                     //通知观察者，录像状态发生了改变
                                     [self reportRecordingStateFromChannelId :(int)chn.uniqueId];
                                 }
                                 [recordingState setConnecting :NO];
                             }];
                        }
                    }
                } else if (scheduledVideoWriter) {
                    //检测到没有任务需要使用这路通道，通知中心关闭它
                    [[DispatchCenter sharedDispatchCenter] stopRealTimeVideoFromChannelId: (int)chn.uniqueId streamType:FOSSTREAM_MAIN];
                    //关闭计划录像
                    [scheduledVideoWriter terminateWriting];
                    [recordingState setScheduledVideoWriter :nil];
                    //通知观察者，录像状态发生了改变
                    [self reportRecordingStateFromChannelId :(int)chn.uniqueId];
                }
            }
            
            [self.mapLock unlock];
        }
        @catch (NSException *exception) {
            NSLog(@"Warning!!!!!!Exception raised,%@",exception);
        }
    });
}


#pragma mark - private method
- (void)reportRecordingStateFromChannelId :(int)channelId
{
    BOOL state = [self queryRecordingStateForChannelId:channelId];
    for (id<VideoRecorderProtocol> observer in self.observers) {
        if ([observer respondsToSelector:@selector(channelWithId:didChangeRecordingState:)]) {
            [observer channelWithId:channelId didChangeRecordingState:state];
        }
    }
}

- (void)shutdownScheduledRecording
{
    //遍历每个通道，依次关闭定时录像
    NSArray *allValues = [self.recordingMap allValues];
    for (RecordingState *state in allValues) {
        //关闭写者
        VideoFileWriter *scheduledVideoWrite = state.scheduledVideoWriter;
        if (scheduledVideoWrite) {
            [scheduledVideoWrite terminateWriting];
            [state setScheduledVideoWriter :nil];
            //向中心请求关闭视频流
            [[DispatchCenter sharedDispatchCenter] stopRealTimeVideoFromChannelId:(int)state.channel.uniqueId streamType:FOSSTREAM_MAIN];
        }
        //广播通知出去
        [self reportRecordingStateFromChannelId:(int)state.channel.uniqueId];
    }
}


- (NSArray *)videoFiles
{
    NSURL *url = [NSURL URLWithString:self.recording_setting.recordingPathName];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [manager enumeratorAtURL:url
                                      includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                         options:NSDirectoryEnumerationSkipsHiddenFiles
                                                    errorHandler:^BOOL(NSURL *url, NSError *error)
    {
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
            [mutableFileURLs addObject:fileURL];
        }
    }
    
    return [NSArray arrayWithArray:mutableFileURLs];
}

- (void)excuteLoopRecordTrick
{
    if (debug) {
        NSLog(@"开始执行循环录像");
    }
    
    NSArray *videoFiles = [self videoFiles];
    //按照时间对文件进行排序
    NSArray *sortedVideoFiles = [videoFiles sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSInteger temp = 0;
        NSURL *url1 = obj1;
        NSURL *url2 = obj2;
        NSDate *beginDate1,*beginDate2;
        NSDate *endDate1,*endDate2;
        [url1.path.lastPathComponent getVideoType:&temp
                                        beginDate:&beginDate1
                                          endDate:&endDate1];
        [url2.path.lastPathComponent getVideoType:&temp
                                        beginDate:&beginDate2
                                          endDate:&endDate2];
        return [beginDate1 compare:beginDate2];
    }];
    //从头至尾的顺序删除制定大小的录像文件
    NSInteger delSize = 1024 * 1024 * self.recording_setting.loopRecordDeleteFileSize;
    NSInteger count = [sortedVideoFiles count];
    NSFileManager *manager = [NSFileManager defaultManager];
    for (int idx = 0; idx < count; idx++) {
        NSURL *url = [sortedVideoFiles objectAtIndex:idx];
        NSError *err;
        NSInteger size = [[manager attributesOfItemAtPath:url.path
                                                            error:&err] fileSize];
        
        if (delSize <= 0)
            break;
        
        if (!err) {
            [manager removeItemAtURL:url error:&err];
            if (!err) {
                //减去该文件大小
                delSize -= size;
            }
        }
    }
    if (debug) {
        NSLog(@"结束执行循环录像");
    }
}

#pragma mark - video file writer delegate
- (void)willWriteToDisk:(NSNotification *)aNotific
{
    //处理录像文件写者回调
    [self.writerLock lock];
    NSError* err;
    NSFileManager*  manager         = [NSFileManager defaultManager];
    NSDictionary*   fileAttributes  = [manager attributesOfFileSystemForPath:@"/" error:&err];
    NSDictionary*   userInfo        = [aNotific userInfo];
    size_t          size            = [[userInfo valueForKey:KEY_VIDEO_DATA_LEN] unsignedLongValue];
    //考虑磁盘写满情况，删除录像
    if (!err) {
        //这里添加测试条件
        unsigned long long freeSpace = [[fileAttributes objectForKey:NSFileSystemFreeSize] longLongValue];
        if (freeSpace < size) {
            [self excuteLoopRecordTrick];
        }
    }
    [self.writerLock unlock];
}
#pragma mark - dispatch center delegate
- (void)didRecivedData:(void *)bytes
                length:(int)lenght
                  type:(int)type
             timeStamp:(double)timeStamp
             channelId:(int)channel_id
            streamType:(FOSSTREAM_TYPE)streamType
{
    if (FOSSTREAM_MAIN == streamType) {
        //当前操作在其它线程执行
        //仅接收大码流
        //查录像状态
        RecordingState *recordingState = [self.recordingMap valueForKey:[NSString stringWithFormat:@"%d",channel_id]];
        BOOL recordable = self.recording_setting.enable;
        
        unsigned int data_type = DATA_TYPE_AUDIO;
        switch (type) {
            case DATA_TYPE_AUDIO_PCM:
                data_type = DATA_TYPE_AUDIO;
                break;
            case DATA_TYPE_VIDEO_H264:
                data_type = DATA_TYPE_VIDEO;
                break;
            default:
                break;
        }
        
        if (recordingState && recordable) {
            //查看是否保存录像
            Channel *channel = recordingState.channel;
            VideoFileWriter *scheduled_writer = recordingState.scheduledVideoWriter;
            VideoFileWriter *manual_writer = recordingState.manualVideoWriter;
            VideoFileWriter *alarm_writer = recordingState.alarmVideoWriter;
            dispatch_queue_t queue = recordingState.writeFileQueue;
            
            NSString *path = self.recording_setting.recordingPathName;
            NSData *copy = [NSData dataWithBytes:bytes length:lenght];
            [scheduled_writer writeData:copy
                                   type:data_type
                                channel:channel
                                  queue:queue
                                   path:path];
            [manual_writer writeData:copy
                                type:data_type
                             channel:channel
                               queue:queue
                                path:path];
            [alarm_writer writeData:copy
                               type:data_type
                            channel:channel
                              queue:queue
                               path:path];
        }
    }

}

- (void)didDisconnectChannelId:(int)channelId
                    streamType:(FOSSTREAM_TYPE)streamType
{
    if (FOSSTREAM_MAIN == streamType) {
        RecordingState *recordingState = [self.recordingMap valueForKey:[NSString stringWithFormat:@"%d",channelId]];
        
        if (recordingState) {
            VideoFileWriter *scheduled_writer = recordingState.scheduledVideoWriter;
            VideoFileWriter *manual_writer = recordingState.manualVideoWriter;
            VideoFileWriter *alarm_writer = recordingState.alarmVideoWriter;
            dispatch_queue_t queue = recordingState.writeFileQueue;
            dispatch_async(queue, ^{
                [scheduled_writer terminateWriting];
                [manual_writer terminateWriting];
                [alarm_writer terminateWriting];
            });
        }
    }
}



#pragma mark - getter and setter
- (NSMutableArray *)observers
{
    if (!_observers) {
        _observers = [[NSMutableArray alloc] init];
    }
    
    return _observers;
}

- (NSArray *)scheduledRecordTasks
{
    if (!_scheduledRecordTasks) {
        _scheduledRecordTasks = [[VMSDatabase sharedVMSDatabase] fetchScheduledTasksWithWeekday:_weekday entity:@"t_rec_plan"];
    }
    
    return _scheduledRecordTasks;
}



- (void)loadScheduledTasks
{
    //加载计划任务
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    NSDate *now = [NSDate date];
    NSInteger weekday = [now weekDay];
    
    self.scheduledRecordTasks = [db fetchScheduledTasksWithWeekday:weekday entity:@"t_rec_plan"];
}

- (void)loadChannelInfo
{
    //取回所有设备
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    NSArray *devices = [db fetchDevices];
    
    //取回所有通道
    for (CDevice *device in devices) {
        NSArray *channels = [db fetchChannelsWithDevice:device];
        for (Channel *channel in channels) {
            NSString *identifier = [NSString stringWithFormat:@"%ld",channel.uniqueId];
            RecordingState *state = [self.recordingMap valueForKey :identifier];
            if (!state) {
                //登记
                state = [[RecordingState alloc] initWithChannel:channel];
                [self.recordingMap setValue:[[RecordingState alloc] initWithChannel:channel] forKey:identifier];
            }
            state.channel = channel;
        }
    }
}

- (NSMutableDictionary *)recordingMap
{
    if (!_recordingMap) {
        _recordingMap = [[NSMutableDictionary alloc] init];
    }
    
    return _recordingMap;
}

- (dispatch_semaphore_t)startSignal
{
    if (!_startSignal) {
        _startSignal = dispatch_semaphore_create(0);
    }
    return _startSignal;
}

@end
