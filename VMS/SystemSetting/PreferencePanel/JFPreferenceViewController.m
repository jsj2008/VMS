//
//  JFPreferenceViewController.m
//  JFPreferencePanel
//
//  Created by mac_dev on 2016/10/22.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "JFPreferenceViewController.h"

@interface JFPreferenceViewController ()

@end

@implementation JFPreferenceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)load
{
    //overwrite by subclass
}

- (void)goBack
{
    if ([self.delegate respondsToSelector:@selector(preferencePanel:willBackToPanel:)]) {
        [self.delegate preferencePanel:self willBackToPanel:self.backController];
    }
}
@end
