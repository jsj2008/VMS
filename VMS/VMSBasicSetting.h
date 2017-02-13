//
//  VMSBasicSetting.h
//  VMS
//
//  Created by mac_dev on 15/12/3.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SNAPSHOT_FOLDER @"vms_snapshot"
typedef NS_OPTIONS(NSUInteger, VMS_OPTION) {
    VMS_SAVE_LAYOUT = 1 << 0,
    VMS_AUTO_RUN = 1 << 1,
    VMS_AUTO_LOGIN = 1 << 2,
    VMS_AUTO_SEARCH = 1 << 3,
    VMS_SAVE_PSW = 1 << 4,
    VMS_AUTO_FULLSCREEN = 1 << 5,
};

//该类为系统基本设置类，仅支持解挡、归档操作即可
@interface VMSBasicSetting : NSObject

@property (nonatomic,copy) NSString *version;
@property (nonatomic,copy,readonly) NSString *path;
@property (nonatomic,copy) NSString *capturePathName;
@property (nonatomic,assign) int netType;
@property (nonatomic,assign) int wndStreamType;
@property (nonatomic,assign) int pollTime;
@property (nonatomic,assign) int latestUserId;
@property (nonatomic,assign) VMS_OPTION options;
@property (nonatomic,assign) int serverPort;



- (instancetype)initWithPath :(NSString *)path;
- (void)archive;
- (void)unArchive;
@end

