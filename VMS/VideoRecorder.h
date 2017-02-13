//
//  VideoRecorder.h
//  
//
//  Created by mac_dev on 16/3/11.
//
//

#import <Foundation/Foundation.h>
#import "../FoscamNetSDK/RecordDef.h"
#import "../FoscamNetSDK/IPC/FoscamNetSDK.h"
#import "../FoscamNetSDK/IPCSDK_for_mac150629/include/FosDef.h"
#import "VideoFileWriter.h"
#import "VMSRecordSetting.h"
#import "VMSPathManager.h"
#import "DiskManager.h"

typedef NS_OPTIONS(NSUInteger, RecordType) {
    ScheduledRecord = 1 << 0,
    ManualRecord = 1 << 1,
    AlarmRecord = 1 << 2,
    AllRecord = ScheduledRecord | ManualRecord | AlarmRecord,
};


@interface VideoRecorder : NSObject<VideoFileWriterDelegate,NSUserNotificationCenterDelegate>

@property (nonatomic,strong,readonly) Channel *chn;
@property (nonatomic,strong) VMSRecordSetting *rs;

- (instancetype)initWithChannel:(Channel *)chn;
- (void)dealloc;
- (void)start :(RecordType)type;
- (void)stop :(RecordType)type;
- (void)inputData :(void *)bytes length :(int)len type :(int)type;
- (BOOL)isRecording :(RecordType)type;

@end
