//
//  DeviceRebootViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

@interface DeviceRebootViewController : SettingViewController

- (void)fetch;
- (void)push;
- (NSString *)description;
- (void)performReboot;
- (void)onReboot;
@end
