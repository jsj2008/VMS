//
//  PTZStartupOptionViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

@interface PTZStartupOptionViewController : SettingViewController

@property(nonatomic,assign) int selfTestMode;
@property(nonatomic,assign) NSString *selfTestPresetName;
@property(nonatomic,assign) FOS_RESETPOINTLIST presetPointList;


- (void)fetch;
- (void)push;
- (NSString *)description;

@end
