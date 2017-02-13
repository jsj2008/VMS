//
//  RecordSettingViewController.h
//  VMS
//
//  Created by mac_dev on 2016/10/24.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "JFPreferenceViewController.h"
#import "VMSRecordSetting.h"
#import "VMSPathManager.h"

@interface RecordSettingViewController : JFPreferenceViewController

@property(nonatomic,strong) VMSRecordSetting *recordSetting;
@end
