//
//  VMSPathManager.h
//  VMS
//
//  Created by mac_dev on 15/12/16.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface VMSPathManager : NSObject

+ (NSString *)doscDir;
+ (NSString *)vmsDatabasePath:(BOOL)isCreate;
+ (NSString *)vmsConfPath:(BOOL)isCreate;
+ (NSString *)vmsWebSnapshotDir:(BOOL)isCreate;
+ (NSString *)vmsClientLogsDir;
+ (NSString *)vmsWebLogsDir;

@end
