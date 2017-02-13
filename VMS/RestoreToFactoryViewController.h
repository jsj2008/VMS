//
//  RestoreToFactoryViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

@interface RestoreToFactoryViewController : SettingViewController

- (void)fetch;
- (void)push;
- (NSString *)description;
- (void)performReset;
- (void)onRestore;

@end
