//
//  AlarmLink.m
//  VMS
//
//  Created by mac_dev on 15/12/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "AlarmLink.h"

@implementation AlarmLink

- (instancetype)initWithUniqueId :(int)uniqueId
                       alarmType :(int)alarmType
                         linkage :(VMS_ALARM_LINKAGE)linkage
                       channelId :(int)channelId
{
    if (self = [super init]) {
        self.uniqueId = uniqueId;
        self.alarmType = alarmType;
        self.linkage = linkage;
        self.channelId = channelId;
    }
    
    return self;
}
@end
