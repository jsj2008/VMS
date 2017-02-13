//
//  PTZSettingViewController.h
//  VMS
//
//  Created by mac_dev on 15/12/22.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"
#import "DispatchCenter.h"

#define FOS_DEFAULT_CURISEMAP_COUNT 2
#define FOS_DEFAULT_PRESETPOINT_COUNT 4
#define VMS_MAX_CURISEMAP_COUNT     FOS_MAX_CURISEMAP_COUNT - FOS_DEFAULT_CURISEMAP_COUNT
#define VMS_MAX_PRESETPOINT_COUNT   FOS_MAX_PRESETPOINT_COUNT - FOS_DEFAULT_PRESETPOINT_COUNT


@interface PTZSettingViewController : SettingViewController<NSComboBoxDataSource,NSTableViewDataSource,NSTableViewDelegate>

@property(nonatomic,assign) int speed;
@property(nonatomic,assign) FOS_CRUISECTRLMODE cruiseCtrlMode;
@property(nonatomic,assign) unsigned int cruiseTime;
@property(nonatomic,assign) FOS_CRUISETIMECUSTOMED cruiseTimeCustomed;
@property(nonatomic,assign) int cruiseLoopCnt;

@property(nonatomic,assign) FOS_RESETPOINTLIST presetPointList;
@property(nonatomic,assign) FOS_CRUISEMAPPREPOINTLINGERTIME cruiseMapPrepointLingerTime;
@property(nonatomic,assign) FOS_CRUISEMAPLIST cruiseMapList;
@property(nonatomic,assign) FOS_CRUISEMAPINFO cruiseMapInfo;

@property(nonatomic,assign) int selfTestMode;
@property(nonatomic,assign) NSString *selfTestPresetName;
@end
