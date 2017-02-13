//
//  VideoFileReader.m
//  VMS
//
//  Created by mac_dev on 15/8/19.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//


#import "VideoFileReader.h"
#define KEY_DATE_BEGIN      @"begin"
#define KEY_DATE_END        @"end"
#define KEY_PATH            @"path"


@interface VideoFileReader() {
    FILE *_stream;
    RECORD_FILE_HEAD_INFO _file_head_info;
    RECORD_FILE_INDEX_INFO _file_index_info;
    unsigned int _firstDataBlockTimeStamp;//第一块数据事件戳
}
@property (readwrite) NSString *path;
@end

@implementation VideoFileReader
#pragma mark - init
- (void)dealloc
{
    if (_stream) {
        [self close];
    }
}

- (id)initWithFilePath:(NSString *)path
{
    if (self = [super init]) {
        self.path = path;
    }
    return self;
}

#pragma mark - public api
//开始日期
- (NSDate *)begin
{
    NSDate *begin = nil;
    if (_stream)
        begin = [NSDate dateWithOleTimeStamp:_file_head_info.StartTime];
    
    NSLog(@"Begin = %@",begin);
    return begin;
}

//结束日期
- (NSDate *)end
{
    NSDate *end = nil;
    if (_stream)
        end = [NSDate dateWithOleTimeStamp:_file_head_info.EndTime];
    
    
    NSLog(@"End = %@",end);
    return end;
}

- (int)type
{
    if (_stream)
        return _file_head_info.RecordType;

    return 0;
}

//通道ID
- (Channel *)channel
{
    Channel *channel = nil;
    if (_stream) {
        int channelId = _file_head_info.ChannelID;
        NSString *name = [NSString stringWithUTF8String:_file_head_info.ChannelName];
        channel = [[Channel alloc] initWithUniqueId  :channelId name :name type :0
                                             logicId :0 unused1 :0 unused2:0 mapX:@""
                                                 mapY:@"" patrolGroupId:-1 CDevice:nil];
    }
    
    return channel;
}

- (void)open
{
    if (!_stream && self.path) {
        _stream = fopen([self.path UTF8String], "rb");
        if (_stream) {
            //更新文件头
            fread(&_file_head_info, sizeof(RECORD_FILE_HEAD_INFO), 1, _stream);
            //更新数据块索引
            fread(&_file_index_info, sizeof(RECORD_FILE_INDEX_INFO), 1, _stream);
            //更新第一数据块时间戳
            if (_file_index_info.Count > 0) {
                _firstDataBlockTimeStamp = _file_index_info.Index[0].TimeOffset;
            }
        } else
            NSLog(@"Failed to open file");
    }
}

- (void)close
{
    if (_stream) {
        fclose(_stream);
        _stream = NULL;
    }
    
}

- (void)seekWithDate :(NSDate *)date
{
    if (_stream) {
        double secOffset = date? ([date timeIntervalSince1970] - ([[NSDate dateWithOleTimeStamp:_file_head_info.StartTime] timeIntervalSince1970])) : 0;
        if (secOffset < 0)
            secOffset = 0;//时间还没到达，跳转到起始时间间
        
        //根据数据块索引快速定位所在数据块
        unsigned int msecOffset = 1000 * secOffset;
        int index = -1;
        for (int i = 0; i < _file_index_info.Count; i++) {
            RECORD_FILE_INDEX_DATA file_index_data = _file_index_info.Index[i];
            if (msecOffset >= file_index_data.TimeOffset - _firstDataBlockTimeStamp)
                index = i;
            else {
                //数据块已经超出了给定的seek date
                break;
            }
        }
        
        //快速跳转到该块数据所在文件位置偏移
        if (index >= 0) {
            size_t seekOffset = _file_index_info.Index[index].FileOffset;
            fseek(_stream, seekOffset, SEEK_SET);
            
            //逐帧seek
            RECORD_FILE_DATA_INFO dataInfo;
            size_t count = 0;
            size_t headLength = sizeof(RECORD_FILE_DATA_INFO);
            while (count = fread(&dataInfo, headLength, 1, _stream),count > 0) {
                //计算该帧是否过期
                unsigned int time = dataInfo.TimeStamp - _firstDataBlockTimeStamp;//该帧相对文件起始时间偏移
                if (time < msecOffset)
                    fseek(_stream, dataInfo.Len, SEEK_CUR);//该帧过期就跳过.
                else {
                    seekOffset = ftell(_stream) - headLength;
                    break;
                }
            }
            fseek(_stream, seekOffset, SEEK_SET);
        }
    }
}

- (size_t)read :(void *)buffer
          size :(size_t)size
          type :(int *)type
     timestamp :(double *)timestamp
{
    if (_stream && !feof(_stream)) {
        size_t head_length = sizeof(RECORD_FILE_DATA_INFO);
        RECORD_FILE_DATA_INFO data_info;
        
        if (!fread(&data_info, head_length, 1, _stream))
            return 0;

        if (size >= data_info.Len) {
            if (!fread((char *)buffer, data_info.Len, 1, _stream))
                return 0;
            
            double sec = (data_info.TimeStamp - _firstDataBlockTimeStamp) / 1000.0;
            //NSLog(@"%f",(data_info.TimeStamp - _firstDataBlockTimeStamp) / 1000.0);
            *type = data_info.Type;
            *timestamp = [[NSDate dateWithOleTimeStamp:_file_head_info.StartTime] timeIntervalSince1970] + sec;
            
            return data_info.Len;
        }
    }
    
    return 0;
}

- (size_t)read :(void *)buffer size :(size_t)size
{
    if (_stream && !feof(_stream)) {
        size_t head_length = sizeof(RECORD_FILE_DATA_INFO);
        if (size >= head_length) {
            if (!fread(buffer, head_length, 1, _stream))
                return 0;
            RECORD_FILE_DATA_INFO *data_info = (RECORD_FILE_DATA_INFO *)buffer;
            size_t data_length = data_info->Len;
            
            if (size >= head_length + data_length) {
                if (!fread((char *)buffer + head_length, data_length, 1, _stream))
                    return 0;
                
                return head_length + data_length;
            }
        }
    }
    
    return 0;
}

@end
