//
//  DetectSettingViewController.m
//  VMS
//
//  Created by mac_dev on 15/8/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "DetectSettingViewController.h"

#define ID_MOTION_SENSITIVITY           @"motion sensitivity"
#define ID_MOTION_TRIGGER_INTERVAL      @"motion trigger interval"
#define ID_MOTION_SNAP_INTERVAL         @"motion snap interval"
#define ID_MOTION_SCHEDULES             @"motion schedules"
#define ID_AUDIO_SENSITIVITY            @"audio sensitivity"
#define ID_AUDIO_TRIGGER_INTERVAL       @"audio trigger interval"
#define ID_AUDIO_SNAP_INTERVAL          @"audio snap interval"
#define ID_AUDIO_SCHEDULES              @"audio schedules"
#define ID_TEMPERATURE_TRIGGER_INTERVAL @"temperature trigger interval"
#define ID_TEMPERATURE_SNAP_INTERVAL    @"temperature snap interval"
#define ID_TEMPERATURE_SCHEDULES        @"temperature schedules"

@implementation DetectSettingViewController

#pragma mark - public api
//重写下面这些方法
- (void)setMDC:(void *)config
{}

- (void)performFetch
{}

- (void)performPush
{}

- (void)updateMotionDetectConfigUI
{}

- (void)layout
{}

- (void)push:(NSInteger)tag
{
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^
    {
        switch (tag) {
            case 0: {
                [self performPush];
            }
                break;
            default: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
        }
    });
}

- (void)refetch:(NSInteger)tag
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^
    {
        switch (tag) {
            case 0: {
                [self performFetch];
            }
                break;
            default: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
        }
    });
}

#pragma mrak - action
- (IBAction)editDetectionArea:(id)sender
{
    if (!self.detectionAreasEditWindowController) {
        DetectionAreasEditWindowController *daewc = [self daewc];
        //成功加在侦测区域编辑MVC
        if (daewc) {
            //使用成员变量Hold住该MVC
            [self setDetectionAreasEditWindowController:daewc];
            [self.view.window beginSheet:daewc.window completionHandler:^(NSModalResponse returnCode) {
                [self setMDC:daewc.detectConfig];
                [daewc close];
                [self setDetectionAreasEditWindowController:nil];
            }];
        }
    }
}


#pragma mark - time picker view delegate
- (BOOL)timePickerView :(TimePickerView *)view
     shouldSelectAtRow :(NSUInteger)row
              atColumn :(NSUInteger)column
{
    long long *schedules = NULL;
    NSString *identifier = [view identifier];
    if ([identifier isEqualToString:ID_MOTION_SCHEDULES])
        schedules = _motionSchedules;
 
    long long value = 0x0000000000000001;
    value <<= column;
   
    return schedules? ((schedules[row] & value) != 0x0000000000000000) : NO;
}

- (void)timePickerView :(TimePickerView *)view
   userAlternatedAtRow :(NSUInteger)row atColumn
                       :(NSUInteger)column
{
    NSString *identifier = [view identifier];
    long long *schedules = NULL;
    if ([identifier isEqualToString:ID_MOTION_SCHEDULES])
        schedules = _motionSchedules;
    
    if (schedules) {
        long long value = 0x0000000000000001;
        value <<= column;
        
        BOOL state = ((schedules[row] & value) != 0x0000000000000000);
        schedules[row] = !state? (schedules[row] | value) : (schedules[row] & ~value);
    }
}


- (void)timePickerView :(TimePickerView *)view
     userCheckedColumn :(NSUInteger)column
             withState :(BOOL)state
{
    long long *schedules = NULL;
    NSString *identifier = [view identifier];
    if ([identifier isEqualToString:ID_MOTION_SCHEDULES])
        schedules = _motionSchedules;
    
    if (schedules) {
        long long value = 0x0000000000000001;
        value <<= column;
        for (int weekday = 0; weekday < 7; weekday++) {
            schedules[weekday] = state? (schedules[weekday] | value) : (schedules[weekday] & ~value);
        }
    }
}

-(void)timePickerView :(TimePickerView *)view
       userCheckedRow :(NSUInteger)row
            withState :(BOOL)state
{
    long long *schedules = NULL;
    NSString *identifier = [view identifier];
    if ([identifier isEqualToString:ID_MOTION_SCHEDULES])
        schedules = _motionSchedules;
    
    if (schedules) {
        for (int halfHour = 0; halfHour < 48; halfHour++) {
            long long value = 0x0000000000000001;
            value = value << halfHour;
            schedules[row] = state? (schedules[row] | value) : (schedules[row] & ~value);
        }
    }
}

- (void)timePickerView :(TimePickerView *)view userCheckedAllWithState :(BOOL)state
{
    long long *schedules = NULL;
    NSString *identifier = [view identifier];
    if ([identifier isEqualToString:ID_MOTION_SCHEDULES])
        schedules = _motionSchedules;
   
    if (schedules) {
        for (int weekday = 0; weekday < 7; weekday++) {
            for (int halfHour = 0; halfHour < 48; halfHour++) {
                long long value = 0x0000000000000001;
                value <<= halfHour;
                _motionSchedules[weekday] = state? (_motionSchedules[weekday] | value) : (_motionSchedules[weekday] & ~value);
            }
        }
    }
}

#pragma mark - life cycle
- (void)awakeFromNib
{
    //初始化成员变量
    for (int i = 0; i < 7; i++) {
        _motionSchedules[i] = 0x000000000000000f;
    }
}

- (void)viewDidLoad {
     [super viewDidLoad];
}

- (void)viewWillLayout
{
    [super viewWillLayout];
    [self layout];
}

#pragma mark - setter && getter
- (void)setMotionTriggerIntervalBtn:(NSPopUpButton *)motionTriggerIntervalBtn
{
    _motionTriggerIntervalBtn = motionTriggerIntervalBtn;
    [self setControl:_motionTriggerIntervalBtn withRange:[self motionTriggerIntervalRange]];
}

- (void)setMotionSnapIntervalBtn:(NSPopUpButton *)motionSnapIntervalBtn
{
    _motionSnapIntervalBtn = motionSnapIntervalBtn;
    [self setControl:_motionSnapIntervalBtn withRange:[self motionSnapIntervalRange]];
}

- (DetectionAreasEditWindowController *)daewc
{
    return nil;
}


#pragma mark - control data
- (NSRange)motionTriggerIntervalRange
{
    return NSMakeRange(5, 11);
}

- (NSRange)motionSnapIntervalRange
{
    return NSMakeRange(1, 5);
}

- (NSArray *)availableSensitivity
{
    return [NSArray arrayWithObjects:@4,@3,@0,@1,@2, nil];
}

- (NSArray *)availableTriggerInterval
{
    return [NSArray arrayWithObjects:@"5s",@"6s",@"7s",@"8s",@"9s",@"10s",@"11s",@"12s",@"13s",@"14s",@"15s", nil];
}

- (NSArray *)availableSnapInterval
{
    return [NSArray arrayWithObjects:@1,@2,@3,@4,@5, nil];
}
@end
