//
//  VideoPlayer.m
//  VMS
//  对于音频和视频的回放，对延迟要求较高，这里采用NSThread取代苹果gcd
//
//  Created by mac_dev on 15/8/19.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VideoPlayer.h"
#import "video_frame_type.h"

#define BUFFER_SIZE     1024 * 1024
#define SPEED_MAX       8.0
#define SPEED_MIN       0.125
#define SYNC_WAIT_USECS 5 * 1000

#define KEY_PLAYER       @"player"
#define KEY_CHNNEL_ID    @"channelId"
#define KEY_VIDEO_INFOS  @"video infos"

//thread args
#define KEY_SEEK                @"seek"
#define KEY_SEEK_DATE           @"seek_date"
#define KEY_SPEED               @"speed"
#define KEY_FILE_PATH           @"file_path"
#define KEY_END_FILES           @"end_files"
#define KEY_NEXT_FRAME          @"next_frame"


//debug macro
#define PLAYER_DEBUGGER   1
#define TRACE_CHANNEL(ID,MSG)   if (PLAYER_DEBUGGER) {\
NSLog(@"播放器:通道(%d）%@",ID,MSG);\
}


@implementation PlayerLaunchArgcs

- (id)init
{
    if (self = [super init]) {
        self.hThread = 0;
        self.channelId = -1;
        self.videoInfos = nil;
    }
    
    return self;
}

@end


@interface VideoPlayer()

@property (nonatomic,strong) NSMutableDictionary *playerLaunchArgcs;//线程启动参数
@property (nonatomic,strong) NSMutableArray *playerRunArgcs;//线程运行参数
@property (readwrite) NSMutableArray *playSources;//播放源
@property (nonatomic,strong) NSMutableArray *observers;//观察者

//count
@property (nonatomic,assign) NSInteger pausingChannelCount;
//flag
@property (atomic,assign) BOOL shouldStopPlaying;
@property (nonatomic,assign) BOOL shouldPausePlaying;
@property (readwrite) double speed;//播放速度,用于控制快放，慢放
//lock & condition
@property (nonatomic,strong) NSLock *timestampLock;//互斥访问threadArgs读写当前时间戳
@property (nonatomic,strong) NSCondition *frameSignal;//同步主线程和播放线程

@end

@implementation VideoPlayer

#pragma mark - init
- (id)init
{
    if (self = [super init]) {
        self.playerRunArgcs = [[NSMutableArray alloc] init];
        self.playSources = [[NSMutableArray alloc] init];
        self.shouldStopPlaying = YES;
        self.shouldPausePlaying = NO;
        self.speed = 1.0;
        self.frameSignal = [[NSCondition alloc] init];
        self.timestampLock = [[NSLock alloc] init];
        self.playerLaunchArgcs = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
    [self stop];
}

#pragma mark - public api
//增加观察者
- (void)addObserver :(id<VideoPlayerProtocol>)observer
{
    if (observer) [self.observers addObject:observer];
}

//移除观察者
- (void)removeObserver :(id<VideoPlayerProtocol>)observer
{
    if (observer) [self.observers removeObject:observer];
}

//增加一路通道
- (void)addChannelWithId :(int)channelId
      multyVideoFileInfo :(NSArray *)multyVideoInfo
{
    //对传递进来的时间段 按 开始时间 进行排序
    NSArray *sortedVideoInfos =
    [multyVideoInfo sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
    {
         NSDate *obj1Begin = [obj1 valueForKey:KEY_DATE_BEGIN];
         NSDate *obj2Begin = [obj2 valueForKey:KEY_DATE_BEGIN];
         return [obj1Begin compare:obj2Begin];
    }];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSNumber numberWithInt:channelId] forKey :KEY_CHANNEL_ID];
    [dict setObject:sortedVideoInfos forKey :KEY_MULTY_VIDEO_FILE_INFO];
    [self.playSources addObject:dict];
}

- (BOOL)isPlaying
{
    return !self.shouldStopPlaying;
}

- (BOOL)isPausing
{
    BOOL isPausing = NO;
    
    [self.frameSignal lock];
    isPausing = self.shouldPausePlaying;
    [self.frameSignal unlock];
    
    return isPausing;
}

- (BOOL)play
{
    //存在播放源
    //并且没有开始播放
    if (self.playSources.count > 0 && ![self isPlaying]) {
        self.shouldStopPlaying = NO;
        self.shouldPausePlaying = NO;
        self.speed = 1.0;
        self.pausingChannelCount = 0;
        self.seekDate = nil;
    
        //开始多路视频同步播放
        for (NSMutableDictionary *souce in self.playSources) {
            int chnId = [[souce valueForKey:KEY_CHANNEL_ID] intValue];
            NSArray *fileInfos = [souce valueForKey:KEY_MULTY_VIDEO_FILE_INFO];
            //发射
            [self launchPlayThreadWithChannelId:chnId withVideoInfos:fileInfos];
        }
    
        return YES;
    }
    
    return NO;
}

- (void)resume
{
    [self.frameSignal lock];
    [self setShouldPausePlaying:NO];
    [self.frameSignal broadcast];
    [self.frameSignal unlock];
}

- (void)nextFrame{
    [self.frameSignal lock];
    //通知播放线程
    for (NSDictionary *args in self.playerRunArgcs) {
        [args setValue:[NSNumber numberWithBool:YES] forKey:KEY_NEXT_FRAME];
    }
    [self setShouldPausePlaying:YES];
    [self.frameSignal broadcast];
    [self.frameSignal unlock];
}

- (void)pause
{
    [self.frameSignal lock];
    [self setShouldPausePlaying:YES];
    [self.frameSignal unlock];
}

- (void)stop
{
    //防因为文件播放完，被挂起的通道
    if (!self.shouldStopPlaying) {
        [self setSeekDate:nil];
        [self.frameSignal lock];
        
        self.shouldStopPlaying = YES;
        self.shouldPausePlaying =NO;
        //唤醒线程
        [self.frameSignal broadcast];
        [self.frameSignal unlock];
        
        //等待各通道线程结束
        for (PlayerLaunchArgcs *argcs in self.playerLaunchArgcs.allValues) {
            void *retval;
            pthread_join(argcs.hThread, &retval);
        }
        
        //清除各通道
        [self.playerLaunchArgcs removeAllObjects];
        [self.playSources removeAllObjects];
        [self.playerRunArgcs removeAllObjects];
        [self postNotification:VIDEO_PLAYER_DID_STOP_NOTIFICATION];
    }
}

- (void)slow
{
    [self.frameSignal lock];
    if (self.speed > SPEED_MIN) {
        self.speed /= 2.0;
        self.shouldPausePlaying = NO;
        [self.frameSignal broadcast];
    }
    [self.frameSignal unlock];
}

- (void)fast
{
    [self.frameSignal lock];
    if (self.speed < SPEED_MAX) {
        self.speed *= 2.0;
        self.shouldPausePlaying = NO;
        [self.frameSignal broadcast];
    }
    [self.frameSignal unlock];
}

- (BOOL)existPausingChannel
{
    return self.pausingChannelCount != 0;
}

#pragma mark - do data
static void *doDataCB(void* pParam)
{
    @autoreleasepool {
        if(pParam != NULL)
        {
            PlayerLaunchArgcs *argcs = (__bridge PlayerLaunchArgcs *)(pParam);
            [argcs.player playRoutine:argcs];
        }
    }
    
    return 0;
}

#pragma mark - private method
- (void)launchPlayThreadWithChannelId :(int)channelId
                       withVideoInfos :(NSArray *)videoInfos
{
    PlayerLaunchArgcs *argcs = [[PlayerLaunchArgcs alloc] init];
    [self.playerLaunchArgcs setValue:argcs forKey:[NSString stringWithFormat:@"%d",channelId]];
    
    argcs.hThread = 0;
    argcs.player = self;
    argcs.channelId = channelId;
    argcs.videoInfos = videoInfos;
    
    pthread_t hThread;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    
    if (0 == pthread_create(&hThread, &attr, doDataCB, (__bridge void *)argcs)) {
        argcs.hThread = hThread;
    }
}

//广播数据帧
- (void)broadcastFrame :(void *)bytes
                length :(size_t)length
                  type :(int)type
             timestamp :(double)timestamp
             channelId :(int)channelId
{
    if (!bytes || length == 0)
        return;
    
    NSArray *observers = [NSArray arrayWithArray:self.observers];
    for (id<VideoPlayerProtocol> observer in observers) {
        if ([observer respondsToSelector:@selector(videoPlayer:didReadData:length:type:timeStamp:channelId:)])
            [observer videoPlayer:self
                      didReadData:bytes
                           length:length
                             type:type
                        timeStamp:timestamp
                        channelId:channelId];
    }
    
    self.progressDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
}

//播放线程投递消息给其它线程
- (void)postNotification :(NSString *)name
{
    NSNotification *aNotific = [[NSNotification alloc] initWithName:name
                                                             object:self
                                                           userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:aNotific];
}

//同步各通道
- (BOOL)syncChannels :(NSDictionary *)args
{
    //查看其它线程参数
    //int chnId = [[args valueForKey:KEY_CHNNEL_ID] intValue];
    //TRACE_CHANNEL(chnId, @"进入syncChannels :");
    
    BOOL success = NO;
    BOOL seek = NO;
    
    do {
        //查看是最小帧
        BOOL existEmptyChannel = NO;
        NSDictionary *minArgs = nil;

        [self.frameSignal lock];
        seek = [[args valueForKey:KEY_SEEK] boolValue];
        [self.frameSignal unlock];
        
        [self.timestampLock lock];
        for (NSDictionary *tdArgs in self.playerRunArgcs) {
            NSNumber *timestamp = [tdArgs valueForKey:KEY_CUR_TIME_STAMP];
            NSNumber *endFiles = [tdArgs valueForKey:KEY_END_FILES];
            
            if (endFiles.boolValue)
                continue;
            
            if (!minArgs)
                minArgs = tdArgs;
            
            if (!timestamp) {
                existEmptyChannel = YES;
                break;
            }
            
            if ([timestamp isLessThan:[minArgs valueForKey:KEY_CUR_TIME_STAMP]])
                minArgs = tdArgs;
        }
        [self.timestampLock unlock];
        
        if (!existEmptyChannel && (args == minArgs)) {
            success = YES;
            break;
        } else
            usleep(SYNC_WAIT_USECS);
    } while (!seek &&
             !self.shouldStopPlaying &&
             !self.shouldPausePlaying);
    
    //TRACE_CHANNEL(chnId, @"退出syncChannels :");
    return success;
}

#ifdef DEBUG
#define MAX_FRAME_INTERVAL  100.0
#else
#define MAX_FRAME_INTERVAL  100.0
#endif

//播放录像文件
- (VP_RESULT)playFile :(NSDictionary *)args
{
    
    NSDate          *seekDate   = [args valueForKey:KEY_SEEK_DATE];
    int             chnId       = [[args valueForKey:KEY_CHANNEL_ID] intValue];
    double          speed       = [[args valueForKey:KEY_SPEED] doubleValue];
    NSString        *path       = [args valueForKey:KEY_FILE_PATH];
    VP_RESULT       result      = VP_DONE;
    
    TRACE_CHANNEL(chnId, @"开始播放文件");
    
    if (!path || chnId < 0 || speed == 0)
        return VP_INTERRUPT_STOP;
    
    VideoFileReader *reader = [[VideoFileReader alloc] initWithFilePath:path];
    [reader open];
    [reader seekWithDate:seekDate];
    
    //准备buffer
    char *buffer = (char *)malloc(sizeof(char) * BUFFER_SIZE);
    memset(buffer, 0, BUFFER_SIZE);
    
    //参考时间
    BOOL reset = YES;
    NSTimeInterval playRefTimestamp = 0;
    NSTimeInterval fileRefTimestamp = 0;
    NSTimeInterval curFrameTimestamp = 0;
    NSTimeInterval preFrameTimestamp = 0;
    
    //类型与帧长度
    int type = 0;
    size_t length = 0;
    BOOL bFrame = NO;
    
    //抽帧计数
    while ((result == VP_DONE) && (bFrame ||
           ((length = [reader read:buffer size:BUFFER_SIZE type:&type timestamp:&curFrameTimestamp]),length > 0))) {
        
        double waitintSec = 0;
    
        switch (type) {
            case DATA_TYPE_AUDIO:
                [self broadcastFrame:buffer length:length type:type timestamp:curFrameTimestamp channelId:chnId];
                break;
            case DATA_TYPE_VIDEO: {
                int frameType = video_frame_type((unsigned char *)buffer, (int)length);//buffer[4]&0x1f;
                int iSpeed = (int)speed;
            
                if ((iSpeed > 1) && !(frameType == VIDEO_SPS_FRAME || frameType == VIDEO_I_FRAME || frameType == VIDEO_PPS_FRAME))
                    break;
                
                [self.timestampLock lock];
                [args setValue:[NSNumber numberWithDouble:curFrameTimestamp] forKey:KEY_CUR_TIME_STAMP];
                [self.timestampLock unlock];
                
                bFrame = YES;
                if ([self syncChannels:args]) {
                    [self broadcastFrame:buffer length:length type:type timestamp:curFrameTimestamp channelId:chnId];
                    
                    //NSLog(@"timestamp = %lf,frameType = %d",curFrameTimestamp,frameType);
                    //计算等待时间
                    if (reset) {
                        TRACE_CHANNEL(chnId, @"重置参考时间");
                        playRefTimestamp = [[NSDate date] timeIntervalSince1970];
                        fileRefTimestamp = curFrameTimestamp;
                        reset = NO;
                    }
                    
                    if (preFrameTimestamp == 0) {
                        preFrameTimestamp = curFrameTimestamp;
                    }
                    
                    NSTimeInterval span = curFrameTimestamp - preFrameTimestamp;
                    NSTimeInterval t1 = [[NSDate date] timeIntervalSince1970] - playRefTimestamp;//实际距离首帧播放的时间
                    NSTimeInterval t2 = (curFrameTimestamp - fileRefTimestamp) / speed;//理论上距离上一帧的时间间隔
                    
                    preFrameTimestamp = curFrameTimestamp;
                    waitintSec = (t2 - t1);
                    
                    //超时，不等待
                    if (waitintSec < 0.0) {
                        waitintSec = 0.0;
                    }
                    
                    //帧间隔超过一秒，自动重置，并取消等待
                    if (span > MAX_FRAME_INTERVAL) {
                        waitintSec = 0.0;
                        NSLog(@"span greater than 100.0 sec");
                    }
                    
                    bFrame = NO;
                    
#if 0
                    NSLog(@"span = %lf",waitintSec);
#endif
                }
                
                break;
            }
            default:
                break;
        }
        
        //处理事件
        [self.frameSignal lock];
        if (self.shouldStopPlaying) {
            TRACE_CHANNEL(chnId, @"截获到STOP事件!!");
            result = VP_INTERRUPT_STOP;
        } else if ([[args valueForKey:KEY_SEEK] boolValue]) {
            TRACE_CHANNEL(chnId, @"截获到SEEK事件!!");
            result = VP_INTERRUPT_SEEK;
            [args setValue:[NSNumber numberWithBool:NO] forKey:KEY_SEEK];
            [args setValue:self.seekDate forKey:KEY_SEEK_DATE];
        } else if (self.speed != speed) {
            TRACE_CHANNEL(chnId, @"截获到SPEED事件!!");
            speed = self.speed;
            reset = YES;
        } else if ([[args valueForKey:KEY_NEXT_FRAME] boolValue]) {
            TRACE_CHANNEL(chnId, @"截获到NEXT_FRAME事件!!");
            [args setValue:[NSNumber numberWithBool:NO] forKey:KEY_NEXT_FRAME];
        } else if (self.shouldPausePlaying) {
            TRACE_CHANNEL(chnId, @"截获到PAUSE事件!!");
            if (++self.pausingChannelCount == self.playSources.count)
                [self postNotification:VIDEO_PLAYER_WILL_PAUSE_NOTIFICATION];
            //查看是否有下一帧命令，如果有，不等待，快速播放这一帧
            [self.frameSignal wait];
            TRACE_CHANNEL(chnId, @"截获到RESUME事件!!");
            if (--self.pausingChannelCount == 0)
                [self postNotification:VIDEO_PLAYER_DID_RUSUME_NOTIFICATION];
            reset = YES;
        } else {
            //NSLog(@"3");
            [self.frameSignal waitUntilDate:[[NSDate date] dateByAddingTimeInterval:waitintSec]];
            //NSLog(@"4");
        }
        
        [self.frameSignal unlock];
    }
    //销毁缓冲区
    free(buffer);
    
    [reader close];
    TRACE_CHANNEL(chnId, @"结束播放文件");
    return result;
}


- (int)playRoutine :(PlayerLaunchArgcs *)launchArgcs
{
    NSArray             *videoInfos = launchArgcs.videoInfos;
    int                 chnId       = launchArgcs.channelId;
    NSMutableDictionary *threadArgs = [[NSMutableDictionary alloc] init];
    
    //初始化线程参数
    [threadArgs setValue:[NSNumber numberWithInt:chnId] forKey:KEY_CHANNEL_ID];
    [threadArgs setValue:[NSNumber numberWithBool:NO] forKey:KEY_SEEK];
    [threadArgs setValue:nil forKey:KEY_SEEK_DATE];
    [threadArgs setValue:nil forKey:KEY_CUR_TIME_STAMP];
    
    [self.timestampLock lock];
    [self.playerRunArgcs addObject:threadArgs];
    [self.timestampLock unlock];
    
    //回调通知
    [self postNotification:VIDEO_PLAYER_WILL_PLAY_NOTIFICATION];
    
    while (!self.shouldStopPlaying) {
        int index = 0;
        BOOL interrupt = NO;
        //遍历所有文件，顺序播放
        while (!interrupt && (index < videoInfos.count)) {
            NSDictionary *fileInfo = videoInfos[index++];
            NSDate *fileEndDate = [fileInfo valueForKey:KEY_DATE_END];
            NSDate *seekDate = [threadArgs valueForKey:KEY_SEEK_DATE];
            NSString *path = [fileInfo valueForKey:KEY_VIDEO_FILE_PATH];
            //查看文件是否已经过期
            if (NSOrderedDescending == [seekDate compare:fileEndDate])
                continue;
            
            //准备参数
            [threadArgs setValue:[NSNumber numberWithDouble:self.speed] forKey:KEY_SPEED];
            [threadArgs setValue:path forKey:KEY_FILE_PATH];
            [self.timestampLock lock];
            [threadArgs setValue:[NSNumber numberWithBool:NO] forKey:KEY_END_FILES];
            [self.timestampLock unlock];
            
            switch ([self playFile:threadArgs]) {
                case VP_DONE:
                    [threadArgs setValue:nil forKey:KEY_SEEK_DATE];
                    break;
                case VP_INTERRUPT_STOP:
                    [threadArgs setValue:[NSNumber numberWithBool:YES] forKey:KEY_SEEK];
                    interrupt = YES;
                    break;
                case VP_INTERRUPT_SEEK:
                    [self.timestampLock lock];
                    [threadArgs setValue:nil forKey:KEY_CUR_TIME_STAMP];
                    [self.timestampLock unlock];
                    index = 0;
                    break;
                default:
                    break;
            }
        }
        
        //所有文件播放完毕
        [self.timestampLock lock];
        [threadArgs setValue:[NSNumber numberWithBool:YES] forKey:KEY_END_FILES];
        [self.timestampLock unlock];
        
        //所有文件播放完毕，等待seek信号
        [self.frameSignal lock];
        if (![[threadArgs valueForKey:KEY_SEEK] boolValue]) {
            [self.frameSignal wait];
            //seek信号被触发,更新seek日期
            [threadArgs setValue:[NSNumber numberWithBool:NO] forKey:KEY_SEEK];
            [threadArgs setValue:self.seekDate forKey:KEY_SEEK_DATE];
        }
        [self.frameSignal unlock];
    }
    
    TRACE_CHANNEL(chnId, @"播放线程退出!");
    return 0;
}

#pragma mark - setter && getter
- (void)setSpeed:(double)speed
{
    if (_speed != speed) {
        _speed = speed;
        [self postNotification:VIDEO_PLAYER_SPEED_DID_CHANGE_NOTIFICATION];
    }
}


- (void)setSeekDate:(NSDate *)seekDate
{
    [self.frameSignal lock];
    _seekDate = seekDate;
    
    //通知播放线程
    for (NSDictionary *args in self.playerRunArgcs) {
        [args setValue:[NSNumber numberWithBool:YES] forKey:KEY_SEEK];
    }
    [self.frameSignal broadcast];
    [self.frameSignal unlock];
}

- (NSMutableArray *)observers
{
    if (!_observers) {
        _observers = [[NSMutableArray alloc] init];
    }
    
    return _observers;
}
@end
