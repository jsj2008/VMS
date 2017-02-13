//
//  ColorAdjustmentViewController.h
//  VMS
//
//  Created by mac_dev on 16/8/26.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"

@interface ColorAdjustmentViewController : SettingViewController

@property (nonatomic,assign) FOSIMAGE imgParam;
@property (nonatomic,assign) FOSMIRRORFLIP mirrorAndFlipCfg;
@property (nonatomic,assign) FOSPWRFREQ powerFrequency;


- (NSString *)description;
- (SVC_OPTION)option;

@end
