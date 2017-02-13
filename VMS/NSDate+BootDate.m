//
//  NSDate+BootDate.m
//  VMSFileParse
//
//  Created by mac_dev on 15/11/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NSDate+BootDate.h"
#import <sys/sysctl.h>

#define MIB_SIZE 2 

@implementation NSDate (BootDate)

+ (NSDate *)bootDate
{
    int mib[MIB_SIZE];
    size_t size;
    struct timeval  boottime;
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_BOOTTIME;
    size = sizeof(boottime);
    if (sysctl(mib, MIB_SIZE, &boottime, &size, NULL, 0) != -1)
    {
        // successful call
        return [NSDate dateWithTimeIntervalSince1970:
                boottime.tv_sec + boottime.tv_usec / 1.e6];
    }
    
    return nil;
}

@end
