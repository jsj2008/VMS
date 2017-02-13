//
//  AddPollingGroupSheetController.h
//  VMS
//
//  Created by mac_dev on 15/9/3.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Group.h"
#import "VMSDatabase.h"
#import "Poll.h"

typedef NS_ENUM(NSUInteger, APGSC_ERR) {
    APGSC_ERR_NONE,
    APGSC_ERR_INVALID_GROUP_NAME,
    APGSC_ERR_EMPTY_GROUP,
    APGSC_ERR_INVALID_WAITTIME,
};



@interface AddPollingGroupSheetController : NSWindowController<NSTableViewDataSource,NSTableViewDelegate>
//输入
@property (strong,nonatomic) Group *group;//轮巡组
//输出
@property (strong,nonatomic) NSArray *polls;
@end
