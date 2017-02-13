//
//  AlarmTask.h
//  VMS
//
//  Created by mac_dev on 15/12/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScheduledRecordTask.h"
//#import "Channel.h"
#import "DateRange.h"
#import "NSDate+HalfHour.h"
#import "NSDate + SRAdditions.h"

@interface ScheduledTask : NSObject

@property (assign,nonatomic) int uniqueId;
@property (assign,nonatomic) int weekday;
@property (assign,nonatomic) long long data;
@property (assign,nonatomic) int channelId;



-(instancetype)initWithUniqueId:(int)uniqueId
                        weekday:(int)weekday
                      channelId:(int)chnId
                          data :(long long)data;

//解析任务数据,结果为DateRange对象 存储在 数组中
- (NSArray *)parser;
@end
