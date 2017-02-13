//
//  AddPollingGroupSheetController.m
//  VMS
//
//  Created by mac_dev on 15/9/3.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//


#import "AddPollingGroupSheetController.h"

#define ID_CHANNEL_LIST @"channel list"
#define ID_POLL_LIST    @"poll list"
#define ID_INDEX        @"index"
#define ID_NAME         @"name"
#define ID_WAIT_SEC     @"wait sec"
#define KEY_CHANNEL     @"channel"
#define KEY_WAITSEC     @"wait sec"

@interface AddPollingGroupSheetController ()
@property (nonatomic,weak) IBOutlet NSTableView *channelList;
@property (nonatomic,weak) IBOutlet NSTableView *pollList;
@property (nonatomic,weak) IBOutlet NSTextField *groupName;
@property (nonatomic,strong) NSMutableArray *channels;
@property (nonatomic,strong) NSMutableArray *pollingTableContents;
@end

@implementation AddPollingGroupSheetController
@synthesize group = _group;
#pragma mark - life cycle
- (void)windowDidLoad {
    [super windowDidLoad];
}

#pragma mark - action
- (IBAction)done :(id)sender
{
    [self.window endEditingFor:self.window.contentView];
    
    APGSC_ERR err = APGSC_ERR_NONE;
    NSString *groupName;
    
    do {
        //检查轮巡组名称是否为空
        groupName = [self.groupName stringValue];
        if (!groupName || [groupName isEqualToString:@""]) {
            err = APGSC_ERR_INVALID_GROUP_NAME;
            break;
        }
        
        err = [self isPollingTableContentsValid:self.pollingTableContents];
    } while (0);
    
    
    if (err == APGSC_ERR_NONE) {
        [self.group setName :groupName];
        
        if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
            [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseOK];
        else
            [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
    }
    else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Failed", nil)];
        [alert setInformativeText:[self errMsg:err]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert runModal];
    }
}

- (IBAction)cancel :(id)sender
{
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseCancel];
    else
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)moveIn :(id)sender
{
    //默认5s等待时间
    NSInteger row = [self.channelList selectedRow];
    Channel *channel = self.channels[row];
    [self pickPollsWithChannelId :channel.uniqueId
                         waitSec :20];
}

- (IBAction)moveOut:(id)sender
{
    NSInteger row = [self.pollList selectedRow];
    NSDictionary *dict = [self.pollingTableContents objectAtIndex:row];
    
    Channel *channel = [dict valueForKey:KEY_CHANNEL];
    
    //添加入通道列表
    [self.channels addObject:channel];
    
    //从轮巡列表中移除
    [self.pollingTableContents removeObject:dict];
    
    //重载
    [self.channelList reloadData];
    [self.pollList reloadData];
}

#pragma mark - private
- (NSString *)errMsg :(APGSC_ERR)code
{
    switch (code) {
        case APGSC_ERR_NONE:
            return NSLocalizedString(@"success", nil);
        case APGSC_ERR_INVALID_GROUP_NAME:
            return NSLocalizedString(@"the group name is empty", nil);
        case APGSC_ERR_EMPTY_GROUP:
            return NSLocalizedString(@"there is no channel in the patrol group", nil);
        case APGSC_ERR_INVALID_WAITTIME:
            return NSLocalizedString(@"waiting time out of range", nil);
        default:
            break;
    }
    
    return NSLocalizedString(@"unknow error", nil);
}

- (APGSC_ERR)isPollingTableContentsValid :(NSArray *)contents
{
    if (contents.count == 0)
        return APGSC_ERR_EMPTY_GROUP;
    
    for (NSDictionary *dict in contents) {
        int waitSecs = [[dict valueForKey:KEY_WAITSEC] intValue];
        
        if (waitSecs < 5 || waitSecs >3600)
            return APGSC_ERR_INVALID_WAITTIME;
    }
    
    return APGSC_ERR_NONE;
}

- (void)pickPollsWithChannelId :(int)channelId
                       waitSec :(int)waitSec
{
    for (Channel *channel in self.channels) {
        if (channel.uniqueId == channelId) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setValue:channel forKey:KEY_CHANNEL];
            [dict setValue:[NSNumber numberWithInt:waitSec] forKey:KEY_WAITSEC];
            
            //从通道列表中移除
            [self.channels removeObject:channel];
            
            //添加入轮巡列表
            [self.pollingTableContents addObject:dict];
            
            //重载
            [self.channelList reloadData];
            [self.pollList reloadData];
            
            break;
        }
    }
}

#pragma mark - tableview datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSString *identifier = tableView.identifier;
    NSInteger number = 0;
    
    if ([identifier isEqualToString:ID_CHANNEL_LIST])
        number = [self.channels count];
    else if ([identifier isEqualToString:ID_POLL_LIST])
        number = [self.pollingTableContents count];
    
    
    return number;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = tableView.identifier;
    id result;
    
    if ([identifier isEqualToString:ID_CHANNEL_LIST]) {
        NSString *column = tableColumn.identifier;
        if ([column isEqualToString:ID_INDEX]) {
            result = [NSNumber numberWithInteger :row];
        } else if ([column isEqualToString:ID_NAME]) {
            result = [self.channels[row] name];
        }
    } else if ([identifier isEqualToString:ID_POLL_LIST]) {
        NSString *column = tableColumn.identifier;
        NSMutableDictionary *dict = [self.pollingTableContents objectAtIndex :row];
        if ([column isEqualToString:ID_INDEX]) {
            result = [NSNumber numberWithInteger :row];
        } else if ([column isEqualToString:ID_NAME]) {
            Channel *channel = [dict valueForKey:KEY_CHANNEL];
            result = channel.name;
        } else if ([column isEqualToString:ID_WAIT_SEC]) {
            result = [dict valueForKey:KEY_WAITSEC];
        }
    }
    
    return result;
}

#pragma mark - tableview delegate
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [[tableColumn identifier] isEqualToString :ID_WAIT_SEC]? YES : NO;
}

- (void)tableView:(NSTableView *)tableView
   setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row
{
    NSString *tIdentifier = tableView.identifier;
    NSString *cIdentifier = tableColumn.identifier;
    NSMutableDictionary *dict = [self.pollingTableContents objectAtIndex :row];
    
    if ([tIdentifier isEqualToString:ID_POLL_LIST] &&
        [cIdentifier isEqualToString:ID_WAIT_SEC]) {
        NSNumber *waitTime = object;
        [dict setValue:waitTime forKey:KEY_WAITSEC];
    }
    [self.pollList reloadData];
}
#pragma mark - setter && getter
- (NSMutableArray *)channels
{
    if (!_channels) {
        _channels = [[NSMutableArray alloc] init];
        //重数据库中取回通道信息
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        //首先取回所有设备
        NSArray *devices = [db fetchDevices];
        //取回设备下所有的通道
        for (CDevice *device in devices) {
            NSArray *channels = [db fetchChannelsWithDevice:device];
            for (Channel *channel in channels)
                [_channels addObject:channel];
        }
    }
    
    return _channels;
}

- (NSArray *)polls
{
    if (!_polls) {
        NSMutableArray *polls = [[NSMutableArray alloc] init];
        NSArray *contents = self.pollingTableContents;
        for (int i = 0; i < contents.count; i++) {
            NSDictionary *dict = [contents objectAtIndex :i];
            Channel *channel = [dict valueForKey :KEY_CHANNEL];
            NSNumber *waitSec = [dict valueForKey:KEY_WAITSEC];
            Poll *poll = [[Poll alloc] initWithUniqueId :-1
                                                  group :nil
                                              channelId :channel.uniqueId
                                                waitSec :[waitSec intValue]
                                            sequenceNum :i];
            [polls addObject :poll];
        }
        _polls = polls;
    }
    
    return _polls;
}

- (void)setGroup:(Group *)group
{
    NSArray *polls = [group children];
    for (Poll *poll in polls)
        [self pickPollsWithChannelId :poll.channelId waitSec :poll.waitSec];
    _group = group;
}

- (NSMutableArray *)pollingTableContents
{
    if (!_pollingTableContents) {
        _pollingTableContents = [[NSMutableArray alloc] init];
    }
    
    return _pollingTableContents;
}

- (void)setGroupName:(NSTextField *)groupName
{
    _groupName = groupName;
    [_groupName setStringValue:self.group.name];
}
@end
