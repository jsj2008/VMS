//
//  ScheduledRecordTask.m
//  VMS
//
//  Created by mac_dev on 15/7/30.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "ScheduledRecordTask.h"

@implementation ScheduledRecordTask

- (id)initWithUniqueId :(int)uniqueId
                 start :(NSDate *)start
                   end :(NSDate *)end
               weekday :(int)weekday
               channel :(Channel *)channel
{
    if (self = [super init]) {
        self.uniqueId = uniqueId;
        self.start = start;
        self.end = end;
        self.weekday = weekday;
        self.channel = channel;
    }
    
    return self;
}
@end
