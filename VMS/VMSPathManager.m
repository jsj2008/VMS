//
//  VMSPathManager.m
//  VMS
//
//  Created by mac_dev on 15/12/16.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VMSPathManager.h"

#define VMS_ROOT_DIR        @"/VMS"
#define VMS_CONF_FILE       @"vms.ini"
#define VMS_DATABASE        @"vms.db"
#define VMS_WEB_SNAPSHOT    @"vmsSnapshot"
#define VMS_CLIENT_LOGS     @"vms_client_logs"
#define VMS_WEB_LOGS        @"vms_web_logs"


@implementation VMSPathManager
+ (BOOL)isDirValid :(NSString *)dir
{
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isExists = [manager fileExistsAtPath:dir];
    BOOL isReadable = [manager isReadableFileAtPath:dir];
    BOOL isWriteable = [manager isWritableFileAtPath:dir];
    BOOL isExcuteable = [manager isExecutableFileAtPath:dir];
    
    return isExists && isReadable && isWriteable && isExcuteable;
}

+ (NSString *)doscDir
{
    //获取文档路径
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    return docsDir;
}

+ (NSString *)applicationSupportDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                NSUserDomainMask,
                                                YES) lastObject];
}

+ (NSString *)vmsRootDir:(BOOL)isCreate
{
    if (isCreate && ![VMSPathManager isDirValid:VMS_ROOT_DIR]) {
        //如果文件不存在，或者使用权限不对,需要以管理员权限运行安装脚本
        NSString *path = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:@"VMSCreateDir" ofType:@"sh"]];
        NSString *output;
        NSString *error;
        [self runProcessAsAdministrator:path
                          withArguments:@[VMS_ROOT_DIR]
                                 output:&output
                       errorDescription:&error];
        
        return error? nil : VMS_ROOT_DIR;
    }
    
    return VMS_ROOT_DIR;
}

+ (BOOL) runProcessAsAdministrator:(NSString*)scriptPath
                     withArguments:(NSArray *)arguments
                            output:(NSString **)output
                  errorDescription:(NSString **)errorDescription {
    NSString *source = [NSString stringWithFormat:@"%@",scriptPath];
    NSInteger argumentsCount = arguments.count;
    for (NSInteger idx = 0; idx < argumentsCount; idx++) {
        source = [source stringByAppendingString:@","];
        source = [source stringByAppendingString:arguments[idx]];
    }
    
    NSString        *allArgs = [arguments componentsJoinedByString:@" "];
    NSString        *fullScript = [NSString stringWithFormat:@"%@ %@", scriptPath, allArgs];
    NSDictionary    *errorInfo = [NSDictionary new];
    NSString        *script =  [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", fullScript];
    NSAppleScript   *appleScript = [[NSAppleScript new] initWithSource:script];
    NSAppleEventDescriptor *eventResult = [appleScript executeAndReturnError:&errorInfo];
    
    // Check errorInfo
    if (! eventResult)
    {
        // Describe common errors
        *errorDescription = nil;
        if ([errorInfo valueForKey:NSAppleScriptErrorNumber])
        {
            NSNumber * errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
            if ([errorNumber intValue] == -128)
                *errorDescription = @"The administrator password is required to do this.";
        }
        
        // Set error message from provided message
        if (*errorDescription == nil)
        {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage])
                *errorDescription =  (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
        }
        
        return NO;
    }
    else
    {
        // Set output to the AppleScript's output
        *output = [eventResult stringValue];
        
        return YES;
    }
}

+ (NSString *)vmsWebSnapshotDir:(BOOL)isCreate
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *vmsWebSnapshotDir = [VMS_ROOT_DIR stringByAppendingPathComponent:@"Snapshot"];
    BOOL isExists = [manager fileExistsAtPath:vmsWebSnapshotDir];
    BOOL isReadable = [manager isReadableFileAtPath:vmsWebSnapshotDir];
    BOOL isWriteable = [manager isWritableFileAtPath:vmsWebSnapshotDir];
    BOOL isExcuteable = [manager isExecutableFileAtPath:vmsWebSnapshotDir];
    if (isCreate && !(isExists && isReadable && isWriteable && isExcuteable)) {
        //如果文件不存在，或者使用权限不对,需要以管理员权限运行安装脚本
        NSString *path = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:@"VMSCreateDir" ofType:@"sh"]];
        NSString *output;
        NSString *error;
        [self runProcessAsAdministrator:path
                          withArguments:@[vmsWebSnapshotDir]
                                 output:&output
                       errorDescription:&error];
        
        return error? nil : vmsWebSnapshotDir;
    }
    
    return vmsWebSnapshotDir;
}

+ (NSString *)vmsDatabasePath:(BOOL)isCreate
{
    //NSString *vmsSupportDir = [VMSPathManager vmsRootDir:isCreate];
    NSString *vmsSupportDir = [self applicationSupportDirectory];
    
    if (vmsSupportDir)
        return [vmsSupportDir stringByAppendingPathComponent:VMS_DATABASE];
    else {
        NSLog(@"创建VMS 支持文件夹 失败，退出应用程序");
        exit(0);
    }
}

+ (NSString *)vmsConfPath:(BOOL)isCreate
{
    //NSString *vmsSupportDir = [VMSPathManager vmsRootDir:isCreate];
    NSString *vmsSupportDir = [self applicationSupportDirectory];
    
    if (vmsSupportDir)
        return [vmsSupportDir stringByAppendingPathComponent:VMS_CONF_FILE];
    else {
        NSLog(@"创建VMS 支持文件夹 失败，退出应用程序");
        exit(0);
    }
}


+ (NSString *)applicatoinLibraryDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                NSUserDomainMask,
                                                YES) lastObject];
}

+ (NSString *)applicationLogsDirectory
{
    return [[self applicatoinLibraryDirectory] stringByAppendingPathComponent:@"Logs"];
}

+ (NSString *)vmsLogsDir
{
    NSArray *results =
    NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *appLibraryDir = [results lastObject];
    NSString *appLogsDir = [appLibraryDir stringByAppendingPathComponent:@"Logs"];
    return [appLogsDir stringByAppendingPathComponent:@"VMS"];
}

+ (NSString *)vmsClientLogsDir
{
    NSError *error;
    NSString *vmsClientLogsDir =
    [[VMSPathManager vmsLogsDir] stringByAppendingPathComponent:VMS_CLIENT_LOGS];
    
//    NSString *vmsClientLogsDir =
//    [[self vmsLogsDir] stringByAppendingPathComponent:VMS_CLIENT_LOGS];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:vmsClientLogsDir withIntermediateDirectories:YES attributes:nil error:&error];
    return error? nil : vmsClientLogsDir;
}

+ (NSString *)vmsWebLogsDir
{
    NSError *error;
    NSString *vmsWebLogsDir =
    [[VMSPathManager vmsLogsDir] stringByAppendingPathComponent:VMS_WEB_LOGS];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:vmsWebLogsDir withIntermediateDirectories:YES attributes:nil error:&error];
    return error? nil : vmsWebLogsDir;
}

@end
