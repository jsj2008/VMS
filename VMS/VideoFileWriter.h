//
//  VideoFileManager.h
//  VMS
//
//  Created by mac_dev on 15/8/4.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../FoscamNetSDK/RecordDef.h"
#import "Channel.h"
#import "CDevice.h"
#import "NSDate+OleDate.h"
#import "NSDate + SRAdditions.h"
#import "NSDate+BootDate.h"
#import "VideoBuffer.h"

#define NOTIFICATION_VIDEO_DATA_WILL_WRITE_TO_DISK  @"video data will write to disk notification"
#define KEY_VIDEO_DATA_LEN                          @"video data length"

typedef struct TAG_VIDEO_FILE_CONSTRAINT {
    int type;
    int length_max;
    double time_interval_max;
}VIDEO_FILE_CONSTRAINT;


typedef NS_ENUM(NSUInteger, VFW_RESULT) {
    VFW_SUCCESS,
    VFW_BAD_DATA,
    VFW_NO_FILE,
    VFW_NEW_FILE,
    VFW_NULL_CHANNEL,
    VFW_INVALID_PATH,
    VFW_EMPTY_PATH,
    VFW_OPEN_FILE_FAILED,
    VFW_INVALID_END_DATE,
    VFW_FILE_ALREADY_OPENED,
    VFW_FILE_NOT_OPEN,
    VFW_DISK_SPACE_NOT_ENOUGH,
};

@protocol VideoFileWriterDelegate <NSObject>

- (void)willWriteToDisk :(NSNotification *)aNotific
                   stop :(BOOL *)stop;
@end


@interface VideoFileWriter : NSObject

@property (assign,readonly) VIDEO_FILE_CONSTRAINT constraint;//视频数据目的地
//@property (copy) NSString *path;
@property (assign,readonly) int type;
@property (assign,nonatomic) id<VideoFileWriterDelegate> delegate;

- (id)initWithFileConstraint :(VIDEO_FILE_CONSTRAINT)constraint
                        type :(int)type
                        path :(NSString *)path;
- (instancetype)initWithType :(int)type;
- (instancetype)initWithFileConstraint:(VIDEO_FILE_CONSTRAINT)constraint
                                  type:(int)type;
- (void)dealloc;
- (VFW_RESULT)createFileForChannel :(Channel *)chn
                        path :(NSString *)path;
- (VFW_RESULT)close;
- (VFW_RESULT)writeFileWithBuffer :(const void *)bytes
                           length :(size_t)len
                           bengin :(NSDate *)begin
                              end :(NSDate *)end;
- (NSString *)errMsg :(VFW_RESULT)result;
@end
