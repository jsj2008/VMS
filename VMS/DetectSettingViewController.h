//
//  DetectSettingViewController.h
//  VMS
//
//  Created by mac_dev on 15/8/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"
#import "TimePickerView/TimePickerView.h"
#import "DetectionAreasEditWindowController.h"



@interface DetectSettingViewController : SettingViewController<TimePickerViewDelegate,NSComboBoxDataSource> {
    long long _motionSchedules[7];
}

- (void)push:(NSInteger)tag;
- (void)refetch:(NSInteger)tag;

@property (nonatomic,assign) BOOL isEnableMotionDetect;
@property (nonatomic,assign) BOOL isEnableMotionRing;
@property (nonatomic,assign) BOOL isEnablePCAudioAlarm;
@property (nonatomic,assign) BOOL isEnableMotionMail;
@property (nonatomic,assign) BOOL isEnableMotionSnap;
@property (nonatomic,assign) BOOL isEnableMotionRecord;
@property (nonatomic,assign) BOOL isEnableMotionPushPhone;
@property (nonatomic,weak) IBOutlet NSPopUpButton *motionSensitivityBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *motionTriggerIntervalBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *motionSnapIntervalBtn;
@property (nonatomic,weak) IBOutlet TimePickerView *motionSchedulesPicker;
@property (nonatomic,weak) IBOutlet NSView *zone1;
@property (nonatomic,weak) IBOutlet NSView *zone2;
@property (nonatomic,strong) DetectionAreasEditWindowController *detectionAreasEditWindowController;

- (NSArray *)availableSensitivity;
- (NSArray *)availableTriggerInterval;
- (NSArray *)availableSnapInterval;

//下面这些方法需要被重写
- (void)setMDC :(void *)config;
- (void)performFetch;
- (void)performPush;
- (void)layout;
- (void)updateMotionDetectConfigUI;
- (DetectionAreasEditWindowController *)daewc;
@end
