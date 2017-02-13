//
//  GeneralViewController.h
//  VMS
//
//  Created by mac_dev on 2016/10/24.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "JFPreferenceViewController.h"
#import "VMSBasicSetting.h"
#import "VMSPathManager.h"

#define BASIC_SETTING_DID_CHANGE_NOTIFICATION   @"basic setting did change notification"


@interface GeneralViewController : JFPreferenceViewController

@property(nonatomic,strong) VMSBasicSetting *basicSetting;
@end
