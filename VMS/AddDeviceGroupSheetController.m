//
//  AddDeviceGroupSheetController.m
//  VMS
//
//  Created by mac_dev on 15/12/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "AddDeviceGroupSheetController.h"

#define ID_GROUP_IN     @"group_in"
#define ID_GROUP_OUT    @"group_out"
#define ID_INDEX        @"index"
#define ID_NAME         @"name"

@interface AddDeviceGroupSheetController ()

@property (weak,nonatomic) IBOutlet NSTextField *groupNameTF;
@property (weak,nonatomic) IBOutlet NSTableView *groupInTableView;
@property (weak,nonatomic) IBOutlet NSTableView *groupOutTableView;




@property (nonatomic,strong) NSAlert *alert;
@end

@implementation AddDeviceGroupSheetController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self updateUI];
}

- (void)updateUI
{
    //将group中的设备从组外移入组内
    NSArray *devices = self.group.children;
    
    for (CDevice *device in devices) {
        //在组外设备中进行查找
//        __block CDevice *deviceFinded;
//        [self.groupOutDevices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
//        {
//            if (device.uniqueId == [(CDevice *)obj uniqueId]) {
//                deviceFinded = obj;
//                *stop = YES;
//            }
//        }];
        
        [self moveInDevice:device];
    }
    //更新组名
    self.groupNameTF.stringValue = (self.group.uniqueId == -1)? @"New Group" : self.group.name;
}

- (ADGSC_ERR)checkParam
{
    ADGSC_ERR err = ADGSC_NO_ERR;
    
    do {
        if ([self.groupNameTF.stringValue isEqualToString:@""]) {
            err = ADGSC_EMPTY_NAME;
            break;
        }
    }while (0);
    
    return err;
}
#pragma mark - error
- (NSString *)errMessage :(ADGSC_ERR)err
{
    NSString *msg = NSLocalizedString(@"unknow error", nil);
    
    switch (err) {
        case ADGSC_NO_ERR:
            msg = NSLocalizedString(@"no error", nil);
            break;
            
        case ADGSC_EMPTY_NAME:
            msg = NSLocalizedString(@"the group name is empty", nil);
            break;
            
        default:
            break;
    }
    
    return msg;
}
#pragma mark - move
- (void)moveInDevice :(CDevice *)device
{
    if (device) {
        //从组外移除
        [self.groupOutDevices removeObject:device];
        [self.groupOutTableView reloadData];
        
        //加入到组内
        [self.groupInDevices addObject:device];
        [self.groupInTableView reloadData];
    }
}

- (void)moveOutDevice :(CDevice *)device
{
    if (device) {
        //从组内移除
        [self.groupInDevices removeObject:device];
        [self.groupInTableView reloadData];
        //加入到组外
        [self.groupOutDevices addObject:device];
        [self.groupOutTableView reloadData];
    }
}


#pragma mark - interaction
- (IBAction)moveIn :(id)sender
{
    //获取组外选中设备
    NSInteger selectedRow = self.groupOutTableView.selectedRow;
    
    if (selectedRow < self.groupOutDevices.count) {
        CDevice *device = self.groupOutDevices[selectedRow];
        
        [self moveInDevice:device];
    }
}

- (IBAction)moveOut :(id)sender
{
    //从组内获取选中设备
    NSInteger selectedRow = self.groupInTableView.selectedRow;
    
    if (selectedRow < self.groupInDevices.count) {
        CDevice *device = self.groupInDevices[selectedRow];
        
        [self moveOutDevice:device];
    }
}


- (IBAction)done:(id)sender
{
    ADGSC_ERR err = [self checkParam];
    
    if (err != ADGSC_NO_ERR) {
        [self.alert setMessageText:[self errMessage:err]];
        [self.alert beginSheetModalForWindow:self.window
                           completionHandler:NULL];
        return;
    }
    
    //更新group
    self.group.name = self.groupNameTF.stringValue;

    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseOK];
    else
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)cancel :(id)sender
{
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseCancel];
    else
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}
#pragma mark - table view datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSString *identifier = tableView.identifier;
    NSInteger number = 0;
    
    if ([identifier isEqualToString:ID_GROUP_IN])
        number = [self.groupInDevices count];
    else if ([identifier isEqualToString:ID_GROUP_OUT])
        number = [self.groupOutDevices count];
    
    return number;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = tableView.identifier;
    id result;
    
    if ([identifier isEqualToString:ID_GROUP_IN]) {
        NSString *column = tableColumn.identifier;
        if ([column isEqualToString:ID_INDEX]) {
            result = [NSNumber numberWithInteger :row];
        } else if ([column isEqualToString:ID_NAME]) {
            result = [self.groupInDevices[row] name];
        }
    } else if ([identifier isEqualToString:ID_GROUP_OUT]) {
        NSString *column = tableColumn.identifier;
        if ([column isEqualToString:ID_INDEX]) {
            result = [NSNumber numberWithInteger :row];
        } else if ([column isEqualToString:ID_NAME]) {
            result = [self.groupOutDevices[row] name];
        }
    }
    
    return result;
}
#pragma mark - table view delegate
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

#pragma mark - setter && getter
- (NSMutableArray *)groupInDevices
{
    if (!_groupInDevices) {
        _groupInDevices = [[NSMutableArray alloc] init];
    }
    
    return _groupInDevices;
}

- (NSMutableArray *)groupOutDevices
{
    if (!_groupOutDevices) {
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        _groupOutDevices = [[db fetchDevicesWithGroup:nil] mutableCopy];
        //_groupOutDevices = [[db fetchDevices] mutableCopy];
    }
    
    return _groupOutDevices;
}

- (NSAlert *)alert
{
    if (!_alert) {
        _alert = [[NSAlert alloc] init];
    }
    
    return _alert;
}
@end
