//
//  VideoFileManager.m
//  VMS
//
//  Created by mac_dev on 15/8/4.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VideoFileWriter.h"
#import <sys/time.h>
#import <sys/dir.h>
#import "pthread_auto_lock.h"

#define BUFSIZE     1048576
#define SEC_PER_DAY 86400.0
#define BUFFER_COUNT    2
#define VIDEO_FILE_WRITER_DEBUG           0

@interface VideoFileWriter() {
    FILE *_stream;
    RECORD_FILE_HEAD_INFO _file_head_info;
    RECORD_FILE_INDEX_INFO _file_index_info;
    pthread_mutex_t _mutex;
}

@property (copy,nonatomic) NSString *path;
@property (assign,readwrite) VIDEO_FILE_CONSTRAINT constraint;
@property (assign,readwrite) int type;
@property (nonatomic,strong) NSDate *beginDate;
@property (nonatomic,strong) NSDate *endDate;

@end

@implementation VideoFileWriter

#pragma mark - init & dealloc
- (instancetype)initWithType :(int)type
{
    //使用默认的文件约束条件
    if (self = [super init]) {
        VIDEO_FILE_CONSTRAINT constraint;
        constraint.type = 1;
        constraint.time_interval_max = 15 * 60;
        constraint.length_max = 100;
        
        self.constraint = constraint;
        self.type = type;
        self.path = nil;
        self.beginDate = nil;
        self.endDate = nil;
        
        memset(&_file_head_info, 0, sizeof(RECORD_FILE_HEAD_INFO));
        memset(&_file_index_info, 0, sizeof(RECORD_FILE_INDEX_INFO));
        _stream = NULL;
        
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
        
        pthread_mutex_init(&_mutex, NULL);
        pthread_mutex_init(&_mutex, &attr);
    }
    
    return self;
}

- (instancetype)initWithFileConstraint:(VIDEO_FILE_CONSTRAINT)constraint
                                  type:(int)type
{
    if (self = [super init]) {
        self.constraint = constraint;
        self.type = type;
    }
    
    return self;
}

- (id)initWithFileConstraint :(VIDEO_FILE_CONSTRAINT)constraint
                        type :(int)type
                        path :(NSString *)path
{
    if (self = [super init]) {
        self.constraint = constraint;
        self.type = type;
    }
    
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - public api
- (size_t)fileSize
{
    if (_stream) return ftell(_stream);
    return 0;
}

- (VFW_RESULT)createFileForChannel :(Channel *)chn path :(NSString *)path
{
    pthread_auto_lock lk(&(_mutex));
    
    if(VIDEO_FILE_WRITER_DEBUG)
        NSLog(@"开始创建文件.");
    
    if (!chn) return VFW_NULL_CHANNEL;
    if (!path) return VFW_EMPTY_PATH;
    if (_stream) return VFW_FILE_ALREADY_OPENED;
    
    @try {
        //询问是否可以创建文件
        BOOL stop = NO;
        id<VideoFileWriterDelegate> del = self.delegate;
        if ([del respondsToSelector:@selector(willWriteToDisk:stop:)]) {
            NSNotification *aNotific = [[NSNotification alloc] initWithName:NOTIFICATION_VIDEO_DATA_WILL_WRITE_TO_DISK
                                                                     object:self
                                                                   userInfo:nil];
            
            [del willWriteToDisk:aNotific stop:&stop];
        }
        
        if (stop) return VFW_DISK_SPACE_NOT_ENOUGH;
        
        //新建文件
        NSString *start = @"PlaceHolder";//占位符
        NSString *dir = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%d_%@",chn.uniqueId,chn.name]];
        NSString *filePath = [NSString stringWithFormat:@"%@/%d__%@",dir,self.type,start];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        _stream = fopen([filePath UTF8String], "wb+");
        
        if (_stream) {
            self.path = dir;
            //配置通道信息
            _file_head_info.Ver = RECORD_FILE_VERSION;
            _file_head_info.RecordType = self.type;
            _file_head_info.EncodeType = 0;//Todo :modify
            _file_head_info.ChannelID = chn.uniqueId;
            _file_head_info.fps = 0.0;
            _file_head_info.SamplesPerSec = 0;
            _file_head_info.BitsPerSample = 0;
            _file_head_info.Channel = 0;
            _file_head_info.UnUse1 = 0;
            _file_head_info.UnUse2 = 0;
            _file_head_info.UnUse3 = 0;
            _file_head_info.UnUse4 = 0;
            _file_head_info.IP[0] = 0;
            _file_head_info.ChannelName[0] = 0;
            
            //初始化块索引
            _file_index_info.Count = 0;
            _file_index_info.Size = RECORD_FILE_INDEX_LEN;
            for (int i = 0; i < RECORD_FILE_INDEX_LEN; i++) {
                _file_index_info.Index[i].FileOffset = 0;
                _file_index_info.Index[i].TimeOffset = 0;
            }
            
            if ([self fwriteWithBuffer:&_file_head_info size:sizeof(RECORD_FILE_HEAD_INFO) count:1 stream:_stream] > 0 &&
                [self fwriteWithBuffer:&_file_index_info size:sizeof(RECORD_FILE_INDEX_INFO) count:1 stream:_stream] > 0) {
                
                if(VIDEO_FILE_WRITER_DEBUG)
                    NSLog(@"创建文件成功!");
                
                return VFW_SUCCESS;
            }
            
            return VFW_DISK_SPACE_NOT_ENOUGH;
            
        } else {
            return VFW_OPEN_FILE_FAILED;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"创建文件时发生了异常，终止应用程序，错误代码%d,信息%@",errno,exception);
        exit(0);
    }
}

- (VFW_RESULT)close
{
    pthread_auto_lock lk(&(_mutex));
    
    if (NULL == _stream) {
        return VFW_FILE_NOT_OPEN;
    }
    
    @try {
        NSDate *endDate = self.endDate;
        if (!endDate) {
            fclose(_stream);
            _stream = NULL;
            return VFW_INVALID_END_DATE;
        }
        
        //结束当前文件会话，关闭文件
        //首先更新文件大小
        _file_head_info.Len = (int)ftell(_stream);
        _file_head_info.StartTime = [self.beginDate oleTimeStamp];
        _file_head_info.EndTime = [endDate oleTimeStamp];
        fseek(_stream, 0, SEEK_SET);//移动到文件头
        
        BOOL flag =
        ([self fwriteWithBuffer:&_file_head_info size:sizeof(RECORD_FILE_HEAD_INFO) count:1 stream:_stream] > 0) &&
        ([self fwriteWithBuffer:&_file_index_info size:sizeof(RECORD_FILE_INDEX_INFO) count:1 stream:_stream] > 0);
       
        //定位到文件结尾
        fclose(_stream);
        
        _stream = NULL;
        self.beginDate = nil;
        self.endDate = nil;
        
        //rename the file
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
        
        NSString *start = [formatter stringFromDate:[NSDate dateWithOleTimeStamp:_file_head_info.StartTime]];
        NSString *end   = [formatter stringFromDate:[NSDate dateWithOleTimeStamp:_file_head_info.EndTime]];
        NSString *path  = self.path;
        NSString *old_file_path = [NSString stringWithFormat:@"%@/%d__%@",path,self.type,@"PlaceHolder"];
        NSString *new_file_path = [NSString stringWithFormat:@"%@/%d__%@___%@.vms",path,self.type,start,end];
        
        if (flag) {
            rename(old_file_path.UTF8String, new_file_path.UTF8String);
            return VFW_SUCCESS;
        }
        else {
            remove(old_file_path.UTF8String);
            return VFW_DISK_SPACE_NOT_ENOUGH;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"关闭文件时发生了异常,错误码%d,信息%@",errno,exception);
        exit(0);
    }
}

- (VFW_RESULT)writeFileWithBuffer :(const void *)bytes
                           length :(size_t)len
                           bengin :(NSDate *)begin
                              end :(NSDate *)end
{
    pthread_auto_lock lk(&(_mutex));
    
    if (bytes == NULL || len == 0)
        return VFW_BAD_DATA;
    
    if (!_stream)
        return VFW_NO_FILE;
    
    if (!self.beginDate) {
        //第一块数据
        self.beginDate = begin;
    }
    
    BOOL    shouldCreateNewFile = NO;
    NSDate  *now = [NSDate date];
    NSDate  *expectedEndDate = [self.beginDate dateByAddingTimeInterval:self.constraint.time_interval_max];
    size_t  expectedFileSize = self.constraint.length_max * (1024 * 1024);
    
    switch (self.constraint.type) {
        case 1: //按时间
            shouldCreateNewFile = ([now compare:expectedEndDate] != NSOrderedAscending);
            break;
        case 2: //按文件大小
            shouldCreateNewFile = ([self fileSize] >= expectedFileSize);
            break;
        case 3://任意一种
            shouldCreateNewFile = ([now compare:expectedEndDate] != NSOrderedAscending) || ([self fileSize] >= expectedFileSize);
            break;
        default:
            break;
    }
    
    //查看是否需要新起一个文件
    if (shouldCreateNewFile)
        return VFW_NEW_FILE;
    
    @try {
        //将数据块写入文件中
        //往文件中写入数据
        //纪录起始时间
        NSDate          *bootDate   = [NSDate bootDate];
        int             file_offset = (int)ftell(_stream);//数据块文件偏移
        int             data_index  = _file_index_info.Count;
        unsigned int    usec        = [begin timeIntervalSinceDate:bootDate] * 1000;
        assert(data_index < RECORD_FILE_INDEX_LEN);
        
        //将缓冲区写入文件
        size_t cnt = [self fwriteWithBuffer:bytes size:len count:1 stream:_stream];
        
        if (cnt > 0) {
            [self setEndDate:end];
            
            //更新数据块索引
            _file_index_info.Index[data_index].FileOffset = file_offset;
            _file_index_info.Index[data_index].TimeOffset = usec;
            _file_index_info.Count++;
            
            return VFW_SUCCESS;
        }
        else {
            return VFW_DISK_SPACE_NOT_ENOUGH;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception raised when write buffer to file:%@",exception);
        exit(0);
    }
}

#pragma mark - private method
- (size_t)fwriteWithBuffer :(const void *)buffer
                      size :(size_t)size
                     count :(size_t)count
                    stream :(FILE *)stream
{
    id<VideoFileWriterDelegate> delegate = self.delegate;
    BOOL stop = YES;
    
    if ([delegate respondsToSelector:@selector(willWriteToDisk:stop:)]) {
        NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:size],KEY_VIDEO_DATA_LEN, nil];
        NSNotification *aNotific = [[NSNotification alloc] initWithName:NOTIFICATION_VIDEO_DATA_WILL_WRITE_TO_DISK
                                                                 object:self
                                                               userInfo:userInfo];
        [delegate willWriteToDisk:aNotific stop:&stop];
    }
    
    return stop? 0 : fwrite(buffer, size, count, stream);
}

- (NSString *)errMsg :(VFW_RESULT)result
{
    pthread_auto_lock lk(&(_mutex));
    
    NSString *msg = @"Unknow err";
    
    switch (result) {
        case VFW_SUCCESS:
            msg = @"NO err";
            break;
        case VFW_BAD_DATA:
            msg = @"Bad pointer";
            break;
        case VFW_NO_FILE:
            msg = @"File not created";
            break;
        case VFW_NEW_FILE:
            msg = @"Beyond file constraints";
            break;
        case VFW_NULL_CHANNEL:
            msg = @"Null channel";
            break;
        case VFW_INVALID_PATH:
            msg = @"Invalid path";
            break;
        case VFW_EMPTY_PATH:
            msg = @"Empty path";
            break;
        case VFW_OPEN_FILE_FAILED:
            msg = @"Failed to open file";
            break;
        case VFW_INVALID_END_DATE:
            msg = @"Invalid end date";
            break;
        case VFW_FILE_ALREADY_OPENED:
            msg = @"File already opened";
            
        case VFW_DISK_SPACE_NOT_ENOUGH:
            msg = @"Disk space not enough";
        default:
            break;
    }
    return msg;
}

@end

