//
//  HsDetectSettingViewController.m
//  
//
//  Created by mac_dev on 16/4/1.
//
//

#import "HsDetectSettingViewController.h"

@interface HsDetectSettingViewController ()

@end

@implementation HsDetectSettingViewController

#pragma mark - public api
- (DetectionAreasEditWindowController *)daewc
{
    Channel *chn = self.device.children[0];
    return [[HsDetectionAreaEditWindowController alloc] initWithWindowNibName:@"HsDetectionAreasEditWindowController"
                                                                    channelId:chn.uniqueId
                                                                 detectConfig:self.motionDetectConfig];
}

- (void)setMDC :(void *)config
{
    self.motionDetectConfig = *((FOS_MOTIONDETECTCONFIG *)config);
}

- (void)performPush
{
    CDevice *device = self.device;
    FOSCAM_NET_CONFIG config;
    FOS_MOTIONDETECTCONFIG motionDetectConfig = [self motionDetectConfigFromUI];
    for (int i=0; i<FOS_MAX_AREA_COUNT; i++) {
        motionDetectConfig.areas[i] = self.motionDetectConfig.areas[i];
    }
    config.info = &motionDetectConfig;
    
    BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                            forType:FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT
                                                           toDevice:device];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!success) [self alert:@"超时"];
        [self setActivity:NO];
    });
}

- (void)performFetch
{
    FOSCAM_NET_CONFIG config;
    FOS_MOTIONDETECTCONFIG motionDetectConfig;
    
    config.info = &motionDetectConfig;
    
    BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                            forType:FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT
                                                         fromDevice:self.device];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success)
            [self setMotionDetectConfig:motionDetectConfig];
        else
            [self alert:@"超时"];
        [self setActivity:NO];
    });
}


- (void)updateMotionDetectConfigUI
{
    //启用
    self.isEnableMotionDetect = self.motionDetectConfig.isEnable;
    //报警联动策略
    //mask
    int ring = 0x00000001;
    int mail = 0x00000002;
    int snap = 0x00000004;
    int record = 0x00000008;
    int pushPhone = 0x00000080;
    //value
    self.isEnableMotionRing = (self.motionDetectConfig.linkage & ring) != (0x00000000);
    self.isEnableMotionMail = (self.motionDetectConfig.linkage & mail) != (0x00000000);
    self.isEnableMotionSnap = (self.motionDetectConfig.linkage & snap) != (0x00000000);
    self.isEnableMotionRecord = (self.motionDetectConfig.linkage & record) != (0x00000000);
    self.isEnableMotionPushPhone = (self.motionDetectConfig.linkage & pushPhone) != (0x00000000);
    
    //抓拍时间间隔
    NSUInteger index = [[self availableSnapInterval] indexOfObject:[NSNumber numberWithInt:self.motionDetectConfig.snapInterval]];
    if (index == NSNotFound) index = 0;
    if (index < [self.motionSnapIntervalBtn itemArray].count) {
        [self.motionSnapIntervalBtn selectItemAtIndex :index];
    }
    
    
    //计划
    for (int weekday = 0; weekday < 7; weekday++)
        _motionSchedules[weekday] = self.motionDetectConfig.schedules[weekday];
    
    [self.motionSchedulesPicker setNeedsDisplay:YES];
    //灵敏度
    index = [[self availableSensitivity] indexOfObject:[NSNumber numberWithInt:self.motionDetectConfig.sensitivity]];
    if (index == NSNotFound) index = 0;
    if (index < self.motionSensitivityBtn.itemArray.count) {
        [self.motionSensitivityBtn selectItemAtIndex:index];
    }
    
    //报警触发间隔
    index = self.motionDetectConfig.triggerInterval;
    if (index >= [self availableTriggerInterval].count) index = 0;
    [self.motionTriggerIntervalBtn selectItemAtIndex :index];
}

- (FOS_MOTIONDETECTCONFIG)motionDetectConfigFromUI
{
    FOS_MOTIONDETECTCONFIG config;
    //启用
    config.isEnable = self.isEnableMotionDetect;
    
    //报警联动策略
    int ring = 0x00000001;
    int mail = 0x00000002;
    int snap = 0x00000004;
    int record = 0x00000008;
    int pushPhone = 0x00000080;
    
    int linkage = 0;
    if (self.isEnableMotionRing) linkage |= ring;
    if (self.isEnableMotionMail) linkage |= mail;
    if (self.isEnableMotionSnap) linkage |= snap;
    if (self.isEnableMotionRecord) linkage |= record;
    if (self.isEnableMotionPushPhone) linkage |= pushPhone;
    
    config.linkage = linkage;
    
    //抓拍时间间隔
    int index = (int)[self.motionSnapIntervalBtn indexOfSelectedItem];
    config.snapInterval = [[self availableSnapInterval][index] intValue];
    
    //计划
    for (int i = 0; i < 7; i++)
        config.schedules[i] = _motionSchedules[i];
    
    //灵敏度
    index = (int)[self.motionSensitivityBtn indexOfSelectedItem];
    config.sensitivity = [[self availableSensitivity][index] intValue];
    
    //报警触发间隔
    config.triggerInterval = (int)[self.motionTriggerIntervalBtn indexOfSelectedItem];
    return config;
}

#pragma mark - setter & getter
- (void)setMotionDetectConfig:(FOS_MOTIONDETECTCONFIG)motionDetectConfig
{
    _motionDetectConfig = motionDetectConfig;
    [self updateMotionDetectConfigUI];
}
@end
