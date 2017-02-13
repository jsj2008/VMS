//
//  VMSAlarmControlleer.h
//  VMS
//
//  Created by mac_dev on 15/12/30.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DispatchCenter.h"
#import "VMSDatabase.h"
#import "RecordCenter.h"
#import "VMSBasicSetting.h"
#import "NSImage+Flip.h"
#import "NSImage+SaveAsJpegWithName.h"
#import "../libplay/libplay/avplay_sdk.h"




#define VMS_ALARM_RECORD_NOTIFICATION   @"vms alarm record notification"
#define VMS_ALARM_SNAP_NOTIFICATION     @"vms alarm snap notification"
#define KEY_ALARM_CHANNEL_ID            @"alarm channel id"
#define KEY_ALARM_STREAM_TYPE           @"alarm stream type"


@interface VMSAlarmController : NSObject<DispatchProtocal>

- (instancetype)init;
@end
