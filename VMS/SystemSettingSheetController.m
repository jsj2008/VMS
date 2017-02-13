//
//  SystemSettingSheetController.m
//  VMS
//
//  Created by mac_dev on 15/8/24.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "SystemSettingSheetController.h"
#import <ServiceManagement/ServiceManagement.h>

#define ID_RECORDING_SIZE   @"recording size"
#define ID_RECORDING_TIME   @"recording time"
#define ID_POLL_TIME        @"poll time"
#define IS_RECORD_CONFIG_VISIBALE    0

#define TVID_RECORD     @"record table view"
#define TVID_ALARM      @"alarm table view"
#define TPVID_RECORD    @"record time picker view"
#define TPVID_ALARM     @"alarm time picker view"
@interface SystemSettingSheetController ()

@property (weak) IBOutlet NSTextField *capturePathName;//快照存放路径
@property (weak,nonatomic) IBOutlet NSComboBox *pollTime;//轮巡时间
@property (weak,nonatomic) IBOutlet NSTextField *pollTimeTF;
@property (weak) IBOutlet NSMatrix *wndStreamType;//预览视频码流类型
@property (assign) BOOL saveLayout;//保存摆放位置
@property (assign) BOOL autoRun;//自动运行
@property (assign) BOOL autoSearch;//自动查找
@property (assign) BOOL autoLogin;//自动登录

//录像设置
@property (assign) BOOL enableRecording;
@property (assign) BOOL cycleRecord;//循环录像
@property (weak) IBOutlet NSTextField *recordingPathName;
@property (weak) IBOutlet NSTextField *freeSpace;
@property (weak) IBOutlet NSMatrix *recordingRestrict;
@property (weak) IBOutlet NSComboBox *recordingSize;
@property (weak) IBOutlet NSComboBox *recordingTime;

@property (weak) IBOutlet NSTextField *recordingRestrictTF;
@property (weak) IBOutlet NSTextField *recordingSizeTF;
@property (weak) IBOutlet NSTextField *recordingTimeTF;
@property (weak) IBOutlet NSTextField *sizeUnitTF;
@property (weak) IBOutlet NSTextField *timeUnitTF;
@property (strong,nonatomic) NSArray *channels;

//报警设置
@property (weak,nonatomic) IBOutlet NSTableView *alarmTV;
@property (weak,nonatomic) IBOutlet TimePickerView *alarmTPV;
@property (assign,nonatomic) NSInteger alarmType;
@property (assign,nonatomic,getter=isAlarmSnap) BOOL alarmSnap;
@property (assign,nonatomic,getter=isAlarmRecord) BOOL alarmRcord;
@property (assign,nonatomic,getter=isAlarmRing) BOOL alarmRing;

//录像计划
@property (weak,nonatomic) IBOutlet NSTableView *recordTV;
@property (weak,nonatomic) IBOutlet TimePickerView *recordTPV;

@end

@implementation SystemSettingSheetController

- (void)dealloc
{
    self.recordTV.dataSource = nil;
    self.recordTV.delegate = nil;
    self.alarmTV.dataSource = nil;
    self.alarmTV.delegate = nil;
    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self updateBasicSettingUI];
    [self updateRecordingSettingUI];
    [self.recordTV selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:YES];
    [self.alarmTV selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:YES];
}

- (void)updateBasicSettingUI
{
    VMSBasicSetting *basicSetting = self.basic_setting;
    if (basicSetting) {
        [self.capturePathName setStringValue:basicSetting.capturePathName];
//        NSInteger index =
//        [[self availablePollTime] indexOfObject:[NSNumber numberWithInt:basicSetting.pollTime]];
        [self.pollTimeTF setIntegerValue:basicSetting.pollTime];
        //index = (index == NSNotFound)? 0 : index;
       // [self.pollTime selectItemAtIndex:index];
        [self.wndStreamType selectCellAtRow:basicSetting.wndStreamType column:0];
        [self setSaveLayout:basicSetting.options & VMS_SAVE_LAYOUT];
        [self setAutoRun :basicSetting.options & VMS_AUTO_RUN];
        [self setAutoSearch:basicSetting.options & VMS_AUTO_SEARCH];
        [self setAutoLogin:basicSetting.options & VMS_AUTO_LOGIN];
    }
}

- (void)updateRecordingSettingUI
{
    VMSRecordSetting *recordingSetting = self.recording_setting;
    if (recordingSetting) {
        self.enableRecording = recordingSetting.enable;
        self.recordingPathName.stringValue =
        recordingSetting.recordingPathName? recordingSetting.recordingPathName : @"";
        self.cycleRecord = recordingSetting.enableLoopRecord;
        //get free dick space
        NSError *err;
        NSDictionary *fileAttributes =
        [[NSFileManager defaultManager] attributesOfFileSystemForPath:recordingSetting.recordingPathName
                                                                error:&err];

        if (!err) {
            unsigned long long freeSpace = [[fileAttributes valueForKey:NSFileSystemFreeSize] longLongValue];
            [self.freeSpace setStringValue:[NSString stringWithFormat:@"可用空间:%dGB",(int)(freeSpace / 1073741824)]];
        }
        
        if (IS_RECORD_CONFIG_VISIBALE) {
            NSInteger index = 0;
            [self.recordingRestrict selectCellAtRow:recordingSetting.recordingRestrict column:0];
            [self.recordingRestrictTF setHidden:NO];
            [self.recordingRestrict setHidden:NO];
            index = [[self availableRecordingSize] indexOfObject:[NSNumber numberWithInt:recordingSetting.recordingSize]];
            index = (index == NSNotFound)? 0 : index;
            [self.recordingSize selectItemAtIndex:index];
            [self.recordingSizeTF setHidden:NO];
            [self.recordingSize setHidden:NO];
            [self.sizeUnitTF setHidden:NO];
            
            index = [[self availableRecordingTime] indexOfObject:[NSNumber numberWithInt:recordingSetting.recordingTime]];
            index = (index == NSNotFound)? 0 : index;
            [self.recordingTime selectItemAtIndex:index];
            [self.recordingTimeTF setHidden:NO];
            [self.recordingTime setHidden:NO];
            [self.timeUnitTF setHidden:NO];
        } else {
            [self.recordingRestrictTF setHidden:YES];
            [self.recordingRestrict setHidden:YES];
            [self.recordingSizeTF setHidden:YES];
            [self.recordingSize setHidden:YES];
            [self.sizeUnitTF setHidden:YES];
            [self.recordingTimeTF setHidden:YES];
            [self.recordingTime setHidden:YES];
            [self.timeUnitTF setHidden:YES];
        }
    }
}

#pragma mark - start up
+ (BOOL)setStartupAtBoot :(BOOL)isStartUp
{
    NSURL *helperUrl = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/VMS Helper.app"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[helperUrl path]]) {
        /*OSStatus status = LSRegisterURL((__bridge CFURLRef _Nonnull)(helperUrl), self.autoRun);
         
         if (status != noErr) {
         NSLog(@"LSRegisterURL failed!");
         }*/
        
        NSBundle *bundle = [NSBundle bundleWithURL:helperUrl];
        NSString *identifier = bundle.bundleIdentifier;//@"com.foscam.vms.helper";
        
        return SMLoginItemSetEnabled((__bridge CFStringRef)identifier, isStartUp);
    }
    
    return NO;
}

#pragma mark - action
- (IBAction)done :(id)sender
{
    self.basic_setting.capturePathName = self.capturePathName.stringValue;
    //self.basic_setting.pollTime = (int)([self.pollTime indexOfSelectedItem] + 1) * 5;
    int pollTime = self.pollTimeTF.intValue;
    if (pollTime < 5 || pollTime >3600) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"轮巡时间不在合法区间范围内"
                                         defaultButton:@"确定"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        [alert runModal];
        return;
    }
    self.basic_setting.pollTime = self.pollTimeTF.intValue;
    self.basic_setting.wndStreamType = (int)self.wndStreamType.selectedRow;
    
    int options = self.basic_setting.options;
    options = self.saveLayout? (options | VMS_SAVE_LAYOUT) : (options & ~VMS_SAVE_LAYOUT);
    
    
    if ([SystemSettingSheetController setStartupAtBoot:self.autoRun]) {
        options = self.autoRun? (options | VMS_AUTO_RUN) : (options & ~VMS_AUTO_RUN);
    }
    
    //定位到当前bundle所对应的helper.app
//    NSURL *helperUrl = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/VMS Helper.app"];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:[helperUrl path]]) {
//        /*OSStatus status = LSRegisterURL((__bridge CFURLRef _Nonnull)(helperUrl), self.autoRun);
//        
//        if (status != noErr) {
//            NSLog(@"LSRegisterURL failed!");
//        }*/
//        
//        NSBundle *bundle = [NSBundle bundleWithURL:helperUrl];
//        NSString *identifier = bundle.bundleIdentifier;//@"com.foscam.vms.helper";
//        if (SMLoginItemSetEnabled((__bridge CFStringRef)identifier, self.autoRun/*self.autoRun? true : false*/)) {
//            options = self.autoRun? (options | VMS_AUTO_RUN) : (options & ~VMS_AUTO_RUN);
//        }
//    }
    
    options = self.autoSearch? (options | VMS_AUTO_SEARCH) : (options & ~VMS_AUTO_SEARCH);
    options = self.autoLogin? (options | VMS_AUTO_LOGIN) : (options & ~VMS_AUTO_LOGIN);
    self.basic_setting.options = options;
    
    //[recording setting]
    self.recording_setting.enable = self.enableRecording;
    self.recording_setting.recordingPathName = self.recordingPathName.stringValue;
    self.recording_setting.enableLoopRecord = self.cycleRecord;
    if (IS_RECORD_CONFIG_VISIBALE) {
        self.recording_setting.recordingRestrict = (int)self.recordingRestrict.selectedRow;
        NSInteger index = [self.recordingSize indexOfSelectedItem];
        self.recording_setting.recordingSize = [[self availableRecordingSize][index] intValue];
        index = [self.recordingTime indexOfSelectedItem];
        self.recording_setting.recordingTime = [[self availableRecordingTime][index] intValue];
    }
    
    //完成
    [self.basic_setting archive];
    [self.recording_setting archive];
    
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseOK];
    else
        [self.window.sheetParent endSheet :self.window returnCode :NSModalResponseOK];
}

- (IBAction)cancel :(id)sender
{
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseCancel];
    else
        [self.window.sheetParent endSheet :self.window returnCode :NSModalResponseCancel];
}

- (IBAction)pathSelection:(id)sender
{
    NSInteger tag = [sender tag];
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    
    if ([panel runModal] == NSModalResponseOK) {
        NSString *dir = [[[panel URLs] objectAtIndex:0] path];
        //检查路径权限
        if (![VMSPathManager isDirValid:dir]) {
            [[NSAlert alertWithMessageText:@"操作失败"
                             defaultButton:@"确定"
                           alternateButton:nil
                               otherButton:nil
                 informativeTextWithFormat:@"没有权限访问该路径"] runModal];
            return;
        }
        
        switch (tag) {
            case 0:
                [self.capturePathName setStringValue:dir];
                break;
                
            case 1: {
                NSError *err;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:dir
                                                                                                       error:&err];
                [self.recordingPathName setStringValue:dir];
                if (!err) {
                    unsigned long long freeSpace = [[fileAttributes valueForKey:NSFileSystemFreeSize] longLongValue];
                    [self.freeSpace setStringValue:[NSString stringWithFormat:@"可用空间:%dGB",(int)(freeSpace / 1073741824)]];
                }
            }
                break;
            default:
                break;
        }
    }
}


- (IBAction)copyToAllMonitoringPoint :(id)sender
{
    NSString    *entity;
    NSInteger   tag = [sender tag];
    NSInteger   selectedRow = -1;
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    long long schedule[7] = {0};
    
    switch (tag) {
        case 0: {
            selectedRow = self.alarmTV.selectedRow;
            entity = @"t_alarm_plan";
            
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
        }
            break;
            
        case 1:
            selectedRow = self.recordTV.selectedRow;
            entity = @"t_rec_plan";
            [self.recordTPV getSchedule:schedule lenght:7];
            break;
        default:
            break;
    }
    
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

- (IBAction)saveScheduled:(id)sender
{
    NSInteger   tag = [sender tag];
    NSInteger   selectedRow = -1;
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    NSString    *entity;
    long long schedule[7] = {0};
    
    switch (tag) {
        case 0: {
            selectedRow = self.alarmTV.selectedRow;
            entity = @"t_alarm_plan";
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
            }
        }
            break;
            
        case 1:
            selectedRow = self.recordTV.selectedRow;
            [self.recordTPV getSchedule:schedule lenght:7];
            entity = @"t_rec_plan";
            break;
            
        default:
            break;
    }
    
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
        [[NSAlert alertWithMessageText:@"保存计划失败!"
                        defaultButton:@"确定"
                      alternateButton:nil
                          otherButton:nil
            informativeTextWithFormat:@"尚未选取任何设备"] runModal];
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
        if ([tableview.identifier isEqualToString:TVID_RECORD]) {
            [self setScheduleTasks:[db fetchScheduledTasksWithChannel:chn entity:@"t_rec_plan"]
                 forTimePickerView:self.recordTPV];
        } else if ([tableview.identifier isEqualToString:TVID_ALARM]) {
            
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
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

#pragma mark - private method
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

- (NSArray *)availableRecordingSize
{
    return [NSArray arrayWithObjects:@100,@200,@300,@500,@1000, nil];
}
- (NSArray *)availableRecordingTime
{
    return [NSArray arrayWithObjects:@5,@10,@15,@30,@60, nil];
}

- (NSArray *)availablePollTime
{
    return @[@5,@10,@15,@20,@25,@30];
}
- (void)reportErr :(NSString *)msg
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:@""];
    [alert setInformativeText :msg];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}

#pragma mark - setter && getter
- (void)setPollTime:(NSComboBox *)pollTime
{
    _pollTime = pollTime;
    [_pollTime selectItemAtIndex :0];
}

- (void)setRecording_setting:(VMSRecordSetting *)recording_setting
{
    _recording_setting = recording_setting;
    [self updateRecordingSettingUI];
}

- (void)setBasic_setting:(VMSBasicSetting *)basic_setting
{
    _basic_setting = basic_setting;
    [self updateBasicSettingUI];
}

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

- (void)setRecordTPV:(TimePickerView *)recordTPV
{
    _recordTPV = recordTPV;
    _recordTPV.style = StartWithSunday;
}

- (void)setAlarmTPV:(TimePickerView *)alarmTPV
{
    _alarmTPV = alarmTPV;
    _alarmTPV.style = StartWithSunday;
}

@end
