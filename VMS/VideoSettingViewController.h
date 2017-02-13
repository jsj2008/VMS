//
//  VideoSettingViewController.h
//  VMS
//
//  Created by mac_dev on 15/8/28.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"

@interface VideoSettingViewController : SettingViewController<NSComboBoxDataSource>

- (void)refetch:(NSInteger)tag;

@property (assign,nonatomic) int nightLightState;
@property (assign,nonatomic) FOS_VIDEOSTREAMLISTPARAM videoStreamListParam;
@property (assign,nonatomic) FOS_VIDEOSTREAMLISTPARAM videoSubStreamListParam;
@property (assign,nonatomic) FOS_OSDSETTING osdSetting;
@property (assign,nonatomic) int osdMaskEnable;
@property (assign,nonatomic) FOS_OSDMASKAREA osdMaskArea;
@property (assign,nonatomic) FOS_SNAPCONFIG snapConfig;
@property (assign,nonatomic) FOS_SCHEDULESNAPCONFIG scheduleSnapConfig;
@property (assign,nonatomic) FOS_SCHEDULEINFRALEDCONFIG scheduleInfraLedConfig;

@end
