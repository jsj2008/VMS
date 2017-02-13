//
//  VMSAlarmControlleer.m
//  VMS
//
//  Created by mac_dev on 15/12/30.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VMSAlarmController.h"
#import "DispatchCenter.h"

#define alarmController_debug   0

@interface VMSAlarmController()
@property (nonatomic,strong) NSLock     *lock;
@property (nonatomic,strong) NSSound    *ring;
@end


@implementation VMSAlarmController

- (instancetype)init
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        //开始接受报警出现通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDispatchCenterNotification:)
                                                     name:ALARM_STATE_DID_CHANGE_NOTIFICATION
                                                   object:nil];
        [[DispatchCenter sharedDispatchCenter] addObserver:self];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[DispatchCenter sharedDispatchCenter] removeObserver:self];
}

#pragma mark - dispatch center protocol
- (void)handleDispatchCenterNotification :(NSNotification *)aNotific
{
    if (alarmController_debug) {
        NSLog(@"Running in %@,'%@'",[self class],NSStringFromSelector(_cmd));
    }
    
    if ([aNotific.name isEqualToString:ALARM_STATE_DID_CHANGE_NOTIFICATION]) {
        //解析该通知
        int devId = [[aNotific.userInfo valueForKey:KEY_EVENT_DEVICE_ID] intValue];
        int logicId = [[aNotific.userInfo valueForKey:KEY_EVENT_CHANNEL_ID] intValue];
        BOOL state = [[aNotific.userInfo valueForKey:KEY_ALARM_STATE] boolValue];
        
        //调度回同一个队列，顺序执行
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            VMSDatabase *db             = [VMSDatabase sharedVMSDatabase];
            NSDate      *now            = [NSDate date];
            NSArray     *scheduledTasks = [db fetchScheduledTasksWithWeekday:(int)now.weekDay entity:@"t_alarm_plan"];
            int         chnId           = [db fetchChannelIdWithDeviceId:devId logicId:logicId];
            
            for (ScheduledTask *task in scheduledTasks) {
                //查找对应的通道
                if (task.channelId == chnId) {
                    NSArray *dateRanges = [task parser];
                    
                    for (DateRange *range in dateRanges) {
                        //判断是否在该计划内
                        if ([range isContainDate:now.time]) {
                            //查看报警联动
                            AlarmLink *alarmLink = [db fetchAlarmLinkWithChannelId:chnId];
                            //报警铃
                            if (state && (alarmLink.linkage & VMS_ALARM_IS_RING) && !self.ring.isPlaying) {
                                [self.ring play];
                            }
                            
                            //抓拍
                            if (state && (alarmLink.linkage & VMS_ALARM_IS_SNAP)) {
                                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                                
                                [userInfo setValue:[NSNumber numberWithInteger :task.channelId] forKey:KEY_ALARM_CHANNEL_ID];
                                [center postNotificationName:VMS_ALARM_SNAP_NOTIFICATION
                                                      object:self
                                                    userInfo:userInfo];
                            }
                            
                            
                            if (state) {
                                if ((alarmLink.linkage & VMS_ALARM_IS_RECORD)) {
                                    [[RecordCenter sharedRecordCenter] switchRecordingState:YES withChannelId:chnId type:AlarmRecord];
                                }
                            }
                            else {
                                [[RecordCenter sharedRecordCenter] switchRecordingState:NO withChannelId:chnId type:AlarmRecord];
                            }
                        }
                    }
                }
            }
        });
    }
}

- (NSSound *)ring
{
    if (!_ring) {
        NSString *alarmFilePath = [[NSBundle mainBundle] pathForResource:@"Alarm" ofType:@"wav"];
        _ring = [[NSSound alloc] initWithContentsOfFile:alarmFilePath byReference:YES];
    }
    
    return _ring;
}

@end
