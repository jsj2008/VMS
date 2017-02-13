//
//  AddDeviceGroupSheetController.h
//  VMS
//
//  Created by mac_dev on 15/12/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Group.h"
#import "CDevice.h"
#import "VMSDatabase.h"

typedef NS_ENUM(NSUInteger, ADGSC_ERR) {
    ADGSC_NO_ERR,
    ADGSC_EMPTY_NAME,
};

@interface AddDeviceGroupSheetController : NSWindowController
@property (nonatomic,strong) Group *group;
@property (nonatomic,strong) NSMutableArray *groupInDevices;
@property (nonatomic,strong) NSMutableArray *groupOutDevices;
@end
