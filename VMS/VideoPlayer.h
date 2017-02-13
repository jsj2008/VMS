//
//  VideoPlayer.h
//  VMS
//
//  Created by mac_dev on 15/8/19.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoFileReader.h"
#import "Channel.h"
#import "NSDate + SRAdditions.h"
#import <pthread.h>

#define KEY_CHANNEL_ID                      @"channelId"

#define KEY_MULTY_VIDEO_FILE_INFO           @"multy_video_file_info"
    #define KEY_VIDEO_FILE_PATH             @"file_path"
    #define KEY_DATE_BEGIN                  @"date_begin"
    #define KEY_DATE_END                    @"date_end"
    #define KEY_RECORD_TYPE                 @"record_type"
#define KEY_CUR_TIME_STAMP                  @"cur_time_stamp"

#define VIDEO_PLAYER_WILL_PLAY_NOTIFICATION         @"video player will play notification"
#define VIDEO_PLAYER_WILL_PAUSE_NOTIFICATION        @"video player will pause notification"
#define VIDEO_PLAYER_DID_RUSUME_NOTIFICATION        @"video player did resume notification"
#define VIDEO_PLAYER_DID_STOP_NOTIFICATION          @"video player did stop notification"
#define VIDEO_PLAYER_SPEED_DID_CHANGE_NOTIFICATION  @"video player speed did change notification"

typedef NS_ENUM(NSUInteger, VP_RESULT) {
    VP_DONE,
    VP_INTERRUPT_SEEK,
    VP_INTERRUPT_STOP,
};


@class VideoPlayer;

@protocol VideoPlayerProtocol <NSObject>
@optional
//视频播放器读到一帧数据
- (void)videoPlayer :(VideoPlayer *)player
        didReadData :(void *)bytes
             length :(size_t)length
               type :(int)type
          timeStamp :(double)timeStamp
          channelId :(int)channelId;
@end


@interface VideoPlayer : NSObject
//由主线程控制写
//多线程控制读
//异步停止
//异步暂停

@property (nonatomic,strong) NSDate *seekDate;
@property (atomic,strong) NSDate *progressDate;//播放器进度时间
@property (nonatomic,strong,readonly) NSMutableArray *playSources;
@property (nonatomic,assign,readonly) double speed;//播放速度,用于控制快放，慢放
//播放队列计数
- (id)init;
- (void)dealloc;
- (BOOL)play;
- (void)stop;
- (void)pause;
- (void)resume;
- (void)nextFrame;
- (void)slow;
- (void)fast;
- (BOOL)isPlaying;
- (BOOL)isPausing;
- (BOOL)existPausingChannel;
- (void)addChannelWithId :(int)channelId multyVideoFileInfo :(NSArray *)multyVideoInfo;
- (void)addObserver :(id<VideoPlayerProtocol>)observer;
- (void)removeObserver :(id<VideoPlayerProtocol>)observer;

@end

@interface PlayerLaunchArgcs : NSObject
@property(nonatomic,weak) VideoPlayer *player;
@property(nonatomic,assign) pthread_t hThread;
@property(nonatomic,assign) int channelId;
@property(nonatomic,strong) NSArray *videoInfos;

@end
