//
//  UserPanelController.h
//  VMS
//
//  Created by mac_dev on 15/10/22.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VMSUser.h"
#import "VMSDatabase.h"

@interface UserPanelController : NSWindowController<NSComboBoxDataSource,NSComboBoxDelegate>

@property (nonatomic,strong) VMSUser *user;

@end
