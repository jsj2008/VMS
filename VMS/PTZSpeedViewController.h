//
//  PTZSpeedViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

@interface PTZSpeedViewController : SettingViewController

@property(nonatomic,assign) int speed;

- (void)fetch;
- (void)push;
- (int)ptzSpeedFromUI;
- (NSString *)description;

@end
