//
//  NSDate + SRAdditions.m
//  VMS
//
//  Created by mac_dev on 15/6/4.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NSDate + SRAdditions.h"


#define TIME_ZONE [NSTimeZone systemTimeZone]
#define TIME_ZONE_UTC [NSTimeZone timeZoneWithAbbreviation:@"UTC"]


@implementation NSDate (SRAdditions)


- (NSDate *)dateByMovingToBeginningOfDay
{
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents* parts = [calendar components:flags fromDate:self];
    [parts setHour:0];
    [parts setMinute:0];
    [parts setSecond:0];
    
    //转换成为本地时区(北京)
    return [[NSCalendar currentCalendar] dateFromComponents:parts];
}

- (NSDate *)dateByMovingToEndOfDay
{
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents* parts = [[NSCalendar currentCalendar] components:flags fromDate:self];
    [parts setHour:23];
    [parts setMinute:59];
    [parts setSecond:59];
    return [[NSCalendar currentCalendar] dateFromComponents:parts];
}


+(NSDate *)convertDateToLocalTime: (NSDate *)forDate {
    
    NSTimeZone *nowTimeZone = [NSTimeZone localTimeZone];
    long timeOffset = [nowTimeZone secondsFromGMTForDate:forDate];
    NSDate *newDate = [forDate dateByAddingTimeInterval:timeOffset];
    return newDate;
}

+ (NSDate *)dateFromString :(NSString *)date withFormatter :(NSString *)formatterString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat :formatterString];
    return [formatter dateFromString :date];;
}

//This function is used to convert a date like 2015/7/20 15:12:11 to the date that only care about time like
//15:12:11
- (NSDate *)time
{
    NSCalendar *canlendar = [NSCalendar currentCalendar];
    //We only care hour,miniute and seconds
    unsigned unitFlags =  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *components = [canlendar components:unitFlags fromDate:self];
    return [canlendar dateFromComponents :components];
}

- (NSString *)stringWithFormatter :(NSString *)formatterString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat :formatterString];
    return [formatter stringFromDate :self];
}

- (NSInteger)weekDay
{
    NSCalendar *canlendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitWeekday;
    
    return [canlendar components:unitFlags fromDate:self].weekday - 1;
}

- (BOOL)isOnSameDayWithDate :(NSDate *)aDate
{
    return [[aDate dateByMovingToBeginningOfDay] isEqualToDate:[self dateByMovingToBeginningOfDay]];
}
@end
