//
//  DeviceConnectionSettingSheetController.h
//  VMS
//
//  Created by mac_dev on 15/12/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CDevice.h"
#import "DispatchCenter.h"


typedef NS_ENUM(NSUInteger, DCSSC_ERR) {
    DCSSC_NO_ERROR,
    DCSSC_EMPTY_DEVICE_NAME,
    DCSSC_EMPTY_USER_NAME,
};

@interface DeviceConnectionSettingSheetController : NSWindowController

@property (nonatomic,strong,readonly) CDevice *device;

- (instancetype)initWithWindowNibName :(NSString *)windowNibName
                               device :(CDevice *)device;

- (NSString *)errMessage :(DCSSC_ERR)err;
@end
