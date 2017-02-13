//
//  VMSBasicSetting.m
//  VMS
//
//  Created by mac_dev on 15/12/3.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VMSBasicSetting.h"
#import <sys/types.h>
#import <pwd.h>


@interface VMSBasicSetting()
@property (readwrite) NSString *path;
@end

@implementation VMSBasicSetting

static const char *codingKeyBasicSetting = "NORMAL_SET";
static const char *codingKeyVersion = "VERSION";
static const char *codingKeyCapturePathName = "CAPTURE_PATHNAME";
static const char *codingKeyNetType = "NET_TYPE";
static const char *codingKeyWndStreamType = "WND_STREAM_TYPE";
static const char *codingKeyPollTime = "POLL_TIME";
static const char *codingKeyLatestUserId = "LATEST_USER_ID";
static const char *codingKeyOptions = "OPTIONS";
static const char *codingKeyServerPort = "SERVERPORT";

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        [self setPath:path];
        [self unArchive];//解档
    }
    
    return self;
}


- (void)archive
{
    const char *file = self.path.UTF8String;
    
    NSString *version = self.version;
    write_profile_string(codingKeyBasicSetting,
                         codingKeyVersion,
                         version.UTF8String,
                         file);
    
    
    write_profile_string(codingKeyBasicSetting,
                         codingKeyCapturePathName,
                         self.capturePathName.UTF8String,
                         file);
    
    NSString *netTypeStr = [NSString stringWithFormat:@"%d",self.netType];
    write_profile_string(codingKeyBasicSetting,
                         codingKeyNetType,
                         netTypeStr.UTF8String,
                         file);
    NSString *wndStreamTypeStr = [NSString stringWithFormat:@"%d",self.wndStreamType];
    write_profile_string(codingKeyBasicSetting,
                         codingKeyWndStreamType,
                         wndStreamTypeStr.UTF8String,
                         file);
    NSString *pollTimeStr = [NSString stringWithFormat:@"%d",self.pollTime];
    write_profile_string(codingKeyBasicSetting,
                         codingKeyPollTime,
                         pollTimeStr.UTF8String,
                         file);
    NSString *latestUserIdStr = [NSString stringWithFormat:@"%d",self.latestUserId];
    write_profile_string(codingKeyBasicSetting,
                         codingKeyLatestUserId,
                         latestUserIdStr.UTF8String,
                         file);
    NSString *optionsStr = [NSString stringWithFormat:@"%lu",(unsigned long)self.options];
    write_profile_string(codingKeyBasicSetting,
                         codingKeyOptions,
                         optionsStr.UTF8String,
                         file);
    
    NSString *serverPortStr = [NSString stringWithFormat:@"%d",self.serverPort];
    write_profile_string(codingKeyBasicSetting,
                         codingKeyServerPort,
                         serverPortStr.UTF8String,
                         file);
}


- (VMS_OPTION)defaultOption
{
    VMS_OPTION defOp = 0;
    
    defOp |= VMS_SAVE_LAYOUT;
    
    return defOp;
}

- (void)unArchive
{
    const char *file = self.path.UTF8String;
    char capturePath[256];
    const char *defaultCapturePath = [self defaultCapturePathName].UTF8String;
    read_profile_string(codingKeyBasicSetting,
                        codingKeyCapturePathName,
                        defaultCapturePath,
                        capturePath,
                        256,
                        file);
    
    self.capturePathName = [NSString stringWithUTF8String:capturePath];
    self.netType = read_profile_int(codingKeyBasicSetting,
                                    codingKeyNetType,
                                    0,
                                    file);
    self.wndStreamType = read_profile_int(codingKeyBasicSetting,
                                          codingKeyWndStreamType,
                                          0,
                                          file);
    self.pollTime = read_profile_int(codingKeyBasicSetting,
                                     codingKeyPollTime,
                                     5,
                                     file);
    self.latestUserId = read_profile_int(codingKeyBasicSetting,
                                         codingKeyLatestUserId,
                                         0,
                                         file);
    self.options = read_profile_int(codingKeyBasicSetting,
                                    codingKeyOptions,
                                    [self defaultOption],
                                    file);
    self.serverPort = read_profile_int(codingKeyBasicSetting,
                                       codingKeyServerPort,
                                       3000,
                                       file);
    
    char version[32];
    read_profile_string(codingKeyBasicSetting,
                        codingKeyVersion,
                        "V0.0.0",
                        version,
                        32,
                        file);
    self.version = [NSString stringWithUTF8String:version];
}


- (NSString *)defaultCapturePathName
{
    struct passwd *pw = getpwuid(getuid());
    NSString *home = [NSString stringWithUTF8String:pw->pw_dir];

    return [home stringByAppendingPathComponent:@"Pictures"];
}

//- (NSString *)defaultCapturePathName
//{
//    NSString *docsDir;
//    NSArray *dirPaths;
//    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    docsDir = [dirPaths objectAtIndex:0];
//    
//    return docsDir;
//}


@end
