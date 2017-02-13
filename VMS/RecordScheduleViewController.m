//
//  RecordScheduleViewController.m
//  VMS
//
//  Created by mac_dev on 2016/10/24.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "RecordScheduleViewController.h"

@interface RecordScheduleViewController ()

@property (weak,nonatomic) IBOutlet NSTableView *recordTV;
@property (weak,nonatomic) IBOutlet TimePickerView *recordTPV;
@property (strong,nonatomic) NSArray *channels;

@end

@implementation RecordScheduleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self.recordTV selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:YES];
    // Do view setup here.
}

- (NSString *)panelTitle
{
    return  NSLocalizedString(@"Recording Schedule", nil);
}

#pragma mark - load
- (void)load
{
    [self.recordTV deselectAll:nil];
    [self.recordTV selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:YES];
}

#pragma mark - action
- (IBAction)saveScheduled:(id)sender
{
    NSInteger   selectedRow = self.recordTV.selectedRow;
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    NSString    *entity = @"t_rec_plan";;
    long long   schedule[7] = {0};
    
    [self.recordTPV getSchedule:schedule lenght:7];
    
    if (selectedRow >= 0) {
        //update scheduled tasks
        Channel *ch = self.channels[selectedRow];
        for (int weekday = 0; weekday < 7; weekday++) {
            [db updateScheduledData:schedule[weekday]
                              chnId:ch.uniqueId
                            weekday:weekday
                         withEntity:entity];
        }
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        
        alert.messageText = NSLocalizedString(@"Saving the schedule failed", nil);
        alert.informativeText = NSLocalizedString(@"Unchecked", nil);
        
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert runModal];
    }
    [self postNotification];
}

- (IBAction)copyToAllMonitoringPoint :(id)sender
{
    NSString    *entity = @"t_rec_plan";
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    long long schedule[7] = {0};

    [self.recordTPV getSchedule:schedule lenght:7];
    
    for (int weekday = 0; weekday < 7; weekday++) {
        for (Channel *chn in self.channels) {
            //更新
            [db updateScheduledData:schedule[weekday]
                              chnId:chn.uniqueId
                            weekday:weekday
                         withEntity:entity];
        }
    }
    [self postNotification];
}


- (void)postNotification
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:[NSNumber numberWithUnsignedInteger:VMS_SHEDULE_RECORD_UPDATE] forKey:NOTIFI_KEY_DB_OP];
    [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_CHANGED_NOTIFICATION
                                                        object:nil
                                                      userInfo:userInfo];
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
        [self setScheduleTasks:[db fetchScheduledTasksWithChannel:chn entity:@"t_rec_plan"]
             forTimePickerView:self.recordTPV];
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

- (void)setRecordTPV:(TimePickerView *)recordTPV
{
    _recordTPV = recordTPV;
    _recordTPV.style = StartWithSunday;
}

@end
