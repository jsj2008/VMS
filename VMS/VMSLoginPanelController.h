//
//  VMSLoginPanelController.h
//  VMS
//
//  Created by mac_dev on 15/10/21.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VMSDatabase.h"
#import "INAppStoreWindow/INAppStoreWindow.h"
#import "NSTextFieldCell+CenterVertical.h"
#import "NSButton+BTSButton.h"
#import "NSWindow+Effects.h"
#import "BasicSetting.h"
#import "VMSBasicSetting.h"

typedef NS_ENUM(NSUInteger, VMS_OP) {
    VMS_LOGIN,
    VMS_LOGOFF,
    VMS_TOGGLE_USER,
    VMS_UNLOCK,
};

@interface VMSLoginPanelController : NSWindowController

- (instancetype)initWithWindowNibName :(NSString *)windowNibName
                          vmsOperator :(VMS_OP)op;

@property (assign,readonly) VMS_OP op;
//输出
@property (nonatomic,strong) VMSBasicSetting *basicSetting;
//@property (strong) VMSUser *vmsUser;
@end
