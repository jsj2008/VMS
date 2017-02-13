//
//  SystemTimeViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

@interface SystemTimeViewController : SettingViewController

@property (strong,nonatomic) NSTimer *timeUpdate;
@property (assign,nonatomic) FOS_DEVSYSTEMTIME deviceSystemTime;
@property (nonatomic,weak) IBOutlet NSButton *syncIPCTimeBtn;

- (void)fetch;
- (void)push;
- (NSString *)description;
- (BOOL)gmt;
- (FOS_DEVSYSTEMTIME)devSysTimeFromUI;

@end
