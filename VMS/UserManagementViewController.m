//
//  UserManagementViewController.m
//  VMS
//
//  Created by mac_dev on 15/10/21.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "UserManagementViewController.h"

#define KEY_USER            @"user"
#define KEY_USER_GROUP      @"user_group"
#define COL_NUM             @"number"
#define COL_USER_NAME       @"user_name"
#define COL_USER_GROUP      @"user_group"
#define COL_REMARK          @"remark"

@interface UserManagementViewController ()
@property (nonatomic,weak) IBOutlet NSTableView *tableView;
@property (nonatomic,strong) NSMutableArray *tableViewContents;
@property (nonatomic,strong) UserPanelController *userPanelController;
@end

@implementation UserManagementViewController

- (NSString *)panelTitle
{
    return NSLocalizedString(@"Users and Groups", nil);
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)dealloc
{
    [self.tableView setDataSource:nil];
    [self.tableView setDelegate:nil];
}

#pragma mark - action
- (void)alert :(NSString *)msg
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert setMessageText:msg];
    [alert setInformativeText:@""];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}
- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
    
    UserPanelController *controller = (__bridge UserPanelController *)contextInfo;
    VMSUser *user = controller.user;
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    switch (returnCode) {
        case NSModalResponseOK: {
            if (user.uniqueId < 0) {
                //Insert
                
                if ([db insertUser:user] < 0) {
                    [self alert:NSLocalizedString(@"Add user failed", nil)];
                    return;
                }
            } else {
                //Update
                if ([db updateUser:user]) {
                    [self alert:NSLocalizedString(@"Update user failed", nil)];
                    return;
                }
            }
            //Update tableview contents
            [self setTableViewContents:nil];
            [self.tableView reloadData];
        }
            break;
        case NSModalResponseCancel:
            break;
        default:
            break;
    }
    [self.userPanelController close];
    self.userPanelController = nil;
}

- (IBAction)tableViewBottombarAction :(id)sender
{
    NSInteger clickedSegment = [sender selectedSegment];
    NSInteger clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
    //数据库
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    //获取选中的用户
    NSInteger selectedRow = [self.tableView selectedRow];
    VMSUser *selectedUser = nil;
    if (selectedRow >= 0) {
        NSDictionary *entity = [self.tableViewContents objectAtIndex:selectedRow];
        selectedUser = [entity valueForKey:KEY_USER];
    }
    
    switch (clickedSegmentTag) {
        case 0: {
            //Add
            if (!self.userPanelController) {
                self.userPanelController = [[UserPanelController alloc] initWithWindowNibName:@"UserPanelController"];
                
                if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9) {
                    [[NSApplication sharedApplication] beginSheet:self.userPanelController.window
                                                   modalForWindow:self.view.window
                                                    modalDelegate:self
                                                   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                                                      contextInfo:(void *)self.userPanelController];
                }
                else {
                    [self.view.window beginSheet:self.userPanelController.window
                               completionHandler:^(NSModalResponse returnCode) {
                                   [self didEndSheet:self.userPanelController.window
                                          returnCode:returnCode
                                         contextInfo:(void *)self.userPanelController];
                               }];
                }
            }
        }
            break;
        case 1: {
            //Remove
            if (selectedUser) {
                //审查选中的用户是否是根用户
                NSString *selectedUserName = [selectedUser userName];
                if ([selectedUserName isEqualToString:ROOT]) {
                    [self alert:NSLocalizedString(@"The root user can not be deleted", nil)];
                    return;
                }
                //询问是否删除
                NSAlert *alert = [[NSAlert alloc] init];
                
                alert.messageText = NSLocalizedString(@"Are you sure you want to delete this user?", nil);
                alert.informativeText = @"";
                alert.alertStyle = NSAlertStyleWarning;
                
                [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                
                if (NSAlertSecondButtonReturn == [alert runModal]) {
                    [db deleteUser:selectedUser];
                    [self setTableViewContents:nil];
                    [self.tableView reloadData];
                }
            }
        }
            break;
        case 2: {
            //Modify
            if (selectedUser) {
                //当前用户
                VMSUser *currentUser = [(AppDelegate *)[[NSApplication sharedApplication] delegate] currentUser];
                NSString *currentUserName = currentUser.userName;
                //审查是否有权限更改
                NSString *selectedUserName = [selectedUser userName];
                if ([selectedUserName isEqualToString:ROOT] && ![currentUserName isEqualToString:ROOT]) {
                    [self alert:NSLocalizedString(@"The root user can not be modified",nil)];
                    return;
                }
                
                if (!self.userPanelController) {
                    self.userPanelController = [[UserPanelController alloc] initWithWindowNibName:@"UserPanelController"];
                    self.userPanelController.user = selectedUser;
                    
                    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9) {
                        [[NSApplication sharedApplication] beginSheet:self.userPanelController.window
                                                       modalForWindow:self.view.window
                                                        modalDelegate:self
                                                       didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                                                          contextInfo:(void *)self.userPanelController];
                    }
                    else {
                        [self.view.window beginSheet:self.userPanelController.window
                                   completionHandler:^(NSModalResponse returnCode) {
                                       [self didEndSheet:self.userPanelController.window
                                              returnCode:returnCode
                                             contextInfo:(void *)self.userPanelController];
                                   }];
                    }
                }
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - tableview datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.tableViewContents.count;
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row;
{
    id obj = nil;
    NSString *identifier = [tableColumn identifier];
    NSDictionary *entity = [self.tableViewContents objectAtIndex:row];
    VMSUser *user = [entity valueForKey:KEY_USER];
    UserGroup *group = [entity valueForKey:KEY_USER_GROUP];
    
    if ([identifier isEqualToString:COL_NUM])
        obj = [NSNumber numberWithInteger:row];
    else if ([identifier isEqualToString:COL_USER_NAME])
        obj = user.userName;
    else if ([identifier isEqualToString:COL_USER_GROUP])
        obj = NSLocalizedString(group.groupName,nil);
    else
        obj = user.remark;
    
    
    return obj;
}
#pragma mark - tableview delegate
- (BOOL)tableView:(NSTableView *)tableView
shouldEditTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row
{
    return NO;
}

#pragma mark - setter & getter
- (NSMutableArray *)tableViewContents
{
    if (!_tableViewContents) {
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        _tableViewContents = [[NSMutableArray alloc] init];
        //取回用户
        NSArray *vmsUsers = [db fetchUsers];
        for (VMSUser *user in vmsUsers) {
            UserGroup *group = [db fetchUserGroupWithUniqueId:user.groupId];
            NSDictionary *entity = [[NSDictionary alloc] initWithObjectsAndKeys:user,KEY_USER,group,KEY_USER_GROUP, nil];
            [_tableViewContents addObject:entity];
        }
    }
    
    return _tableViewContents;
}

@end
