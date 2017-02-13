//
//  NSDate + SRAdditions.h
//  VMS
//
//  Created by mac_dev on 15/6/4.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SEC_PER_DAY 86400.0    
@interface NSDate (SRAdditions)
- (NSDate *)dateByMovingToBeginningOfDay;
- (NSDate *)dateByMovingToEndOfDay;
+ (NSDate *)convertDateToLocalTime: (NSDate *)forDate;
+ (NSDate *)dateFromString :(NSString *)date withFormatter :(NSString *)formatter;

- (NSDate *)time;
- (NSString *)stringWithFormatter :(NSString *)formatterString;
- (NSInteger)weekDay;
- (BOOL)isOnSameDayWithDate :(NSDate *)aDate;
@end
