//
//  NSString+VMSVideoFileName.m
//  VMS
//
//  Created by mac_dev on 16/1/11.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#import "NSString+VMSVideoFileName.h"

@implementation NSString (VMSVideoFileName)

/*- (void)getVideoType :(NSInteger *)type
           beginDate :(NSDate **)beginDate
             endDate :(NSDate **)endDate
{
    NSDate *t1 = [NSDate date];
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSString *beginDateStr,*endDateStr;
    NSString *dateFormatter = @"yyyy-MM-dd_HH-mm-ss";
    
    [scanner scanInteger:type];
    [scanner scanString:@"__" intoString:NULL];
    [scanner scanUpToString:@"___" intoString:&beginDateStr];
    [scanner scanString:@"___" intoString:NULL];
    [scanner scanUpToString:@".vms" intoString:&endDateStr];
    [scanner scanString:@".vms" intoString:NULL];
    
    
    *beginDate = [NSDate dateFromString:beginDateStr withFormatter:dateFormatter];
    *endDate = [NSDate dateFromString:endDateStr withFormatter:dateFormatter];
    NSDate *t2 = [NSDate date];
    
    NSLog(@"cost = %f",[t2 timeIntervalSinceDate:t1]);
}*/

#define NAME_LEN    64
#define DATE_LEN    32

- (void)getVideoType :(NSInteger *)type
           beginDate :(NSDate **)beginDate
             endDate :(NSDate **)endDate
{
    NSString *dateFormatter = @"yyyy-MM-dd_HH-mm-ss";

    int recordType = 0;
    char name[NAME_LEN] = {0};
    char start[DATE_LEN] = {0};
    char end[DATE_LEN] = {0};
    
    if ([self getCString:name maxLength:NAME_LEN encoding:NSASCIIStringEncoding]) {
        if (sscanf(name,  "%d__%19s___%19s", &recordType, start, end) == 3) {
            *beginDate = [NSDate dateFromString:[NSString stringWithCString:start
                                                                   encoding:NSUTF8StringEncoding]
                                  withFormatter:dateFormatter];
            *endDate = [NSDate dateFromString:[NSString stringWithCString:end
                                                                 encoding:NSUTF8StringEncoding]
                                withFormatter:dateFormatter];
        }
    }
}
@end
