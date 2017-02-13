//
//  UserManagementViewController.h
//  VMS
//
//  Created by mac_dev on 15/10/21.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JFPreferenceViewController.h"
#import "VMSDatabase.h"
#import "UserPanelController.h"
#import "AppDelegate.h"

@interface UserManagementViewController : JFPreferenceViewController<NSTableViewDataSource,NSTableViewDelegate,NSComboBoxDataSource>

@end
