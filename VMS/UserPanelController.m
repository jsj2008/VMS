//
//  UserPanelController.m
//  VMS
//
//  Created by mac_dev on 15/10/22.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "UserPanelController.h"

@interface UserPanelController ()

@property (nonatomic,weak) IBOutlet NSTextField *userName;
@property (nonatomic,weak) IBOutlet NSTextField *password;
@property (nonatomic,weak) IBOutlet NSTextField *remark;
@property (nonatomic,weak) IBOutlet NSPopUpButton *userGroupPopUpBtn;
@property (nonatomic,strong) NSArray *userGroups;

@end

@implementation UserPanelController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self updateUI];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)updateUI
{
    VMSUser *user = self.user;
    NSString *userName = [self secureString:user.userName];

    [self.userName setStringValue:userName];
    [self.password setStringValue:[self secureString:user.password]];
    [self.remark setStringValue:[self secureString:user.remark]];
    
    NSInteger index = [self indexOfUserGroupWithId:user.groupId];
    if (index >= 0) {
        [self.userGroupPopUpBtn selectItemAtIndex:index];
    }
    
    if ([userName isEqualToString:ROOT]) {
        //根用户
        self.userName.enabled = NO;
        self.userGroupPopUpBtn.enabled = NO;
    }
}

#pragma mark - action
- (void)alert :(NSString *)msg
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    alert.messageText = msg;
    alert.informativeText = @"";
    
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}

- (IBAction)done:(id)sender
{
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    //用户名
    NSString *userName = [self.userName stringValue];
    if ([userName isEqualToString:@""]) {
        [self alert:NSLocalizedString(@"the user id is empty", nil)];
        return;
    } else if (!self.user && [db fetchUserWithUserName:userName]) {
        [self alert:NSLocalizedString(@"username exist", nil)];
        return;
    }
    
    //密码
    NSString *password = [self.password stringValue];
    
    //备注
    NSString *remark = self.remark.stringValue;
    
    //组
    NSInteger index = [self.userGroupPopUpBtn indexOfSelectedItem];
    if (index < 0) {
        [self alert:NSLocalizedString(@"Unchecked", nil)];
        return;
    }
    int groupId = [(UserGroup *)[self.userGroups objectAtIndex:index] uniqueId];
    
    //Id
    int userId = self.user? self.user.uniqueId : -1;
    [self setUser:[[VMSUser alloc] initWithUniqueId:userId
                                           userName:userName
                                           password:password
                                             remark:remark
                                            gorupId:groupId]];
    
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseOK];
    else
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)cancel:(id)sender
{
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseCancel];
    else
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}


#pragma mark - priavte
- (NSString *)secureString :(NSString *)str
{
    return !str? @"" : str;
}

- (NSInteger)indexOfUserGroupWithId :(NSInteger)uniqueId
{
    NSInteger count = self.userGroups.count;

    for (int i = 0; i < count; i++) {
        UserGroup *group = self.userGroups[i];
        if (group.uniqueId == uniqueId) {
            return i;
        }
    }
    
    return -1;
}

#pragma mark - setter && getter
- (NSArray *)userGroups
{
    if (!_userGroups) {
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        _userGroups = [db fetchUserGroups];
    }
    
    return _userGroups;
}

- (void)setUserGroupPopUpBtn:(NSPopUpButton *)userGroupPopUpBtn
{
    _userGroupPopUpBtn = userGroupPopUpBtn;
    //移除已有的所有菜单项
    [_userGroupPopUpBtn removeAllItems];
    //向菜单中插入菜单项
    NSArray *userGroups = self.userGroups;
    for (NSUInteger i = 0; i < userGroups.count; i++) {
        UserGroup *group = userGroups[i];
        [_userGroupPopUpBtn addItemWithTitle:NSLocalizedString(group.groupName,nil)];
    }
}


@end
