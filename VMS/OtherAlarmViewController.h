//
//  OtherAlarmViewController.h
//  
//
//  Created by mac_dev on 16/6/1.
//
//

#import "SettingViewController.h"

@interface OtherAlarmViewController : SettingViewController

@property(nonatomic,assign) FOS_NVR_OTHER_ALARM_CONFIG otherAlarmConfig;
@property(nonatomic,assign) int alarmType;

- (void)fetch;
- (void)push;
- (NSString *)description;
- (SVC_OPTION)option;
- (FOS_NVR_OTHER_ALARM_CONFIG)alarmConfigFromUI;

@end
