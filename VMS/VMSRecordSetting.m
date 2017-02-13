//
//  VMSRecordSetting.m
//  VMS
//
//  Created by mac_dev on 15/12/3.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VMSRecordSetting.h"
#import <sys/types.h>
#import <pwd.h>


@interface VMSRecordSetting()
@property (readwrite) NSString *path;
@end


@implementation VMSRecordSetting


static const char *codingKeyDiskCount = "COUNT";
static const char *codingKeyRecordSetting = "RECORD_DISK";
static const char *codingKeyEnableRecording = "EnableRecording";
static const char *codingKeyRecordingPathName = "DISK_PATH_0";
static const char *codingKeyRecordingRestrict = "TYPE";
static const char *codingKeyRecordingSize = "SIZE";
static const char *codingKeyRecordingTime = "TIME";
static const char *codingKeyAlarmRecordTimerInterval = "ALARM_RECORD_TIMER_INTERVAL";
static const char *codingKeyEnableLoopRecord = "ENABLE LOOP RECORD";
static const char *codingKeyLoopRecordDelSize = "LOOP RECORD DEL SIZE";

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        [self setPath:path];
        [self unAchive];
    }
    
    return self;
}

- (void)archive
{
    const char *file = self.path.UTF8String;
    NSString *enableStr = [NSString stringWithFormat:@"%d",self.enable];
    write_profile_string(codingKeyRecordSetting,
                         codingKeyEnableRecording,
                         enableStr.UTF8String,
                         file);
    write_profile_string(codingKeyRecordSetting,
                         codingKeyRecordingPathName,
                         self.recordingPathName.UTF8String,
                         file);
    NSString *recordingRestrictStr = [NSString stringWithFormat:@"%d",self.recordingRestrict];
    write_profile_string(codingKeyRecordSetting,
                         codingKeyRecordingRestrict,
                         recordingRestrictStr.UTF8String,
                         file);
    NSString *recordingSizeStr = [NSString stringWithFormat:@"%d",self.recordingSize];
    write_profile_string(codingKeyRecordSetting,
                         codingKeyRecordingSize,
                         recordingSizeStr.UTF8String,
                         file);
    NSString *recordingTimeStr = [NSString stringWithFormat:@"%d",self.recordingTime];
    write_profile_string(codingKeyRecordSetting,
                         codingKeyRecordingTime,
                         recordingTimeStr.UTF8String,
                         file);
    
    NSString *diskCountStr = [NSString stringWithFormat:@"%d",self.diskCount];
    write_profile_string(codingKeyRecordSetting,
                         codingKeyDiskCount,
                         diskCountStr.UTF8String,
                         file);
    
    NSString *alarmRecordTimerInterval = [NSString stringWithFormat:@"%d",self.alarmRecordTimerInterval];
    write_profile_string(codingKeyRecordSetting,
                         codingKeyAlarmRecordTimerInterval,
                         alarmRecordTimerInterval.UTF8String,
                         file);
    
    NSString *enableLoopRecord = [NSString stringWithFormat:@"%d",self.enableLoopRecord];
    write_profile_string(codingKeyRecordSetting,
                         codingKeyEnableLoopRecord,
                         enableLoopRecord.UTF8String,
                         file);
    
    NSString *loopRecordDelSize = [NSString stringWithFormat:@"%d",self.loopRecordDeleteFileSize];
    write_profile_string(codingKeyRecordSetting,
                         codingKeyLoopRecordDelSize,
                         loopRecordDelSize.UTF8String,
                         file);
}

- (void)unAchive
{
    const char *file = self.path.UTF8String;
    char videoPath[256];
    const char *defaultVideoPath = [self defaultVideoPathName].UTF8String;
    
    read_profile_string(codingKeyRecordSetting,
                        codingKeyRecordingPathName,
                        defaultVideoPath,
                        videoPath,
                        256,
                        file);
    self.recordingPathName = [NSString stringWithUTF8String:videoPath];
    self.enable = read_profile_int(codingKeyRecordSetting,
                                   codingKeyEnableRecording,
                                   1,
                                   file);
    self.recordingRestrict = read_profile_int(codingKeyRecordSetting,
                                              codingKeyRecordingRestrict,
                                              0,
                                              file);
    self.recordingSize = read_profile_int(codingKeyRecordSetting,
                                          codingKeyRecordingSize,
                                          64,
                                          file);
    self.recordingTime = read_profile_int(codingKeyRecordSetting,
                                          codingKeyRecordingTime,
                                          5,
                                          file);
    self.diskCount = read_profile_int(codingKeyRecordSetting,
                                      codingKeyDiskCount,
                                      1,
                                      file);
    
    self.alarmRecordTimerInterval = read_profile_int(codingKeyRecordSetting,
                                                     codingKeyAlarmRecordTimerInterval,
                                                     120,
                                                     file);
    
    self.enableLoopRecord = read_profile_int(codingKeyRecordSetting,
                                             codingKeyEnableLoopRecord,
                                             0,
                                             file);
    self.loopRecordDeleteFileSize = read_profile_int(codingKeyRecordSetting,
                                                     codingKeyLoopRecordDelSize,
                                                     500,
                                                     file);
}


- (NSString *)defaultVideoPathName
{
    struct passwd *pw = getpwuid(getuid());
    NSString *home = [NSString stringWithUTF8String:pw->pw_dir];
    
    return [home stringByAppendingPathComponent:@"Movies"];
}
//- (NSString *)defaultVideoPathName
//{
//    NSString *docsDir;
//    NSArray *dirPaths;
//    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    docsDir = [dirPaths objectAtIndex:0];
//    
//    return docsDir;
//}
@end
