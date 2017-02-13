//
//  NSDate+OleDate.m
//  VMS
//
//  Created by mac_dev on 15/8/20.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NSDate+OleDate.h"

@implementation NSDate (OleDate)

+ (NSDate *)date1899
{
    NSDateFormatter *date_formatter = [[NSDateFormatter alloc] init];
    [date_formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [date_formatter setLocale:[NSLocale currentLocale]];
    [date_formatter setDateFormat:@"yyyy-MM-dd_hh-mm-ss"];
    [date_formatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
    
    NSDate *date_1899 = [date_formatter dateFromString:@"1899-12-30_00-00-00"];
    
    return date_1899;
}

+ (NSDate *)dateWithOleTimeStamp :(double)oleTimeStamp
{
    NSTimeInterval timeInterval = oleTimeStamp * SEC_PER_DAY;
    
    return [NSDate dateWithTimeInterval :timeInterval sinceDate:[NSDate date1899]];
}

- (double)oleTimeStamp
{
    //获取相对于1989年的时间戳
    NSTimeInterval time_interval = [self timeIntervalSinceDate:[NSDate date1899]];
    return time_interval / SEC_PER_DAY;
}

@end
