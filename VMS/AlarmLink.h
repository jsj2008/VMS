//
//  AlarmLink.h
//  VMS
//
//  Created by mac_dev on 15/12/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, VMS_ALARM_LINKAGE) {
    VMS_ALARM_IS_RECORD = 1 << 0,
    VMS_ALARM_IS_RING = 1 << 1,
    VMS_ALARM_IS_SNAP = 1 << 2,
    VMS_ALARM_IS_SHOW_VIDIO = 1 << 3,
};


@class Channel;

@interface AlarmLink : NSObject

@property (assign,nonatomic) int uniqueId;
@property (assign,nonatomic) int alarmType;
@property (assign,nonatomic) VMS_ALARM_LINKAGE linkage;
@property (assign,nonatomic) int channelId;

- (instancetype)initWithUniqueId :(int)uniqueId
                       alarmType :(int)alarmType
                         linkage :(VMS_ALARM_LINKAGE)linkage
                       channelId :(int)channelId;
@end
