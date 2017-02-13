//
//  NSDate+HalfHour.m
//  VMS
//
//  Created by mac_dev on 15/8/25.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NSDate+HalfHour.h"

@implementation NSDate (HalfHour)
- (int)floorHalfHour
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components =
    [calendar components:NSCalendarUnitHour |NSCalendarUnitMinute |NSCalendarUnitSecond  fromDate:self];
    
    return floor(2.0 *components.hour + components.minute / 30.0 + components.second / 1800.0);
}

- (int)ceilHalfHour
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components =
    [calendar components:NSCalendarUnitHour |NSCalendarUnitMinute |NSCalendarUnitSecond  fromDate:self];
    
    return ceil(2.0 *components.hour + components.minute / 30.0 + components.second / 1800.0);
}

+ (NSDate *)dateFromHalfHour :(int)halfHour
{
    NSDate *result = nil;
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components =
    [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:now];
    
    if (halfHour < 48) {
        int minutesTotal = halfHour * 30;
        components.hour = minutesTotal / 60;
        components.minute = minutesTotal % 60;
        components.second = 0;
    } else if (halfHour == 48){
        components.hour = 23;
        components.minute = 59;
        components.second = 59;
    }
    
    result = [calendar dateFromComponents:components];
    return result;
}


@end
