//
//  DiskManager.m
//  VMS
//
//  Created by mac_dev on 2016/12/26.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "DiskManager.h"

@implementation DiskManager

+ (CGFloat)diskUsage
{
    CGFloat diskUsage = 0.0;
    NSError *err;
    NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/"
                                                                                           error:&err];
    
    if (!err) {
        unsigned long long freeSpace = [[fileAttributes objectForKey:NSFileSystemFreeSize] longLongValue];
        unsigned long long totalSpace = [[fileAttributes objectForKey:NSFileSystemSize] longLongValue];
        diskUsage = (totalSpace - freeSpace) * 100.0/ totalSpace;
    }
    
    return diskUsage;
}

@end
