//
//  AlarmSettingViewController.m
//  VMS
//
//  Created by mac_dev on 2016/10/24.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "AlarmSettingViewController.h"

@interface AlarmSettingViewController ()

@property (weak,nonatomic) IBOutlet NSTableView *alarmTV;
@property (weak,nonatomic) IBOutlet TimePickerView *alarmTPV;
@property (assign,nonatomic) int alarmType;
@property (assign,nonatomic,getter=isAlarmSnap) BOOL alarmSnap;
@property (assign,nonatomic,getter=isAlarmRecord) BOOL alarmRcord;
@property (assign,nonatomic,getter=isAlarmRing) BOOL alarmRing;
@property (strong,nonatomic) NSArray *channels;

@end

@implementation AlarmSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (NSString *)panelTitle
{
    return NSLocalizedString(@"Alarm Settings", nil);
}

#pragma mark - load
- (void)load
{
    [self.alarmTV deselectAll:nil];
    [self.alarmTV selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:YES];
}

#pragma mark - action
- (IBAction)saveScheduled:(id)sender
{
    NSInteger   selectedRow = self.alarmTV.selectedRow;
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    NSString    *entity = @"t_alarm_plan";
    long long   schedule[7] = {0};
    
    [self.alarmTPV getSchedule:schedule lenght:7];
    
    if (selectedRow >= 0) {
        //Update alarm link.
        VMS_ALARM_LINKAGE linkage = 0;
        if (self.isAlarmRecord) linkage |= VMS_ALARM_IS_RECORD;
        if (self.isAlarmRing) linkage |= VMS_ALARM_IS_RING;
        if (self.isAlarmSnap) linkage |= VMS_ALARM_IS_SNAP;
        
        Channel *chn = self.channels[selectedRow];
        [db updateAlarmLink:linkage
                  alarmType:self.alarmType
              withChannelId:chn.uniqueId];
        
        Channel *ch = self.channels[selectedRow];
        for (int weekday = 0; weekday < 7; weekday++) {
            [db updateScheduledData:schedule[weekday]
                              chnId:ch.uniqueId
                            weekday:weekday
                         withEntity:entity];
        }
    }
    else {
        NSAlert *alert = [[NSAlert alloc] init];
        
        alert.messageText = NSLocalizedString(@"Saving the schedule failed", nil);
        alert.informativeText = NSLocalizedString(@"Unchecked", nil);
        
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert runModal];
    }
}

- (IBAction)copyToAllMonitoringPoint :(id)sender
{
    NSString    *entity = @"t_alarm_plan";
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    long long   schedule[7] = {0};
    VMS_ALARM_LINKAGE linkage = 0;
    
    if (self.isAlarmRecord) linkage |= VMS_ALARM_IS_RECORD;
    if (self.isAlarmRing) linkage |= VMS_ALARM_IS_RING;
    if (self.isAlarmSnap) linkage |= VMS_ALARM_IS_SNAP;
    
    for (Channel *chn in self.channels) {
        [db updateAlarmLink:linkage
                  alarmType:self.alarmType
              withChannelId:chn.uniqueId];
    }
    
    [self.alarmTPV getSchedule:schedule lenght:7];
    
    for (int weekday = 0; weekday < 7; weekday++) {
        for (Channel *chn in self.channels) {
            //更新
            [db updateScheduledData:schedule[weekday]
                              chnId:chn.uniqueId
                            weekday:weekday
                         withEntity:entity];
        }
    }
}

#pragma mark - tableview datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.channels.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    ///cell-based table view
    NSString *identifier = [tableColumn identifier];
    
    if (row < self.channels.count) {
        Channel     *channel = [self.channels objectAtIndex:row];
        NSString    *index = [NSString stringWithFormat:@"%ld",row];
        
        id result = nil;
        if ([identifier isEqualToString:@"number"]) result = index;
        else if ([identifier isEqualToString:@"name"]) result = channel.name;
        
        return result;
    }
    
    return nil;
}

#pragma mark - tableview delegate
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableview = notification.object;
    NSInteger selectedRow = tableview.selectedRow;
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    //获取到选中的通道
    
    if (selectedRow  < self.channels.count) {
        Channel *chn = [self.channels objectAtIndex:selectedRow];
        
        //查询出alarm linkage
        AlarmLink *alarmlink = [db fetchAlarmLinkWithChannelId:chn.uniqueId];
        //更新UI
        [self setAlarmRcord:alarmlink.linkage & VMS_ALARM_IS_RECORD];
        [self setAlarmRing:alarmlink.linkage & VMS_ALARM_IS_RING];
        [self setAlarmSnap:alarmlink.linkage & VMS_ALARM_IS_SNAP];
        [self setAlarmType:alarmlink.alarmType];
        [self setScheduleTasks:[db fetchScheduledTasksWithChannel:chn entity:@"t_alarm_plan"]
             forTimePickerView:self.alarmTPV];
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

#pragma mark - setter & getter
- (NSArray *)channels
{
    if (!_channels) {
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        NSArray *devices = [db fetchDevices];
        
        NSMutableArray *temp = [[NSMutableArray alloc] init];
        for (CDevice *dev in devices) {
            [temp addObjectsFromArray:[db fetchChannelsWithDevice:dev]];
        }
        
        _channels = [NSArray arrayWithArray:temp];
    }
    
    return _channels;
}

- (void)setScheduleTasks :(NSArray *)tasks forTimePickerView :(TimePickerView *)tpv
{
    long long schedule[7] = {0};
    
    if (tasks.count == 7) {
        for (ScheduledTask *task in tasks) {
            schedule[task.weekday] = task.data;
        }
        
        [tpv setSchedule:schedule];
    }
}

- (void)setAlarmTPV:(TimePickerView *)alarmTPV
{
    _alarmTPV = alarmTPV;
    _alarmTPV.style = StartWithSunday;
}
@end
