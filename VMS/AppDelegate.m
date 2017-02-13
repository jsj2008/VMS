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

#define NIB_SYSTEM_SETTING_SHEET_CONTROLLER    @"SystemSettingSheetController"


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
@property (assign) NSInteger curTag;
@property (strong,nonatomic) NSArray *toolbarToggleItems;
@property (weak) IBOutlet NSTextField *systemTime;
@property (nonatomic,weak) IBOutlet LBProgressBar *cpuUsageProgressBar;
@property (nonatomic,weak) IBOutlet LBProgressBar *diskUsageProgressBar;
@property (nonatomic,weak) IBOutlet NSTextField *cpuUsageValue;
@property (nonatomic,weak) IBOutlet NSTextField *diskUsageValue;
@property (strong) NSLock *CPUUsageLock;

@property (nonatomic,strong) NSTimer *localTime;
@property (nonatomic,strong) NSTimer *resUsage;
@property (nonatomic,strong) VMSLoginPanelController *loginPanelController;
@property (nonatomic,strong) LogQuerySheetController *logQuerySheetController;
@property (nonatomic,strong) NSAlert *alert;

@end

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //注册系统配置文件
    [self registerDefautsFromMainBundle];
    //开启登录Panel
    if (!self.loginPanelController) {
        self.loginPanelController = [[VMSLoginPanelController alloc] initWithWindowNibName:@"VMSLoginPanelController"];
        //prepare for login panel controller
        NSString *plistLocation = [self plistLocation];
        NSMutableDictionary *plistDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistLocation];
        NSMutableDictionary *basicSetting = [plistDict valueForKey:KEY_BASIC_SETTING];
        self.loginPanelController.basicSetting = basicSetting;
        [[NSApplication sharedApplication] beginSheet :self.loginPanelController.window
                                       modalForWindow :nil
                                        modalDelegate :self
                                       didEndSelector :@selector(loginPanelDidEnd:returnCode:contextInfo:)
                                          contextInfo :NULL];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    if (self.currentUser) {
        //登录成功
        //读取plist文件
        //保存页面大小
        //MultyVideoViewsManager *manager = self.monitoringViewController.multyVideoViewsManager;
        //NSInteger pageSize = manager.pageSize;
    }
    NSLog(@"Save config");
}


- (void)loginPanelDidEnd :(NSWindow *)sheet
              returnCode :(int)returnCode
             contextInfo :(void  *)contextInfo
{
    switch (returnCode) {
        case NSModalResponseOK: {
            NSDictionary *basicSetting = self.loginPanelController.basicSetting;
            //更新配置文件
            NSString *plistLoction = [self plistLocation];
            NSMutableDictionary *plistDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistLoction];
            //更新基本设置
            [plistDict setValue:basicSetting forKey:KEY_BASIC_SETTING];
            [plistDict writeToFile:plistLoction atomically:YES];
            //更新当前用户
            NSInteger currentUserId = [[basicSetting valueForKey:KEY_LASTEST_USER_ID] integerValue];
            [self setCurrentUser:[[VMSDatabase sharedVMSDatabase] fetchUserWithUniqueId:currentUserId]];
            [self performSelector:@selector(prepareMainWnd) withObject:self afterDelay:0.0];
            //Log
            [[VMSDatabase sharedVMSDatabase] insertLog:self.currentUser.userName
                                                  type:@"登录系统"
                                                 event:@""];
        }
            break;
            
        default:
            break;
    }
    [self setLoginPanelController:nil];
}

- (void)prepareMainWnd
{
    [self setCurTag:-1];
    [self configTitlebar];
    [self toggleContentViewForTag:1];
    [self.localTime fire];
    [self.resUsage fire];
    [self.window setIsVisible:YES];
}

- (void)configTitlebar
{
    [self.window insertTitlebarAccessoryViewController:self.titlebarAccessoryViewController atIndex:0];
    //[self.window setTitlebarAppearsTransparent:YES];
    
    //下面一段代码的作用是:
    //重写一段绘图函数，用来替换TitleView的绘图函数
    NSView *themeView = [[self.window contentView] superview];
    NSView *titlebarContainerView = [themeView.subviews lastObject];
  
    //NSView *titlebarView = [[titlebarContainerView subviews] firstObject];
    NSView *customTitleView = [[CustomTitleView alloc] initWithFrame:titlebarContainerView.frame];
    
    [titlebarContainerView addSubview :customTitleView positioned :NSWindowBelow relativeTo:nil];
    
   
    //为customTitleView增加约束条件.
    [customTitleView setTranslatesAutoresizingMaskIntoConstraints :NO];
    NSDictionary *viewsDictionary = @{@"customTitleView":customTitleView};
    NSArray  *posFormats = [NSArray arrayWithObjects:@"H:|-0-[customTitleView]-0-|",@"V:|-0-[customTitleView]-0-|", nil];

    for (NSString *posFormat in posFormats) {
        NSArray *posConstraint = [NSLayoutConstraint constraintsWithVisualFormat:posFormat
                                                                      options:0
                                                                      metrics:nil
                                                                        views:viewsDictionary];
        [titlebarContainerView addConstraints:posConstraint];
    }
    
    [self configToolbarItems];
}

- (void)configToolbarItems
{
    [self.toolbarItemMonitoring.cell setHighlightsBy:NSNoCellMask];
    [self.toolbarItemPlayback.cell setHighlightsBy:NSNoCellMask];
    [self.toolbarItemLog.cell setHighlightsBy:NSNoCellMask];
    [self.toolbarItemMap.cell setHighlightsBy:NSNoCellMask];
    [self.toolbarItemTV.cell setHighlightsBy:NSNoCellMask];
}

- (void)updateTimeAction :(NSTimer *)sender
{
    NSDate *now = [NSDate date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    
    //获取日期
    [fmt setDateFormat:@"YYYY年MM月dd日hh:mm:ss"];
    NSString *date = [fmt stringFromDate:now];
    
    //获取weekday
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:now];
    NSString *weekdayString = [self stringFromWeekday:weekday];
    
    
    [self.systemTime setStringValue:[NSString stringWithFormat:@"%@%@",date,weekdayString]];
}

- (void)updateResUsageAction :(NSTimer *)sender
{
    //Cpu useage
    CGFloat cpuUsage = [self cpuUsage];
    [self.cpuUsageProgressBar setDoubleValue :cpuUsage];
    [self.cpuUsageValue setStringValue:[NSString stringWithFormat:@"%.2f%%",cpuUsage]];

    //Disk usage
    CGFloat diskUsage = [self diskUsage];
    [self.diskUsageProgressBar setDoubleValue :diskUsage];
    [self.diskUsageValue setStringValue:[NSString stringWithFormat:@"%.2f%%",diskUsage]];
}

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
                inUse = (
                         (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - _prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                         + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - _prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                         + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - _prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
                         );
                total = inUse + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - _prevCpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
            } else {
                inUse = _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
                total = inUse + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
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

- (CGFloat)diskUsage
{
    CGFloat diskUsage = 0.0;
    NSError *err;
    NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/"
                                                                                           error:&err];
    
    if (!err) {
        unsigned long long freeSpace = [[fileAttributes objectForKey:NSFileSystemFreeSize] longLongValue];
        unsigned long long totalSpace = [[fileAttributes objectForKey:NSFileSystemSize] longLongValue];
        diskUsage = (totalSpace - freeSpace) * 100.0/ totalSpace;
    }
    
    return diskUsage;
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

- (IBAction)toggleViewAction:(id) sender {
    for (NSButton *item in self.toolbarToggleItems)
        [item setState:NSOffState];
    [sender setState:NSOnState];
    [self toggleContentViewForTag:[sender tag]];
}

- (IBAction)addDevice :(id)sender
{
    [self.monitoringViewController addDevice];
}

- (IBAction)viewLogs :(id)sender
{
    self.logQuerySheetController = [[LogQuerySheetController alloc] initWithWindowNibName:@"LogQuerySheetController"];
    [[NSApplication sharedApplication] runModalForWindow:self.logQuerySheetController.window];
}

- (IBAction)activeSystemSettingSheet :(id)sender
{
    //审查用户权限
    VMSUser *user = [self currentUser];
    UserGroup *group = [[VMSDatabase sharedVMSDatabase] fetchUserGroupWithUniqueId:user.groupId];
    
    if (group.level > 0) {
        //权限不够
        NSAlert *alert = self.alert;
        [alert setMessageText:@"权限不够"];
        [alert beginSheetModalForWindow:self.window
                      completionHandler:^(NSModalResponse returnCode) {
                          
                      }];
        return;
    }
    SystemSettingSheetController *sssc = [[SystemSettingSheetController alloc] initWithWindowNibName: NIB_SYSTEM_SETTING_SHEET_CONTROLLER];
    [self setSystemSettingSheetController: sssc];
    [self prepareForSheetController:sssc];
    [self.window beginSheet :sssc.window completionHandler :^(NSModalResponse returnCode)
    {
        switch (returnCode) {
            case NSModalResponseOK: {
                //更新基本设置
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                NSString *path = [[NSBundle mainBundle] pathForResource:@"vms" ofType:@"plist"];
                [dict setValue :sssc.basicSetting forKey:KEY_BASIC_SETTING];
                [dict setValue :sssc.recordingSetting forKey:KEY_RECORDING_SETTING];
                [dict writeToFile :path atomically:YES];
                //更新录像计划
                [[VMSDatabase sharedVMSDatabase] deleteAllRecordTasks];
                NSString *formatterString = @"HH:mm:ss";
                for (NSMutableDictionary *channelPlan in sssc.recordPlan) {
                    Channel *channel = [channelPlan valueForKey:KEY_CHANNEL];
                    WeekPlan *weekPlan = [channelPlan valueForKey:KEY_PLAN];
                    NSArray *planDate = [weekPlan planedDate];
                    for (NSDictionary *range in planDate) {
                        int weekday = [[range valueForKey:KEY_WEEKDAY] intValue];
                        NSString *begin = [[range valueForKey:KEY_BEGIN_DATE] stringWithFormatter:formatterString];
                        NSString *end = [[range valueForKey:KEY_END_DATE] stringWithFormatter:formatterString];
                        [[VMSDatabase sharedVMSDatabase] insertScheduledRecordTaskWithChannelId:channel.uniqueId
                                                                                      startTime:begin
                                                                                        endTime:end
                                                                                        weekday:weekday];
                    }
                }
                //重新开始播放视频
                //[self.monitoringViewController beginRealPlayAllChannels];
                //重新开始录像
                VideoRecorder *recorder = [VideoRecorder sharedVideoRecorder];
                [recorder setShouldStop :YES];
                [recorder run];
            }
                break;
            case NSModalResponseCancel:
                break;
            default:
                break;
        }
    }];
}

- (void)prepareForSheetController :(id)sheetController
{
    if ([sheetController isKindOfClass:[SystemSettingSheetController class]]) {
        SystemSettingSheetController *sssc = sheetController;
        //读取plist文件
        NSString *resLocation = [[NSBundle mainBundle] resourcePath];
        NSString *plistLocation = [NSString stringWithFormat:@"%@/vms.plist",resLocation];
        NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistLocation];
        //初始化系统设置表单
        [sssc setBasicSetting :[plistDict valueForKey :KEY_BASIC_SETTING]];
        [sssc setRecordingSetting: [plistDict valueForKey:KEY_RECORDING_SETTING]];
        //初始化计划录像设置
        NSMutableArray *recordPlan = [[NSMutableArray alloc] init];
        VMSDatabase *database = [VMSDatabase sharedVMSDatabase];
        NSArray *devices = [database fetchDevices];
        for (CDevice *device in devices) {
            NSArray *channels = [[VMSDatabase sharedVMSDatabase] fetchChannelsWithDevice:device];
            for (Channel *channel in channels) {
                NSArray *tasks = [[VMSDatabase sharedVMSDatabase] fetchScheduledRecordTasksWithChannel:channel];
                WeekPlan *plan = [[WeekPlan alloc] init];
                for (ScheduledRecordTask *task in tasks)
                    [plan checkWeekday :(int)task.weekday begin:task.start end:task.end withState:YES];
                
                NSMutableDictionary *channelPlan = [[NSMutableDictionary alloc] init];
                [channelPlan setObject:channel forKey:KEY_CHANNEL];
                [channelPlan setObject:plan forKey:KEY_PLAN];
                [recordPlan addObject:channelPlan];
            }
        }
        [sssc setRecordPlan:recordPlan];
    }
}

- (void)toggleContentViewForTag :(NSInteger)tag
{

    NSView *contentView = self.window.contentView;
    NSView *newView = [self viewForTag:tag];
    
    if (!newView) {
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
    
    //更新当前tag
    self.curTag = tag;
}

- (NSView *)viewForTag :(NSInteger) tag
{
    NSView *view = nil;
    NSViewController *controller;
    switch (tag) {
        case 1:
            view = [self.monitoringViewController view];
            break;
        case 2:
            view = self.playbackViewController.view;
            break;
        case 3:
            controller = self.mapViewController;
            view = self.mapViewController.view;
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
        [array addObject:self.toolbarItemMap];
        
        _toolbarToggleItems = array;
    }
    
    return _toolbarToggleItems;
}

//注册系统配置文件vms.plist到资源包中
- (void)registerDefautsFromMainBundle
{
    NSString *plistLocation = [[NSBundle mainBundle] pathForResource:@"vms" ofType:@"plist"];
    if (!plistLocation) {
        NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] init];
        //基本设置
        NSMutableDictionary *basicSetting = [[NSMutableDictionary alloc] init];
        NSString *docsDir;
        NSArray *dirPaths;
        dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        docsDir = [dirPaths objectAtIndex:0];
        [basicSetting setValue:[NSString stringWithFormat:@"%@/VMS_CAPTURE",docsDir] forKey:KEY_CAPTURE_PATHNAME];
        [basicSetting setValue:[NSNumber numberWithInt:0] forKey:KEY_NET_TYPE];
        [basicSetting setValue:[NSNumber numberWithInt:0] forKey:KEY_WND_STREAM_TYPE];
        [basicSetting setValue:[NSNumber numberWithInt:0] forKey:KEY_SAVE_LAYOUT];
        [basicSetting setValue:[NSNumber numberWithInt:0] forKey:KEY_AUTO_RUN];
        [basicSetting setValue:[NSNumber numberWithInt:0] forKey:KEY_AUTO_SEARCH];
        [basicSetting setValue:[NSNumber numberWithInt:0] forKey:KEY_AUTO_LOGIN];
        [basicSetting setValue:[NSNumber numberWithInt:5] forKey:KEY_POLL_TIME];
        [basicSetting setValue:[NSNumber numberWithBool:0] forKey:KEY_SAVE_PSW];
        [basicSetting setValue:[NSNumber numberWithInt:-1] forKey:KEY_LASTEST_USER_ID];
        [basicSetting setValue:[NSNumber numberWithInt:1] forKey:KEY_PAGE_SIZE];
        [plistDict setValue:basicSetting forKey:KEY_BASIC_SETTING];
        //录像设置
        NSMutableDictionary *videoSetting = [[NSMutableDictionary alloc] init];
        [videoSetting setValue:[NSNumber numberWithInt:1] forKey:KEY_ENABLE_RECORDING];
        [videoSetting setValue:[NSString stringWithFormat:@"%@/VMS_Record",docsDir] forKey:KEY_RECORDING_PATHNAME];
        [videoSetting setValue:[NSNumber numberWithInt:0] forKey:KEY_RECORDING_RESTRICT];
        [videoSetting setValue:[NSNumber numberWithInt:100] forKey:KEY_RECORDING_SIZE];
        [videoSetting setValue:[NSNumber numberWithInt:5] forKey:KEY_RECORDING_TIME];
        [plistDict setValue:videoSetting forKey:KEY_RECORDING_SETTING];
        //写入文件
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        [plistDict writeToFile:[NSString stringWithFormat:@"%@/vms.plist",resourcePath] atomically:YES];
    }
}

#pragma mark - setter and getter
- (NSString *)plistLocation
{
    NSString *srcLocation = [[NSBundle mainBundle] resourcePath];
    
    return [NSString stringWithFormat:@"%@/vms.plist",srcLocation];
}
- (NSTimer *)resUsage
{
    if (!_resUsage) {
        //获取CPU个数
        int mib[2U] = { CTL_HW, HW_NCPU };
        self.CPUUsageLock = [[NSLock alloc] init];
        size_t sizeOfNumCPUs = sizeof(_numCPUs);
        int status = sysctl(mib, 2U, &_numCPUs, &sizeOfNumCPUs, NULL, 0U);
        if(status) _numCPUs = 1;
        _resUsage = [NSTimer scheduledTimerWithTimeInterval :10
                                                     target :self
                                                   selector :@selector(updateResUsageAction:)
                                                   userInfo :nil
                                                    repeats :YES];
    }
    
    return _resUsage;
}

- (NSTimer *)localTime
{
    if (!_localTime) {
        _localTime = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(updateTimeAction:)
                                                    userInfo:nil
                                                     repeats:YES];
    }
    
    return _localTime;
}

- (void)setCpuUsageProgressBar:(LBProgressBar *)cpuUsageProgressBar
{
    _cpuUsageProgressBar = cpuUsageProgressBar;
    _cpuUsageProgressBar.maxValue = 100.0;
}

- (void)setDiskUsageProgressBar:(LBProgressBar *)diskUsageProgressBar
{
    _diskUsageProgressBar = diskUsageProgressBar;
    _diskUsageProgressBar.maxValue = 100.0;
}

- (NSAlert *)alert
{
    if (!_alert) {
        _alert = [[NSAlert alloc] init];
    }
    
    return _alert;
}
@end
