//
//  AmbaDetectSettingViewController.m
//  
//
//  Created by mac_dev on 16/4/1.
//
//

#import "AmbaDetectSettingViewController.h"

@interface AmbaDetectSettingViewController ()

@end

@implementation AmbaDetectSettingViewController

#pragma mark - public
- (DetectionAreasEditWindowController *)daewc
{
    Channel *chn = self.device.children[0];
    return [[AmbaDetectionAreaEditWindowController alloc] initWithWindowNibName:@"AmbaDetectionAreaEditWindowController"
                                                                      channelId:chn.uniqueId
                                                                   detectConfig:self.motionDetectConfig];
}

- (void)setMDC :(void *)config
{
    self.motionDetectConfig = *((FOS_MOTIONDETECTCONFIG1 *)config);
}

- (void)performFetch
{
    FOSCAM_NET_CONFIG config;
    FOS_MOTIONDETECTCONFIG1 motionDetectConfig;
    
    config.info = &motionDetectConfig;
    
    BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                            forType:FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT1
                                                         fromDevice:self.device];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success)
            [self setMotionDetectConfig:motionDetectConfig];
        else
            [self alert:@"超时"];
        [self setActivity:NO];
    });
}

- (void)performPush
{
    FOSCAM_NET_CONFIG config;
    FOS_MOTIONDETECTCONFIG1 motionDetectConfig = [self motionDetectConfigFromUI];
    
    config.info = &motionDetectConfig;
    
    BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                            forType:FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT1
                                                           toDevice:self.device];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!success) [self alert:@"超时"];
        [self setActivity:NO];
    });
}

- (void)layout
{
    //隐藏区域1
    [self.zone1 setHidden:YES];
    //移动区域2
    NSRect frame1 = self.zone1.frame;
    NSRect frame2 = self.zone2.frame;
    if (frame1.origin.y - frame2.origin.y == frame2.size.height) {
        //[self.zone2 setFrame:NSOffsetRect(frame2, 0, frame1.size.height)];
        self.zone2.frame = NSOffsetRect(frame2, 0, frame1.size.height);
    }
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
    
    //报警触发间隔
    index = self.motionDetectConfig.triggerInterval;
    if (index >= [self availableTriggerInterval].count) index = 0;
    [self.motionTriggerIntervalBtn selectItemAtIndex :index];
}

- (FOS_MOTIONDETECTCONFIG1)motionDetectConfigFromUI
{
    //启用
    _motionDetectConfig.isEnable = self.isEnableMotionDetect;
    
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
    
    _motionDetectConfig.linkage = linkage;
    
    //抓拍时间间隔
    int index = (int)[self.motionSnapIntervalBtn indexOfSelectedItem];
    _motionDetectConfig.snapInterval = [[self availableSnapInterval][index] intValue];
    
    //计划
    for (int i = 0; i < 7; i++)
        _motionDetectConfig.schedules[i] = _motionSchedules[i];
    
    //报警触发间隔
    _motionDetectConfig.triggerInterval = (int)[self.motionTriggerIntervalBtn indexOfSelectedItem];
    return _motionDetectConfig;
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - setter & getter
- (void)setMotionDetectConfig:(FOS_MOTIONDETECTCONFIG1)motionDetectConfig
{
    _motionDetectConfig = motionDetectConfig;
    [self updateMotionDetectConfigUI];
}

@end
