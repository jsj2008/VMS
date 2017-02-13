//
//  DeviceManagementController.h
//  VMS
//
//  Created by mac_dev on 15/6/25.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SettingViewController.h"
#import "VMSTabView.h"
#import "VMSDatabase.h"



//支持华为海思平台和安霸平台
typedef NS_ENUM(NSUInteger, PlatformType) {
    NONE_PLATFORM,
    IPC_HS_PLATFORM,
    IPC_AMBA_PLATFORM,
    NVR_PLATFORM,
};

@interface DeviceSettingSheetController : NSWindowController<NSOutlineViewDataSource,
NSOutlineViewDelegate,SVCDelegate,VMSTabViewDelegate>

- (id)initWithWindowNibName:(NSString *)windowNibName
                     device:(CDevice *)device;

@property (nonatomic,weak,readonly) CDevice *device;

@end
