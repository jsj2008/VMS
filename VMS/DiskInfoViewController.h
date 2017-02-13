//
//  DiskInfoViewController.h
//  
//
//  Created by mac_dev on 16/6/7.
//
//

#import "SettingViewController.h"

@interface DiskInfoViewController : SettingViewController<NSTableViewDataSource,NSTableViewDelegate>

@property(nonatomic,assign) FOS_NVR_DISK_INFO diskInfo;

- (void)fetch;
- (void)push;
- (NSString *)description;
- (SVC_OPTION)option;
- (FOS_NVR_DISK_CONFIG)diskConfigFromUI;

@end
