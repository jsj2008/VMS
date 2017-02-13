//
//  AppDelegate.m
//  VMS
//
//  Created by mac_dev on 15/5/19.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "AppDelegate.h"
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <mach/mach.h>
#import <mach/processor_info.h>
#import <mach/mach_host.h>
#import "../WebPlugin/WebPlugin/TransferSvr/net_module.h"
#import "AVSourceServerCppWrap.h"
#import "VideoMonitoringController.h"
#import "VideoPlaybackController.h"
#import "NvrVideoPBViewController.h"
#import "VMSVersionManager.h"
#import "DiskManager.h"

@implementation CustomTitleView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    NSColor *start = [NSColor colorWithCalibratedRed:46/255.0 green:128/255.0 blue:216/225.0 alpha:1];
    NSColor *end = [NSColor colorWithCalibratedRed:4/255.0 green:35/255.0 blue:88/255.0 alpha:1];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor :start endingColor :end];
    
    [gradient drawInRect:dirtyRect angle :-90];
}


@end

@interface AppDelegate () {
    processor_info_array_t _cpuInfo,_prevCpuInfo;
    mach_msg_type_number_t _numCpuInfo,_numPrevCpuInfo;
    unsigned _numCPUs;
}

@property (strong) id activity;
@property (assign) NSInteger curTag;
@property (strong,nonatomic) NSArray *toolbarToggleItems;

@property (weak) IBOutlet NSTextField *systemTime;
@property (nonatomic,weak) IBOutlet NSLevelIndicator *cpuUsageProgressBar;
@property (nonatomic,weak) IBOutlet NSLevelIndicator *diskUsageProgressBar;
@property (nonatomic,weak) IBOutlet NSTextField *cpuUsageValue;
@property (nonatomic,weak) IBOutlet NSTextField *diskUsageValue;
@property (strong) NSLock *CPUUsageLock;
@property (nonatomic,strong) NSTimer *sysInfoTimer;
@property (strong,nonatomic) NSTimer *autoSearchTimer;
@property (strong,nonatomic) NSTimer *scheduledRecordScanTimer;
@property (nonatomic,strong) VMSLoginPanelController *loginPanelController;
@property (nonatomic,strong) LogQuerySheetController *logQuerySheetController;
@property (nonatomic,strong) AddDeviceSheetController *addDeviceSheetController;
@property (nonatomic,strong) NSWindowController *sheetController;

@property (readwrite) BOOL appLocked;

@end

@implementation AppDelegate

//检查更新
- (void)checkUpdate
{
    VMSBasicSetting *bs         = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
    NSString        *localVer   = [bs version];
    NSString        *latestVer  = [VMSVersionManager latestVersion];
    //NSString        *confPath   = [VMSPathManager vmsConfPath:NO];
    
    if ([VMSVersionManager compareVersion:localVer withVersion:latestVer] == NSOrderedAscending) {
        //检测到不是最新的版本
        //比较历史版本
//        if ([VMSVersionManager compareVersion:localVer withVersion:VMS_ALPHA_V0_0_1] == NSOrderedAscending) {
//            //检测到用户本地版本比内侧第一版低，需要对数据库进行迁移
//            [[VMSDatabase sharedVMSDatabase] migration];
//        }
//        
//        if ([VMSVersionManager compareVersion:localVer withVersion:VMS_ALPHA_V0_0_3] == NSOrderedAscending) {
//            //检测到用户本地比第三版低，需要重建配置文件
//            NSFileManager *manager = [NSFileManager defaultManager];
//            if ([manager fileExistsAtPath:confPath]) {
//                //删除
//                [manager removeItemAtPath:confPath error:NULL];
//            }
//        }
        
        if ([VMSVersionManager compareVersion:localVer withVersion:VMS_ALPHA_V0_0_5] == NSOrderedAscending) {
            //检测到用户本地比第五版低，需要迁徙数据库
            [[VMSDatabase sharedVMSDatabase] migration];
        }
        
        if ([latestVer isEqualToString:VMS_BROAD_BEAN_BETA] && ![localVer isEqualToString:VMS_BROAD_BEAN_BETA]) {
            //检测到不是"蚕豆版",自动更改配置文件为开机自启动、自动登录、自动全屏.
            bs.options |= VMS_AUTO_RUN;
            bs.options |= VMS_AUTO_LOGIN;
            bs.options |= VMS_AUTO_FULLSCREEN;
        }
        else {
            //取消自动全屏
            bs.options &= ~VMS_AUTO_FULLSCREEN;
        }
        
        //更新版本号
        [bs setVersion:latestVer];
        [bs archive];
    }
}

//检查开机自启动
- (void)checkStartupAtBoot
{
    VMSBasicSetting *bs = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
    [JFPreferencePanelController setStartupAtBoot:(bs.options & VMS_AUTO_RUN)];
}

- (void)redirectConsoleLogToDocumentFolder
{
    NSDate *now = [NSDate date];
    NSString *fileName = [NSString stringWithFormat:@"vmsConsole(%@).log",[now stringWithFormatter:@"YYYY-MM-dd_HH:mm:ss"]];
    NSString *logsDir = [VMSPathManager vmsClientLogsDir];
    
    if (logsDir) {
        NSString *logPath = [logsDir stringByAppendingPathComponent:fileName];
        freopen([logPath fileSystemRepresentation],"a+",stderr);
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //忽略sigpipi信号
    signal(SIGPIPE, SIG_IGN);
    //检测更新
    [self checkUpdate];
    //检测开机自启动
    [self checkStartupAtBoot];
    //禁止系统空闲sleep
    self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions: NSActivityUserInitiated | NSActivityLatencyCritical
                                                   reason:@"video"];
    //开启服务
    //int serverPort = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]].serverPort;
    //net_module::instance().init(serverPort);
    //日志重定向
#ifndef DEBUG
    [self redirectConsoleLogToDocumentFolder];
#endif
    AVPLAY_Init();
    [self alarmController];
    [self showLoginPanelForOperator :VMS_LOGIN
               withCompletionHandle :^(NSModalResponse returnCode)
    {
        switch (returnCode) {
            case NSModalResponseOK: {
                [self performSelector:@selector(prepareMainWnd) withObject:self afterDelay:1.0];
                [[VMSDatabase sharedVMSDatabase] insertLog:self.currentUser.userName
                                                      type:@"登录系统"
                                                     event:@""];
            }
                break;
            case NSModalResponseCancel: {
                [[NSApplication sharedApplication] performSelector:@selector(terminate:)
                                                        withObject:nil
                                                        afterDelay:0.0];
            }
                break;
                
            default:
                break;
        }
        [self setLoginPanelController:nil];
    }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    if (self.currentUser) {
        //[[DispatchCenter sharedDispatchCenter] cleanUp];
        //关闭服务
        net_module::instance().uninit();
        //归档
        [self.monitoringViewController archive];
    }
    
    AVPLAY_Cleanup();
    [[VMSDatabase sharedVMSDatabase] disconnect];
}

- (void)showLoginPanelForOperator :(VMS_OP)op
             withCompletionHandle :(void(^)(NSModalResponse returnCode))block
{
#ifdef DEBUG
    assert(!self.loginPanelController);
#endif
    
    //开启登录Panel
    if (!self.loginPanelController) {
        self.loginPanelController = [[VMSLoginPanelController alloc] initWithWindowNibName:@"VMSLoginPanelController" vmsOperator:op];
        self.loginPanelController.basicSetting = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
        
        
        if (!self.loginPanelController) {
            NSLog(@"从文件中加载VMSLoginPanelController失败,退出应用程序");
            block(NSModalResponseCancel);
        }
        else {
            NSModalResponse returnCode = [[NSApplication sharedApplication] runModalForWindow:self.loginPanelController.window];
            
            if (NSModalResponseOK == returnCode)
                [self updateCurUser];
            
            block(returnCode);
        }
    }
}

- (void)updateCurUser
{
    //更新当前用户
    VMSBasicSetting *basicSetting =
    [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
    int currentUserId = basicSetting.latestUserId;
    [self setCurrentUser:[[VMSDatabase sharedVMSDatabase] fetchUserWithUniqueId:currentUserId]];
}

#pragma mark - Action
- (void)addDevices :(NSArray *)devices
{
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    
    for (CDevice *device in devices) {
        
        if ([AddDeviceSheetController insertDevice:device]) {
            [db fetchChannelsWithDevice:device];
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:VMS_DEVICE_ADD],NOTIFI_KEY_DB_OP,
                                      device,NOTIFI_KEY_DEVICE,nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_CHANGED_NOTIFICATION
                                                                object:self
                                                              userInfo:userInfo];
        }
        else {
            [db deleteDevice:device];
        }
    }
}

//定时自动搜索设备任务，10s触发一次
- (void)autoSearchAction :(NSTimer *)timer
{
    //查看是否需要自动搜索
    VMSBasicSetting *bs     = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
    VMS_OPTION      options = bs.options;
    
    if ((options & VMS_AUTO_SEARCH)) {
        [DispatchCenter searchDevicesWithCompletingHandle:^(NSArray *devices) {
            dispatch_async(dispatch_get_main_queue(), ^{
                VMSDatabase     *db                 = [VMSDatabase sharedVMSDatabase];
                NSMutableArray  *devicesNotExist    = [[NSMutableArray alloc] init];
                
                for (CDevice *device in devices) {
                    device.serialNumber = @"";//自动搜索默认使用的IP连接方式
                    if (![db fetchDeviceWithEntity:@"mac_address" value:device.macAddress]) {
                        [devicesNotExist addObject:device];
                    }
                }
                
                [self addDevices:devicesNotExist];
            });
        }];
    }
}

- (IBAction)exitAction:(id)sender {
    VMS_LOCKED_ALERT;
    [self showLoginPanelForOperator :VMS_LOGOFF
               withCompletionHandle :^(NSModalResponse returnCode)
    {
        switch (returnCode) {
            case NSModalResponseOK:
                [[NSApplication sharedApplication] performSelector:@selector(terminate:)
                                                        withObject:nil
                                                        afterDelay:0.0];
                [[VMSDatabase sharedVMSDatabase] insertLog:self.currentUser.userName
                                                      type:@"登出系统"
                                                     event:@""];
                break;
                
            case NSModalResponseCancel:
                break;
                
            default:
                break;
        }
        [self setLoginPanelController:nil];
    }];
}

- (void)toggleButtonWithTag :(NSInteger)tag
{
    for (NSButton *item in self.toolbarToggleItems)
        [item setState:NSOffState];
    
    NSButton *btn = self.toolbarToggleItems[tag - 1];
    [btn setState:NSOnState];
}

- (IBAction)toggleViewAction:(id) sender {
    id<TabMVCProtocol> mvc = [self tabMVCForTag:self.curTag];
    NSInteger tag = self.curTag;
    
    if ([mvc respondsToSelector:@selector(willTab:stop:)]) {
        BOOL stop = NO;
        [mvc willTab:nil stop:&stop];
        
        if (!stop) {
            tag = [sender tag];
            [self toggleContentViewForTag:tag];
        }
    }
    [self toggleButtonWithTag:tag];
}

- (IBAction)addDevice :(id)sender
{
    VMS_LOCKED_ALERT;
    //审查用户权限
    VMSUser *user = [self currentUser];
    UserGroup *group = [[VMSDatabase sharedVMSDatabase] fetchUserGroupWithUniqueId:user.groupId];
    
    if (group.level > 0) {
        //权限不够
        NSAlert *alert = self.alert;
        [alert setMessageText:@"权限不够"];
        [alert beginSheetModalForWindow:self.window
                      completionHandler:NULL];
        return;
    }
    
    if (!self.addDeviceSheetController) {
        self.addDeviceSheetController =
        [[AddDeviceSheetController alloc] initWithWindowNibName:NIB_ADD_DEVICE_SHEET];
        
        if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9) {
            [[NSApplication sharedApplication] beginSheet:self.addDeviceSheetController.window
                                           modalForWindow:self.window
                                            modalDelegate:self
                                           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                                              contextInfo:(void *)self.addDeviceSheetController];
        }
        else {
            [self.window beginSheet:self.addDeviceSheetController.window
                  completionHandler:^(NSModalResponse returnCode)
             {
                 [self didEndSheet:self.addDeviceSheetController.window
                        returnCode:returnCode
                       contextInfo:(void *)self.addDeviceSheetController];
             }];
        }
    }
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
    id sender = (__bridge id)contextInfo;
    
    if ([sender isKindOfClass:[AddDeviceSheetController class]]) {
        AddDeviceSheetController *adsc = (__bridge AddDeviceSheetController *)contextInfo;
        if (returnCode == NSModalResponseOK) {
            //The model window returns the devices that have been modified.Do something here
            //广播消息，通知所有收听司机，Soming thing changed!!!
            CDevice *device = adsc.device;
            [[VMSDatabase sharedVMSDatabase] fetchChannelsWithDevice:device];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:VMS_DEVICE_ADD],NOTIFI_KEY_DB_OP,device,NOTIFI_KEY_DEVICE,nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_CHANGED_NOTIFICATION
                                                                object:self
                                                              userInfo:userInfo];
        }
        //销毁窗口
        [adsc close];
        self.addDeviceSheetController = nil;
    }
}

- (IBAction)toggleUser :(id)sender
{
    VMS_LOCKED_ALERT;
    [self showLoginPanelForOperator:VMS_TOGGLE_USER
               withCompletionHandle:^(NSModalResponse returnCode)
     {
         if (returnCode == NSModalResponseOK) {
             [[VMSDatabase sharedVMSDatabase] insertLog:self.currentUser.userName
                                                   type:@"用户切换"
                                                  event:@""];
         }
         [self setLoginPanelController:nil];
     }];
}

- (IBAction)toggleLock:(id)sender
{
    if (self.isAppLocked) {
        //应用程序已经锁定，需要去定用户身份，以解锁
        [self showLoginPanelForOperator:VMS_UNLOCK withCompletionHandle:^(NSModalResponse returnCode)
         {
             switch (returnCode) {
                 case NSModalResponseOK:
                     self.appLocked = NO;;
                     break;
                     
                 default:
                     break;
             }
             
             [self setLoginPanelController:nil];
         }];
    } else {
        self.appLocked = YES;
    }
    
    [sender setState:self.appLocked];
    [[VMSDatabase sharedVMSDatabase] insertLog:self.currentUser.userName
                                          type:self.appLocked?@"系统加锁":@"系统解锁"
                                         event:@""];
}

- (IBAction)viewLogs :(id)sender
{
    VMS_LOCKED_ALERT;
    self.logQuerySheetController = [[LogQuerySheetController alloc] initWithWindowNibName:@"LogQuerySheetController"];
    [[NSApplication sharedApplication] runModalForWindow:self.logQuerySheetController.window];
}


- (IBAction)activePreferencePanel:(id)sender
{
    VMS_LOCKED_ALERT;
    
    //审查用户权限
    VMSUser *user = [self currentUser];
    UserGroup *group = [[VMSDatabase sharedVMSDatabase] fetchUserGroupWithUniqueId:user.groupId];
    
    if (group.level > 0) {
        //权限不够
        NSAlert *alert = self.alert;
        [alert setMessageText:@"权限不够"];
        [alert beginSheetModalForWindow:self.window
                      completionHandler:NULL];
        return;
    }

    
    self.sheetController = [[JFPreferencePanelController alloc] initWithWindowNibName:@"JFPreferencePanelController"];

    //模态对话
    [self.sheetController.window center];
    [NSApp runModalForWindow:self.sheetController.window];
    
    //结束模态对话，关闭
    [self.sheetController close];
    [self setSheetController:nil];
}


#pragma mark - Config User Interface
- (void)prepareMainWnd
{
    [self setupMainWindow];
    [self setCurTag:-1];
    [self.sysInfoTimer fire];
    [self.scheduledRecordScanTimer fire];
    [self.autoSearchTimer fire];
    [self toggleContentViewForTag:1];
}

#pragma mark - Timer Action
- (void)updateSysInfoAction :(NSTimer *)sender
{
    [self updateTimeAction];
    [self updateResUsageAction];
}

- (void)updateTimeAction
{
    @autoreleasepool {
        NSDate *now = [NSDate date];
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        
        //获取日期
        [fmt setDateFormat:@"YYYY年MM月dd日HH:mm:ss"];
        NSString *date = [fmt stringFromDate:now];
        
        //获取weekday
        NSCalendar  *calendar = [NSCalendar currentCalendar];
        NSInteger   weekday = [calendar components:NSCalendarUnitWeekday fromDate:now].weekday;
        NSString    *weekdayString = [self stringFromWeekday:weekday];
        
        //更新UI
        NSString    *title = [NSString stringWithFormat:@"%@%@",date,weekdayString];
        [self.systemTime setStringValue:title];
    }
}

- (void)updateResUsageAction
{
    //Cpu useage
    CGFloat cpuUsage = [self cpuUsage];
    
    [self.cpuUsageProgressBar setDoubleValue :cpuUsage];
    [self.cpuUsageValue setStringValue:[NSString stringWithFormat:@"%.2f%%",cpuUsage]];

    //Disk usage
    CGFloat diskUsage = [DiskManager diskUsage];
    [self.diskUsageProgressBar setDoubleValue :diskUsage];
    [self.diskUsageValue setStringValue:[NSString stringWithFormat:@"%.2f%%",diskUsage]];
}

- (void)scheduledRecordScanTimer :(NSTimer *)sender
{
    [[RecordCenter sharedRecordCenter] scanTasks];
    [[RecordCenter sharedRecordCenter] loopRecord];
}

#pragma mark - CPU && Disk Usage
- (CGFloat)cpuUsage
{
    CGFloat cpuUsage = 0.0;
    natural_t numCPUsU;
    kern_return_t err = host_processor_info(mach_host_self(),
                                            PROCESSOR_CPU_LOAD_INFO,
                                            &numCPUsU,
                                            (processor_info_array_t *)&_cpuInfo,
                                            &_numCpuInfo);
    if(err == KERN_SUCCESS) {
        [self.CPUUsageLock lock];
        
        CGFloat usage = 0;
        for(unsigned i = 0U; i < numCPUsU; ++i) {
            float inUse, total;
            if(_prevCpuInfo) {
                inUse =
                ((_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] - _prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                 + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - _prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                 + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE] - _prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]));
                total =
                inUse + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - _prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
            } else {
                inUse =
                _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
                total =
                inUse + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
            }
            
            usage += inUse / total;
            //NSLog(@"Core: %u Usage: %f",i,inUse / total);
        }
        
        cpuUsage = usage / 4.0 * 100;
        
        [self.CPUUsageLock unlock];
        
        if(_prevCpuInfo) {
            size_t prevCpuInfoSize = sizeof(integer_t) * _numPrevCpuInfo;
            vm_deallocate(mach_task_self(), (vm_address_t)_prevCpuInfo, prevCpuInfoSize);
        }
        
        _prevCpuInfo = _cpuInfo;
        _numPrevCpuInfo = _numCpuInfo;
        
        _cpuInfo = NULL;
        _numCpuInfo = 0U;
    } else {
        NSLog(@"Error!");
        [NSApp terminate:nil];
    }

    
    return cpuUsage;
}

- (NSString *)stringFromWeekday :(NSInteger)weekday
{
    NSString *string = @"";
    
    switch (weekday) {
        case 1:
            string = @"星期日";
            break;
        case 2:
            string = @"星期一";
            break;
        case 3:
            string = @"星期二";
            break;
        case 4:
            string = @"星期三";
            break;
        case 5:
            string = @"星期四";
            break;
        case 6:
            string = @"星期五";
            break;
        case 7:
            string = @"星期六";
            break;
        default:
            break;
    }
    return string;
}


//- (void)prepareForSheetController :(id)sheetController
//{
//    if ([sheetController isKindOfClass:[SystemSettingSheetController class]]) {
//        SystemSettingSheetController *sssc = sheetController;
//        //初始化系统设置表单
//        [sssc setBasic_setting:[[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]]];
//        [sssc setRecording_setting:[[VMSRecordSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]]];
//    }
//}

- (void)toggleContentViewForTag :(NSInteger)tag
{
    NSView *contentView = self.window.contentView;
    NSView *newView = [self viewForTag:tag];
    
    if (!newView) {
        NSLog(@"toggle content view for tag %ld,new view is nil",tag);
        return;
    }
    
    if (self.curTag == -1) {
        //There is nothing on the content view.We need add a subview on it.
        [contentView addSubview:newView];
    } else if (tag == self.curTag) {
        //Do nothing if the tag is curTag.
    } else {
        //Replace the old view with new one.
        NSView *oldView = [self viewForTag:self.curTag];
        
        [NSAnimationContext beginGrouping];
        
        if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
            [[NSAnimationContext currentContext] setDuration:1.0];
        [[contentView animator] replaceSubview:oldView with:newView];
        [NSAnimationContext endGrouping];
        
        switch (self.curTag) {
            case 2:
                self.playbackViewController = nil;
                break;
            case 3:
                [self.nvrPBViewController uninit];
                self.nvrPBViewController = nil;
                break;
            default:
                break;
        }
    }
    
    //增加约束条件
    [newView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSDictionary *viewsDictionary = @{@"newView":newView};
    NSArray  *posFormats = [NSArray arrayWithObjects:@"H:|-0-[newView]-0-|",@"V:|-0-[newView]-0-|", nil];
    for (NSString *posFormat in posFormats) {
        NSArray *posConstraint = [NSLayoutConstraint constraintsWithVisualFormat:posFormat
                                                                         options:0
                                                                         metrics:nil
                                                                           views:viewsDictionary];
        [contentView addConstraints:posConstraint];
    }
    [contentView updateConstraints];
    //更新当前tag
    self.curTag = tag;
}

- (id<TabMVCProtocol>)tabMVCForTag :(NSInteger)tag
{
    switch (tag) {
        case 1:
            return self.monitoringViewController;
        case 2:
            return self.playbackViewController;
        case 3:
            return self.nvrPBViewController;
        default:
            break;
    }
    
    return nil;
}

- (NSView *)viewForTag :(NSInteger) tag
{
    NSView *view = nil;
    switch (tag) {
        case 1:
            view = [self.monitoringViewController view];
            break;
        case 2:
            view = self.playbackViewController.view;
            break;
        case 3:
            view = self.nvrPBViewController.view;
            break;
        default:
            break;
    }
    
    return view;
}


- (NSArray *)toolbarToggleItems
{
    if (!_toolbarToggleItems) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [array addObject:self.toolbarItemMonitoring];
        [array addObject:self.toolbarItemPlayback];
        [array addObject:self.toolbarItemNvrPlayback];
        
        _toolbarToggleItems = array;
    }
    
    return _toolbarToggleItems;
}


#pragma mark - setter and getter
- (void)setToolbarItemMonitoring:(NSButton *)toolbarItemMonitoring
{
    _toolbarItemMonitoring = toolbarItemMonitoring;
    [_toolbarItemMonitoring.cell setHighlightsBy:NSNoCellMask];
}

- (void)setToolbarItemPlayback:(NSButton *)toolbarItemPlayback
{
    _toolbarItemPlayback = toolbarItemPlayback;
    [_toolbarItemPlayback.cell setHighlightsBy:NSNoCellMask];
}

- (void)setToolbarItemLog:(NSButton *)toolbarItemLog
{
    _toolbarItemLog = toolbarItemLog;
    [_toolbarItemLog.cell setHighlightsBy:NSNoCellMask];
}

- (void)setToolbarItemNvrPlayback:(NSButton *)toolbarItemNvrPlayback
{
    _toolbarItemNvrPlayback = toolbarItemNvrPlayback;
    [_toolbarItemNvrPlayback.cell setHighlightsBy:NSNoCellMask];
}

- (void)setupMainWindow
{
    //NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
    
    NSView *themeFrame = [self.window.contentView superview];
    NSView *titlebar = nil;
   
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10){
        //在10_10之前的版本窗口结构发生改变
//        - (void)_createTitlebarView
//        {
//            // Create the title bar view
//            INMovableByBackgroundContainerView *container = [[INMovableByBackgroundContainerView alloc] initWithFrame:NSZeroRect];
//            // Configure the view properties and add it as a subview of the theme frame
//            NSView *firstSubview = self.themeFrameView.subviews.firstObject;
//            [self _recalculateFrameForTitleBarContainer];
//            [self.themeFrameView addSubview:container positioned:NSWindowBelow relativeTo:firstSubview];
//            _titleBarContainer = container;
//            self.titleBarView = [[INTitlebarView alloc] initWithFrame:NSZeroRect];
//        }
    }
    else {
        NSView *titlebarContainerView = themeFrame.subviews.lastObject;
        titlebar = [[titlebarContainerView subviews] lastObject];
    }
   
    if (titlebar) {
        CAGradientLayer *gradient = [CAGradientLayer layer];
        CGColorRef c1 = [[NSColor colorWithCalibratedRed:52/255.0 green:141/255.0 blue:212/255.0 alpha:1.0] CGColor];
        CGColorRef c2 = [[NSColor colorWithCalibratedRed:0/255.0 green:59/255.0 blue:107/255.0 alpha:1.0] CGColor];
        
        [gradient setColors:[NSArray arrayWithObjects:(__bridge id)c2,(__bridge id)c1, nil]];
        [titlebar setWantsLayer:YES];
        [titlebar setLayer:gradient];
        [gradient setNeedsDisplay];
    }
    else {
        NSLog(@"no titlebar access");
    }
    
    //设置窗口关闭按钮回调
    NSButton *closeButton = [_window standardWindowButton:NSWindowCloseButton];
    closeButton.target = self;
    closeButton.action = @selector(exitAction:);
    
    [self.window setIsVisible:YES];
}

//- (void)setWindow:(NSWindow *)window
//{
//    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
//    _window = window;
//    
//    NSView *themeFrame = [_window.contentView superview];
//    NSView *titlebarContainerView = themeFrame.subviews.lastObject;
//    NSView *titlebar = [[themeFrame.subviews.lastObject subviews] lastObject];
//    
//    if (titlebar) {
//        NSLog(@"themeFrame.className = %@, titlebar.className = %@,titlebarContainerView.className = %@",
//              themeFrame.className,titlebar.className,titlebarContainerView.className);
//        NSLog(@"themFrame.subviews.count = %ld",themeFrame.subviews.count);
//        NSLog(@"titlebarContainerView.subviews.count = %ld",titlebarContainerView.subviews.count);
//        CAGradientLayer *gradient = [CAGradientLayer layer];
//        CGColorRef c1 = [[NSColor colorWithCalibratedRed:52/255.0 green:141/255.0 blue:212/255.0 alpha:1.0] CGColor];
//        CGColorRef c2 = [[NSColor colorWithCalibratedRed:0/255.0 green:59/255.0 blue:107/255.0 alpha:1.0] CGColor];
//        
//        [gradient setColors:[NSArray arrayWithObjects:(__bridge id)c2,(__bridge id)c1, nil]];
//        [titlebar setWantsLayer:YES];
//        [titlebar setLayer:gradient];
//        [gradient setNeedsDisplay];
//    }
//    else {
//        NSLog(@"no titlebar access");
//    }
//    
//    //设置窗口关闭按钮回调
//    NSButton *closeButton = [_window standardWindowButton:NSWindowCloseButton];
//    closeButton.target = self;
//    closeButton.action = @selector(exitAction:);
//}
//- (NSTimer *)resUsage
//{
//    if (!_resUsage) {
//        //获取CPU个数
//        int mib[2U] = { CTL_HW, HW_NCPU };
//        self.CPUUsageLock = [[NSLock alloc] init];
//        size_t sizeOfNumCPUs = sizeof(_numCPUs);
//        int status = sysctl(mib, 2U, &_numCPUs, &sizeOfNumCPUs, NULL, 0U);
//        if(status) _numCPUs = 1;
//        _resUsage = [NSTimer scheduledTimerWithTimeInterval :10
//                                                     target :self
//                                                   selector :@selector(updateResUsageAction:)
//                                                   userInfo :nil
//                                                    repeats :YES];
//    }
//    
//    return _resUsage;
//}

- (NSTimer *)sysInfoTimer
{
    if (!_sysInfoTimer) {
        _sysInfoTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(updateSysInfoAction:)
                                                    userInfo:nil
                                                     repeats:YES];
        //获取CPU个数
        int mib[2U] = { CTL_HW, HW_NCPU };
        self.CPUUsageLock = [[NSLock alloc] init];
        size_t sizeOfNumCPUs = sizeof(_numCPUs);
        int status = sysctl(mib, 2U, &_numCPUs, &sizeOfNumCPUs, NULL, 0U);
        if(status) _numCPUs = 1;
    }
    
    return _sysInfoTimer;
}

- (NSTimer *)scheduledRecordScanTimer
{
    if (!_scheduledRecordScanTimer) {
        _scheduledRecordScanTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                                     target:self
                                                                   selector:@selector(scheduledRecordScanTimer:)
                                                                   userInfo:nil
                                                                    repeats:YES];
    }
    
    return _scheduledRecordScanTimer;
}
- (NSTimer *)autoSearchTimer
{
    if (!_autoSearchTimer) {
        _autoSearchTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                            target:self
                                                          selector:@selector(autoSearchAction:)
                                                          userInfo:nil
                                                           repeats:YES];
    }
    
    return _autoSearchTimer;
}

- (NSAlert *)alert
{
    if (!_alert) {
        _alert = [[NSAlert alloc] init];
    }
    
    return _alert;
}

- (VMSAlarmController *)alarmController
{
    if (!_alarmController) {
        _alarmController = [[VMSAlarmController alloc] init];
    }
    
    return _alarmController;
}


- (NvrVideoPBViewController *)nvrPBViewController
{
    if (!_nvrPBViewController) {
        _nvrPBViewController = [[NvrVideoPBViewController alloc] initWithNibName:@"NvrVideoPBViewController"
                                                                          bundle:nil];
    }
    
    return _nvrPBViewController;
}

- (VideoPlaybackController *)playbackViewController
{
    if (!_playbackViewController) {
        _playbackViewController = [[VideoPlaybackController alloc] initWithNibName:@"VideoPlaybackController"
                                                                            bundle:nil];
    }
    
    return _playbackViewController;
}

- (VideoMonitoringController *)monitoringViewController
{
    if (!_monitoringViewController) {
        _monitoringViewController = [[VideoMonitoringController alloc] initWithNibName:@"VideoMonitoringController"
                                                                                bundle:nil];
    }
    
    return _monitoringViewController;
}
@end
