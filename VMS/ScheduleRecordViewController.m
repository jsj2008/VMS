//
//  ScheduleRecordViewController.m
//  
//
//  Created by mac_dev on 16/6/1.
//
//

#import "ScheduleRecordViewController.h"


#define ID_RECORD_SCHEDULES @"record schedules"
@interface ScheduleRecordViewController ()

@property (nonatomic,weak) IBOutlet NSPopUpButton *scheduleRecordBtn;
@property (nonatomic,weak) IBOutlet TimePickerView *timePickerView;
@property (nonatomic,assign) BOOL enableScheduleRecord;

@end

@implementation ScheduleRecordViewController

#pragma mark - public api
- (void)fetch
{}

- (void)push
{}

- (NSString *)description
{
    return NSLocalizedString(@"Schedule Record", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

- (FOS_SCHEDULERECORDCONFIG)scheduleRecordConfigFromUI
{
    FOS_SCHEDULERECORDCONFIG result;
    
    result.isEnable = self.enableScheduleRecord;
    [self.timePickerView getSchedule:result.schedules lenght:7];
    
    return result;
}

#pragma mark - update ui
- (void)updateScheduleRecordCfgUI
{
    FOS_SCHEDULERECORDCONFIG cfg = self.scheduleRecordConfig;
    
    [self setEnableScheduleRecord:cfg.isEnable];
    [self.timePickerView setSchedule:cfg.schedules];
}

#pragma mark - setter & getter
- (void)setScheduleRecordConfig:(FOS_SCHEDULERECORDCONFIG)scheduleRecordConfig
{
    _scheduleRecordConfig = scheduleRecordConfig;
    [self updateScheduleRecordCfgUI];
}
@end
