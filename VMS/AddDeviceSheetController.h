//
//  AddDeviceSheetController.h
//  VMS
//
//  Created by mac_dev on 15/7/9.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DispatchCenter.h"
#import "CheckboxHeaderCell.h"
#import "VMSDatabase.h"

typedef NS_ENUM(NSUInteger, ADSC_ERR) {
    ADSC_NO_ERR,
    ADSC_EMPTY_NAME,
    ADSC_EMPTY_IP,
    ADSC_EMPTY_PORT,
    ADSC_EMPTY_MAC_ADDR,
    ADSC_EMPTY_USER_NAME,
    ADSC_EMPTU_PASSWORD,
    ADSC_EMPTY_UID,
    ADSC_ADD_DEVICE_FAIL,
    ADSC_LOGIN_FAILED,
    ADSC_MODIFY_LOGIN_INFO_FAILED,
};

@interface AddDeviceSheetController : NSWindowController

@property (nonatomic,strong) CDevice * device;//新增的设备;

+ (BOOL)insertDevice :(CDevice *)device;

@end
