//
//  LEDViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

@interface LEDViewController : SettingViewController

@property (assign,nonatomic) FOS_SCHEDULEINFRALEDCONFIG scheduleInfraLedConfig;

- (void)fetch;
- (void)push;
- (NSString *)description;

@end
