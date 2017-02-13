//
//  DeviceStateViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

@interface DeviceStateViewController : SettingViewController

@property (assign,nonatomic) FOS_DEVSTATE deviceState;
- (void)fetch;
- (void)push;
- (NSString *)description;
@end
