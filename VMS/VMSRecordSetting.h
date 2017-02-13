//
//  VMSRecordSetting.h
//  VMS
//
//  Created by mac_dev on 15/12/3.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "inifile.h"

#define RECORD_FILE_FOLDER                      @"com.foscam.vms.record"
#define RECORDING_SETTING_DID_CHANGE_NOTIFIC    @"record setting did change notification"

@interface VMSRecordSetting : NSObject

@property (nonatomic,assign) int diskCount;
@property (nonatomic,copy,readonly) NSString *path;
@property (nonatomic,assign) int enable;
@property (nonatomic,copy) NSString *recordingPathName;
@property (nonatomic,assign) int recordingRestrict;
@property (nonatomic,assign) int recordingSize;
@property (nonatomic,assign) int recordingTime;
@property (nonatomic,assign) int alarmRecordTimerInterval;
@property (nonatomic,assign) BOOL enableLoopRecord;
@property (nonatomic,assign) int loopRecordDeleteFileSize;//循环录像，删除录像文件大小

- (instancetype)initWithPath :(NSString *)path;
- (void)archive;
- (void)unAchive;
@end
