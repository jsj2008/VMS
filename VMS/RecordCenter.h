//
//  ScheduledRecording.h
//  VMS
//
//  Created by mac_dev on 15/7/27.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScheduledRecordTask.h"
#import "../FoscamNetSDK/IPCSDK_for_mac150629/include/FosDef.h"
#import "DispatchCenter.h"
#import "VideoFileWriter.h"
#import "VMSDatabase.h"
#import "NSDate + SRAdditions.h"
#import "Channel.h"
#import "VideoPlayer.h"
#import "SystemSettingSheetController.h"
#import "VMSRecordSetting.h"
#import "VMSPathManager.h"
#import "NSString+VMSVideoFileName.h"
#import "VideoRecorder.h"

//录像文件打包类型
typedef NS_ENUM(NSUInteger, RECORD_PACHAGE_TYPE) {
    RP_SIZE,
    RP_TIME,
    RP_ALL,
};

#define RECORD_STREAM_TYPE      FOSSTREAM_MAIN
#define RECORD_STATE_DID_CHANGE_NOTIFICATION    @"record state did change notification"
#define KEY_RECORD_CHID     @"record_ch_id"
#define RECORD_OFF          0
#define RECORD_ON           1
#define RECORD_CONNECTING   2

@interface RFile : NSObject

@property(nonatomic,strong) NSURL *url;
@property(nonatomic,strong) NSDate *begin;
@property(nonatomic,strong) NSDate *end;

- (void)cache;

@end

@interface RecordCenter : NSObject<DispatchProtocal,NSUserNotificationCenterDelegate>

@property (nonatomic,strong) VMSRecordSetting *recording_setting;

+ (RecordCenter *)sharedRecordCenter;
- (void)dealloc;
- (void)scanTasks;//扫描任务
- (void)loopRecord;//循环录像
- (int)queryStateWithChannelId :(int)cId recordType :(RecordType)type;
- (void)switchRecordingState :(BOOL)state withChannelId :(int)channelId type :(RecordType)type;

@end
