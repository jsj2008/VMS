//
//  ScheduledRecordTask.h
//  VMS
//
//  Created by mac_dev on 15/7/30.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Channel;

@interface ScheduledRecordTask : NSObject
//1~7代表星期日 ~ 星期六
//这里的NSDate 统一使用timeOnlyDate
@property (assign,nonatomic) int uniqueId;
@property (assign,nonatomic) int weekday;
@property (assign,nonatomic) NSDate *start;
@property (assign,nonatomic) NSDate *end;
@property (strong,nonatomic) Channel *channel;

- (id)initWithUniqueId :(int)uniqueId
                 start :(NSDate *)start
                   end :(NSDate *)end
               weekday :(int)weekday
               channel :(Channel *)channel;
@end
