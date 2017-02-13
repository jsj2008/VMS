//
//  DDNSViewController.h
//  
//
//  Created by mac_dev on 16/5/27.
//
//

#import "SettingViewController.h"

@interface DDNSViewController : SettingViewController

@property (assign,nonatomic) FOS_DDNSCONFIG ddnsConfig;

- (void)fetch;
- (void)push;
- (NSString *)description;
- (SVC_OPTION)option;
- (FOS_DDNSCONFIG)ddnsConfigFromUI;
- (BOOL)urlNeedEncode;
- (BOOL)hideRestoreToFactory;

@end
