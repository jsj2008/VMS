//
//  ScheduleRecordViewController.h
//  
//
//  Created by mac_dev on 16/6/1.
//
//

#import "SettingViewController.h"
#import "TimePickerView.h"

@interface ScheduleRecordViewController : SettingViewController

@property(nonatomic,assign) FOS_SCHEDULERECORDCONFIG scheduleRecordConfig;
- (void)fetch;
- (void)push;
- (NSString *)description;
- (SVC_OPTION)option;
- (FOS_SCHEDULERECORDCONFIG)scheduleRecordConfigFromUI;

@end
