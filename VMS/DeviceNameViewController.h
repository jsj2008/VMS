//
//  DeviceNameViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

@interface DeviceNameViewController : SettingViewController

@property (copy,nonatomic) NSString *devName;

- (void)fetch;
- (void)push;
- (NSString *)description;

@end
