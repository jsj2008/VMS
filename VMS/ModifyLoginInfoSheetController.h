//
//  ModifyLoginInfoSheetController.h
//  VMS
//
//  Created by mac_dev on 2016/10/13.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//FOSSDK FOSCMD_RESULT FOSAPI FosSdk_ChangeUserNameAndPwdTogether(FOSHANDLE handle, int timeOutMS, char *usrName, char *newName, char* oldPwd, char* newPwd);

@interface ModifyLoginInfo : NSObject

@property(nonatomic,copy) NSString *usrName;
@property(nonatomic,copy) NSString *modifiedName;
@property(nonatomic,copy) NSString *pwd;
@property(nonatomic,copy) NSString *modifiedPwd;

@end


@interface ModifyLoginInfoSheetController : NSWindowController

- (instancetype)initWithWindowNibName:(NSString *)windowNibName useDefaultUser :(BOOL)useDefaultUser;

@property(nonatomic,assign) BOOL useDefaultUser;
@property(nonatomic,strong) ModifyLoginInfo *info;

@end
