//
//  BasicSettingViewController.h
//  VMS
//
//  Created by mac_dev on 15/8/28.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"
#import "TFDatePickerPopoverController.h"
#import "XStringFomatter.h"

@interface BasicSettingViewController : SettingViewController<NSComboBoxDataSource,NSComboBoxDelegate,NSTabViewDelegate>

@property (copy,nonatomic) NSString *devName;
@property (assign,nonatomic) FOS_DEVSYSTEMTIME deviceSystemTime;
@property (assign,nonatomic) int ledEnable;

- (void)refetch :(NSInteger)tag;
- (void)push :(NSInteger)tag;
@end
