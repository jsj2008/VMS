//
//  LedConfigViewController.h
//  VMS
//
//  Created by mac_dev on 16/8/25.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"

@interface LedConfigViewController : SettingViewController

@property(nonatomic,assign) FOSIRCUTSTATE ircutState;


- (void)fetch;
- (NSString *)description;

@end
