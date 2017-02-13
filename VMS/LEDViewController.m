//
//  LEDViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "LEDViewController.h"

@interface LEDViewController ()

@property (nonatomic,assign) BOOL isEnableSchedule1;
@property (nonatomic,assign) BOOL isEnableSchedule2;
@property (nonatomic,assign) BOOL isEnableSchedule3;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginHour1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginMin1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endHour1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endMin1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginHour2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginMin2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endHour2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endMin2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginHour3Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginMin3Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endHour3Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endMin3Btn;

@end

@implementation LEDViewController
#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    __block BOOL success = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOS_SCHEDULEINFRALEDCONFIG scheduleInfraLedConfig;
        config.info = &scheduleInfraLedConfig;
        success = success && [center getConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_IRLAMP_PLAN fromDevice:device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setScheduleInfraLedConfig:scheduleInfraLedConfig];
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    [self setActivity:YES];
    __block FOS_SCHEDULEINFRALEDCONFIG scheduleInfraLedConfig;
    int result = [self ledScheduleFromUI:&scheduleInfraLedConfig];
    
    if (result == 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
            
            FOSCAM_NET_CONFIG config;
            config.info = &scheduleInfraLedConfig;
            
            BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                    forType:FOSCAM_NET_CONFIG_VIDEO_IRLAMP_PLAN
                                                                   toDevice:self.device];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success)
                    [self alert:NSLocalizedString(@"failed to set the settings", nil)
                           info:NSLocalizedString(@"time out", nil)];
                [self setActivity:NO];
            });
        });
    }
    else {
        [self alert:NSLocalizedString(@"failed to set the settings", nil)
               info:NSLocalizedString(@"the end time must be greater than the start time", nil)];
        [self setActivity:NO];
    }
}

- (NSString *)description
{
    return NSLocalizedString(@"Led Schedule", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

#pragma mark - private api
- (BOOL)isScheduleValidStartHour :(int)h1 startMin :(int)m1 endHour:(int)h2 endMin :(int)m2
{
    return (h1 * 60 + m1)  < (h2 *60 + m2);
}

- (NSArray *)hours
{
    NSMutableArray *hours = [[NSMutableArray alloc] init];
    for (int hour = 0; hour < 24 ; hour++)
        [hours addObject:[NSNumber numberWithInt:hour]];
    
    return hours;
}

- (NSArray *)minutes
{
    NSMutableArray *minutes = [[NSMutableArray alloc] init];
    for (int minute = 0; minute < 60; minute++)
        [minutes addObject:[NSNumber numberWithInt:minute]];
    
    return minutes;
}

#pragma mark - collect from UI
- (int)ledScheduleFromBeginHourBtns :(NSArray *)h1Btns
                       beginMinBtns :(NSArray *)m1Btns
                        endHourBtns :(NSArray *)h2Btns
                         endMinBtns :(NSArray *)m2Btns
                    enableSchedules :(BOOL [])enables
                             config :(FOS_SCHEDULEINFRALEDCONFIG *)cfg
{
    int idx = 0;
    for (int i = 0; i < FOS_LED_SCHEDULE_COUNT; i++) {
        
        if (enables[i]) {
            cfg->startHour[i]   = (int)[(NSPopUpButton *)h1Btns[i] indexOfSelectedItem];
            cfg->startMin[i]    = (int)[(NSPopUpButton *)m1Btns[i] indexOfSelectedItem];
            cfg->endHour[i]     = (int)[(NSPopUpButton *)h2Btns[i] indexOfSelectedItem];
            cfg->endMin[i]      = (int)[(NSPopUpButton *)m2Btns[i] indexOfSelectedItem];
            
            if (![self isScheduleValidStartHour:cfg->startHour[i]
                                       startMin:cfg->startMin[i]
                                        endHour:cfg->endHour[i]
                                         endMin:cfg->endMin[i]]) {
                idx = i + 1;
                break;
            }
        }
    }
    
    return idx;
}

- (int)ledScheduleFromUI :(FOS_SCHEDULEINFRALEDCONFIG *)cfg
{
    for (int i = 0; i < FOS_LED_SCHEDULE_COUNT; i++) {
        cfg->startHour[i] = 0;
        cfg->startMin[i] = 0;
        cfg->endHour[i]  = 0;
        cfg->endMin[i] = 0;
    }
    
    NSArray *h1Btns = @[self.beginHour1Btn,self.beginHour2Btn,self.beginHour3Btn];
    NSArray *m1Btns = @[self.beginMin1Btn,self.beginMin2Btn,self.beginMin3Btn];
    NSArray *h2Btns = @[self.endHour1Btn,self.endHour2Btn,self.endHour3Btn];
    NSArray *m2Btns = @[self.endMin1Btn,self.endMin2Btn,self.endMin3Btn];
    BOOL enables[] = {self.isEnableSchedule1,self.isEnableSchedule2,self.isEnableSchedule3};
    
    return [self ledScheduleFromBeginHourBtns:h1Btns
                                 beginMinBtns:m1Btns
                                  endHourBtns:h2Btns
                                   endMinBtns:m2Btns
                              enableSchedules:enables
                                       config:cfg];
}

#pragma mark - update UI
- (void)updateControl :(NSPopUpButton *)btn withHour :(NSUInteger)hour
{
    if (hour < [self hourRange].length) {
        [btn selectItemAtIndex:hour];
    }
}

- (void)updateControl :(NSPopUpButton *)btn withMinutes :(NSUInteger)min
{
    if (min < [self minutesRange].length) {
        [btn selectItemAtIndex:min];
    }
}

- (void)updateLEDScheduleWithBeginHourBtns :(NSArray *)h1Btns
                              beginMinBtns :(NSArray *)m1Btns
                               endHourBtns :(NSArray *)h2Btns
                                endMinBtns :(NSArray *)m2Btns
                           enableSchedules :(BOOL [])enables
                                    config :(FOS_SCHEDULEINFRALEDCONFIG *)cfg
{
    for (int i = 0; i < FOS_LED_SCHEDULE_COUNT; i++) {
        enables[i] = [self isScheduleValidStartHour:cfg->startHour[i]
                                           startMin:cfg->startMin[i]
                                            endHour:cfg->endHour[i]
                                             endMin:cfg->endMin[i]];
        
        [self updateControl:h1Btns[i] withHour:cfg->startHour[i]];
        [self updateControl:m1Btns[i] withMinutes:cfg->startMin[i]];
        [self updateControl:h2Btns[i] withHour:cfg->endHour[i]];
        [self updateControl:m2Btns[i] withMinutes:cfg->endMin[i]];
    }
}

- (void)updateLEDScheduleUI
{
    FOS_SCHEDULEINFRALEDCONFIG scheduleCfg = self.scheduleInfraLedConfig;
    NSArray *h1Btns = @[self.beginHour1Btn,self.beginHour2Btn,self.beginHour3Btn];
    NSArray *m1Btns = @[self.beginMin1Btn,self.beginMin2Btn,self.beginMin3Btn];
    NSArray *h2Btns = @[self.endHour1Btn,self.endHour2Btn,self.endHour3Btn];
    NSArray *m2Btns = @[self.endMin1Btn,self.endMin2Btn,self.endMin3Btn];
    BOOL enables[FOS_LED_SCHEDULE_COUNT] = {0};
    
    [self updateLEDScheduleWithBeginHourBtns:h1Btns
                                beginMinBtns:m1Btns
                                 endHourBtns:h2Btns
                                  endMinBtns:m2Btns
                             enableSchedules:enables
                                      config:&scheduleCfg];
    self.isEnableSchedule1 = enables[0];
    self.isEnableSchedule2 = enables[1];
    self.isEnableSchedule3 = enables[2];
}

#pragma mark - setter & getter
- (void)setControl :(NSPopUpButton *)btn withRange :(NSRange)range
{
    [btn removeAllItems];
    for (int i = 0; i < range.length; i++) {
        NSString *title = [NSString stringWithFormat:@"%2d",(int)range.location + i];
        [btn addItemWithTitle:title];
    }
}
- (void)setScheduleInfraLedConfig:(FOS_SCHEDULEINFRALEDCONFIG)scheduleInfraLedConfig
{
    _scheduleInfraLedConfig = scheduleInfraLedConfig;
    [self updateLEDScheduleUI];
}

- (void)setBeginHour1Btn:(NSPopUpButton *)beginHour1Btn
{
    _beginHour1Btn = beginHour1Btn;
    [self setControl:beginHour1Btn withRange:[self hourRange]];
}

- (void)setBeginMin1Btn:(NSPopUpButton *)beginMin1Btn
{
    _beginMin1Btn = beginMin1Btn;
    [self setControl:beginMin1Btn withRange:[self minutesRange]];
}

- (void)setEndHour1Btn:(NSPopUpButton *)endHour1Btn
{
    _endHour1Btn = endHour1Btn;
    [self setControl:endHour1Btn withRange:[self hourRange]];
}

- (void)setEndMin1Btn:(NSPopUpButton *)endMin1Btn
{
    _endMin1Btn = endMin1Btn;
    [self setControl:_endMin1Btn withRange:[self minutesRange]];
}


- (void)setBeginHour2Btn:(NSPopUpButton *)beginHour2Btn
{
    _beginHour2Btn = beginHour2Btn;
    [self setControl:beginHour2Btn withRange:[self hourRange]];
}

- (void)setBeginMin2Btn:(NSPopUpButton *)beginMin2Btn
{
    _beginMin2Btn = beginMin2Btn;
    [self setControl:beginMin2Btn withRange:[self minutesRange]];
}

- (void)setEndHour2Btn:(NSPopUpButton *)endHour2Btn
{
    _endHour2Btn = endHour2Btn;
    [self setControl:endHour2Btn withRange:[self hourRange]];
}

- (void)setEndMin2Btn:(NSPopUpButton *)endMin2Btn
{
    _endMin2Btn = endMin2Btn;
    [self setControl:_endMin2Btn withRange:[self minutesRange]];
}


- (void)setBeginHour3Btn:(NSPopUpButton *)beginHour3Btn
{
    _beginHour3Btn = beginHour3Btn;
    [self setControl:beginHour3Btn withRange:[self hourRange]];
}

- (void)setBeginMin3Btn:(NSPopUpButton *)beginMin3Btn
{
    _beginMin3Btn = beginMin3Btn;
    [self setControl:beginMin3Btn withRange:[self minutesRange]];
}

- (void)setEndHour3Btn:(NSPopUpButton *)endHour3Btn
{
    _endHour3Btn = endHour3Btn;
    [self setControl:endHour3Btn withRange:[self hourRange]];
}

- (void)setEndMin3Btn:(NSPopUpButton *)endMin3Btn
{
    _endMin3Btn = endMin3Btn;
    [self setControl:_endMin3Btn withRange:[self minutesRange]];
}

#pragma mark - NSPopupButton Data
- (NSRange)hourRange
{
    return NSMakeRange(0, 24);
}

- (NSRange)minutesRange
{
    return NSMakeRange(0, 60);
}
@end
