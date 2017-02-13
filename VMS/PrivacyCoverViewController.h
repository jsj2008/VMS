//
//  PrivacyCoverViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

@interface PrivacyCoverViewController : SettingViewController

@property (assign,nonatomic) int osdMaskEnable;
@property (assign,nonatomic) FOS_OSDMASKAREA osdMaskArea;

- (void)fetch;
- (void)push;
- (NSString *)description;

@end
