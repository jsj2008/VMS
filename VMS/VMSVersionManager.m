//
//  VMSVersionControll.m
//  VMS
//
//  Created by mac_dev on 15/12/31.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VMSVersionManager.h"



@implementation VMSVersionManager

+ (NSString *)latestVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSComparisonResult)compareVersion :(NSString *)VA
                         withVersion :(NSString *)VB
{
    int var[6] = {0};
    [VMSVersionManager getVersion:VA
                             major:var
                             minor:var+1
                          revision:var+2];
    
    [VMSVersionManager getVersion:VB
                             major:var+3
                             minor:var+4
                          revision:var+5];
    
    if (var[0] != var[3])
        return var[0] > var[3]? NSOrderedDescending : NSOrderedAscending;
    else if (var[1] != var[4])
        return var[1] > var[4]? NSOrderedDescending : NSOrderedAscending;
    else if (var[2] != var[5])
        return var[2] > var[5]? NSOrderedDescending : NSOrderedAscending;
    
    return NSOrderedSame;
}

+ (BOOL)getVersion:(NSString *)version
             major:(int *)major
             minor:(int *)minor
          revision:(int *)revision
{
    NSScanner *scanner = [NSScanner scannerWithString:version];
    
    if ([scanner scanString:@"V" intoString:NULL] &&
        [scanner scanInt:major] &&
        [scanner scanString:@"." intoString:NULL] &&
        [scanner scanInt:minor] &&
        [scanner scanString:@"." intoString:NULL] &&
        [scanner scanInt:revision]) {
        return YES;
    }
    
    return NO;
}


@end
