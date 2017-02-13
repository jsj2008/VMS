//
//  SystemSettingSheetController.h
//  VMS
//
//  Created by mac_dev on 15/8/24.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSDate+HalfHour.h"
#import "Channel.h"
#import "TimePickerView.h"
#import "BasicSetting.h"
#import "VMSRecordSetting.h"
#import "VMSBasicSetting.h"
#import "VMSDatabase.h"


#define KEY_RECORDING_SETTING   @"RECORDING_SETTING"
#define KEY_ENABLE_RECORDING    @"ENABLE_RECORDING"
#define KEY_RECORDING_PATHNAME  @"RECORDING_PATHNAME"
#define KEY_RECORDING_RESTRICT  @"RECORDING_RESTRICT"
#define KEY_RECORDING_SIZE      @"RECORDING_SIZE"
#define KEY_RECORDING_TIME      @"RECORDING_TIME"
#define KEY_CHANNEL             @"CHANNEL"
#define KEY_PLAN                @"PLAN"
#define KEY_WEEKDAY             @"WEEKDAY"
#define KEY_BEGIN_DATE          @"BEGIN_DATE"
#define KEY_END_DATE            @"END_DATE"


@interface SystemSettingSheetController : NSWindowController<NSTableViewDataSource,
NSTableViewDelegate,NSComboBoxDataSource,NSTabViewDelegate>

@property (nonatomic,copy) VMSRecordSetting *recording_setting;
@property (nonatomic) VMSBasicSetting *basic_setting;
//录像计划(输入,输出)
@property (copy,nonatomic) NSMutableArray *recordPlan;

+ (BOOL)setStartupAtBoot :(BOOL)isStartUp;
@end
