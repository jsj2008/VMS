//
//  VideoRecorder.m
//  
//
//  Created by mac_dev on 16/3/11.
//
//

#import "VideoRecorder.h"
#import "RingQueue.h"
#import "NSString+VMSVideoFileName.h"

#define VIDEO_RECORDER_DEBUG    1
#define DATA_QUEUE_LENGTH   1*1024*1024
#define BUFSIZE     1048576
#define SEC_PER_DAY 86400.0
#define BUFFER_COUNT    2

#define RECORDER_TRACE(msg)  if(1) NSLog(@"记录者%p:%@",self,msg);

@interface VideoRecorder() {
    RingQueue   _dataQueue;
}

@property (readwrite) Channel *chn;
@property (nonatomic,assign) NSUInteger option;
@property (nonatomic,strong) NSArray *writers;
@property (nonatomic,strong) NSCondition *triggerSignal;
@property (nonatomic,strong) NSArray *buffers;//双缓冲区
@property (nonatomic,assign) NSInteger curBufIdx;//当前Buffer索引

@end


@implementation VideoRecorder

#pragma mark - publick method
- (instancetype)initWithChannel:(Channel *)chn;
{
    if (self = [super init]) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        for (int i = 0;i < 3;i++) {
            VideoFileWriter *writer = [[VideoFileWriter alloc] initWithType:i];
            [writer setDelegate:self];
            [arr addObject:writer];
        }
        
        NSMutableArray *bufs = [[NSMutableArray alloc] init];
        for (int i = 0;i < BUFFER_COUNT;i++) {
            VideoBuffer *buf = [[VideoBuffer alloc] initWithSize:DATA_QUEUE_LENGTH];
            [buf setIdx:i];
            [bufs addObject:buf];
        }
        
        self.rs = [[VMSRecordSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
        self.chn = chn;
        self.buffers = [NSArray arrayWithArray:bufs];
        self.writers = [NSArray arrayWithArray:arr];
        self.triggerSignal = [[NSCondition alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [self stop:AllRecord];
}

- (void)setRs:(VMSRecordSetting *)rs
{
    [self.triggerSignal lock];
    _rs = rs;
    [self.triggerSignal unlock];
}

- (void)inputData :(void *)bytes length :(int)len type :(int)type
{
    if (bytes == NULL)
        return;
    
    if (len == 0)
        return;
    
    unsigned int realType = DATA_TYPE_AUDIO;
    switch (type) {
        case DATA_TYPE_AUDIO_PCM:
            realType = DATA_TYPE_AUDIO;
            break;
        case DATA_TYPE_VIDEO_H264:
            realType = DATA_TYPE_VIDEO;
            break;
        default:
            assert(false);
            NSLog(@"警告!!!录像数据类型错误,应用程序退出!");
            exit(0);
            break;
    }
    
    _dataQueue.enqueue(bytes, len, realType);
    
    [self.triggerSignal lock];
    [self.triggerSignal signal];
    [self.triggerSignal unlock];
}


- (void)start :(RecordType)type
{
    [self.triggerSignal lock];
    //还未开启任何录像
    if (self.option == 0) {
        _dataQueue.init(DATA_QUEUE_LENGTH);
        [NSThread detachNewThreadSelector:@selector(recordRoutine:) toTarget:self withObject:nil];
    }
    
    
    self.option |= type;
    [self.triggerSignal unlock];
}

- (void)stop :(RecordType)type
{
    [self.triggerSignal lock];
    VideoBuffer *curBuf = [self.buffers objectAtIndex:self.curBufIdx];
    for (int i = 0; i < 3; i++) {
        if (type & (1<<i)) {
            VideoFileWriter *writer = self.writers[i];
            [writer writeFileWithBuffer:curBuf.bytes length:curBuf.length bengin:curBuf.beginDate end:curBuf.endDate];
            [writer close];
            break;
        }
    }
    [self.triggerSignal signal];
    self.option &= ~type;
    [self.triggerSignal unlock];
}

- (BOOL)isRecording :(RecordType)type
{
    [self.triggerSignal lock];
    BOOL result = self.option & type;
    [self.triggerSignal unlock];
    return result;
}

#pragma mark - private method
//将数据帧写入缓冲区
- (BOOL)writeBufferWithData :(void *)bytes
                     length :(size_t)len
                       type :(int)type
{
    //将数据帧进队列的时刻作为当前时刻
    NSDate          *now        = [NSDate date];
    NSDate          *bootDate   = [NSDate bootDate];//开机时间
    VideoBuffer     *curBuffer  = [self.buffers objectAtIndex:self.curBufIdx];
    unsigned int    usec        = [now timeIntervalSinceDate:bootDate] * 1000;
    
    if ([curBuffer length] + sizeof(RECORD_FILE_DATA_INFO) + len > BUFSIZE) {
        //将当前buffer标记为已经填装满
        curBuffer.full = YES;
        //当前buffer 已经填装满,自动移到下一个buffer
        self.curBufIdx = (self.curBufIdx + 1) % BUFFER_COUNT;
        curBuffer = [self.buffers objectAtIndex:self.curBufIdx];
    }
    
    if (curBuffer.isFull)
        return NO;
    
    if ([curBuffer length] == 0)
        curBuffer.beginDate = now;
    
    //记录Buffer的结束时间
    curBuffer.endDate = now;
    //打包数据
    RECORD_FILE_DATA_INFO file_data_info;//数据头
    file_data_info.Len = (int)len;
    file_data_info.TimeStamp = usec;
    file_data_info.Type = type;
    
    [curBuffer appendBytes:&file_data_info length:sizeof(RECORD_FILE_DATA_INFO)];
    [curBuffer appendBytes:bytes length:len];

    return YES;
}

- (void)recordRoutine :(id)args
{
    size_t  capacity    = 1024*1024*1;
    char    *buf        = new char[capacity];

    memset(buf, 0, capacity);
    //开始Loop
    while (YES) {
        //等待结束信号
        [self.triggerSignal lock];
        //查看是否还有录像
        if (self.option == 0) {
            [self.triggerSignal unlock];
            break;
        } else
            [self.triggerSignal wait];
        
        //取出对列中的数据，写入文件中
        size_t count = _dataQueue.count();
        for (int i = 0;i < count;i++) {
            double type  = 0.0;
            size_t len   = _dataQueue.dequeue(buf, capacity, type);
            
            if (len == 0)
                continue;
            
            if (![self writeBufferWithData:buf length:len type:type]) {
                RECORDER_TRACE(@"记录者:数据写入Buffer失败");
                break;
            }
            
            //查看是否有装满的buffer
            for (VideoBuffer *buf in self.buffers) {
                if (buf.isFull) {
                    for (int i = 0; i < 3; i++) {
                        RecordType type = 1 << i;
                        if ((self.option & type) == type) {
                            VideoFileWriter *writer = self.writers[i];
                            VFW_RESULT ret = [writer writeFileWithBuffer:buf.bytes length:buf.length bengin:buf.beginDate end:buf.endDate];
                            
                            switch (ret) {
                                case VFW_SUCCESS: {
                                    NSString *msg = [NSString stringWithFormat:@"Buffer 长度 %ld,写入文件成功!",buf.length];
                                    RECORDER_TRACE(msg);
                                }
                                    break;
                                    
                                case VFW_NO_FILE:
                                case VFW_NEW_FILE: {
                                    [writer close];
                                    VFW_RESULT v = [writer createFileForChannel:self.chn
                                                                           path:[self.rs.recordingPathName stringByAppendingPathComponent:RECORD_FILE_FOLDER]];
                                    
                                    if (v == VFW_SUCCESS) {
                                        [writer writeFileWithBuffer:buf.bytes
                                                             length:buf.length
                                                             bengin:buf.beginDate
                                                                end:buf.endDate];
                                    }
                                    else {
                                        NSString *msg = [NSString stringWithFormat:@"创建录像文件失败,失败原因%@",[writer errMsg :v]];
                                        RECORDER_TRACE(msg);
                                    }
                                }
                                    break;
                                default: {
                                    NSString *msg = [NSString stringWithFormat:@"数据写入文件失败,失败原因%@",[writer errMsg :ret]];
                                    RECORDER_TRACE(msg);
                                }
                                    break;
                                    
                            }
                        }
                    }
                    
                    [buf clear];
                    break;
                }
            }
        }
        
        [self.triggerSignal unlock];
    }

    //处理停止录像后的动作
    delete[] buf;
    for (VideoBuffer *vb in self.buffers)
        [vb clear];
    
    NSLog(@"退出文件写线程");
}



#pragma mark - video file writer delegate
- (void)willWriteToDisk:(NSNotification *)aNotific stop:(BOOL *)stop
{
    *stop = [DiskManager diskUsage] >= DISK_TOLERANCE;
}

@end
