//
//  AlarmTask.m
//  VMS
//
//  Created by mac_dev on 15/12/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "ScheduledTask.h"

@implementation ScheduledTask

-(instancetype)initWithUniqueId:(int)uniqueId
                        weekday:(int)weekday
                      channelId:(int)chnId
                           data:(long long)data;
{
    if (self = [super init]) {
        self.uniqueId = uniqueId;
        self.weekday = weekday;
        self.channelId = chnId;
        self.data = data;
    }
    
    return self;
}



- (NSArray *)parser
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    long long data = self.data;
    
    NSDate *start = nil;
    NSDate *end = nil;
    for (int halfHour = 0; halfHour < 48; halfHour++) {
        long long value = 0x0000000000000001;
        value <<= halfHour;
        BOOL state = ((data & value) != 0x0000000000000000);
        if (state) {
            //该半小时在计划内
            //查看是否是一段时间的起始时间
            if (!start) {
                //更新起始时间
                start = [NSDate dateFromHalfHour:halfHour];
            }
            
            //更新结束时间
            end = [NSDate dateFromHalfHour:halfHour+1];
            
        } else if (end) {
            //存在结束时间，将前一段时间保存至数组
            DateRange *range = [DateRange dateRangeWithStartDate:[start time] endDate:[end time]];
            [results addObject:range];
            
            //清空开始时间 和 结束时间
            start = nil;
            end = nil;
        }
    }
    
    if (end) {
        DateRange *range = [DateRange dateRangeWithStartDate:[start time] endDate:[end time]];
        [results addObject:range];
    }
    
    
    return [NSArray arrayWithArray:results];
}
@end
