//
//  StateSettingViewController.h
//  VMS
//
//  Created by mac_dev on 15/8/28.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"

@interface StateSettingViewController : SettingViewController<NSTabViewDelegate>

@property (assign,nonatomic) FOS_DEVINFO deviceInfo;
@property (assign,nonatomic) FOS_DEVSTATE deviceState;

- (void)refetch :(NSInteger)tag;
@end
