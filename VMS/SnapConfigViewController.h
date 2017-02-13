//
//  SnapConfigViewController.h
//  VMS
//
//  Created by mac_dev on 16/8/30.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"
#import "TimePickerView.h"


@interface SnapConfigViewController : SettingViewController

@property(nonatomic,assign) FOS_SNAPCONFIG snapConfig;
@property(nonatomic,assign) FOS_SCHEDULESNAPCONFIG scheduleSnapConfig;

- (void)fetch;
- (void)push;
- (NSString *)description;
- (SVC_OPTION)option;

@end
