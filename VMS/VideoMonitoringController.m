//
//  VideoMonitoringController.m
//  VMS
//
//  Created by mac_dev on 15/6/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//


#import "VideoMonitoringController.h"
#import "AddPresetWindowController.h"
#import "PTZCruiseViewController.h"
#import "NVRPTZCruiseViewController.h"

#define mor_debug   1

#define COLUMNID_NAME                       @"video devices column"	// the single column name in our outline view
#define INITIAL_INFODICT                    @"Outline"		// name of the dictionary file to populate our outline view
#define IDENTIFIER_TOP_BOTTOM_SPLITVIEW     @"ptz and device list split view"
#define kPTZViewHeight                      466.0
#define kIconImageSize                      16.0
#define kNodesPBoardType                    @"myNodesPBoardType"	// drag and drop pasteboard type
#define KEY_NAME                            @"name"
#define KEY_GROUP                           @"group"
#define KEY_FOLDER                          @"folder"
#define KEY_ENTRIES                         @"entries"
#define NIB_IPC_SETTING_SHEET               @"DeviceSettingSheet"
#define NIB_NVR_SETTING_SHEET               @"NVRSettingSheet"

#define NIB_ADD_POLLING_GROUP_SHEET         @"AddPollingGroupSheetController"
#define NIB_ADD_DEVICE_GROUP_SHEET          @"AddDeviceGroupSheetController"
#define QUERY_DEVICE_STATE_INTERVAL         30.0
#define ID_OUTLINE_VIEW_CONTEXT_MENU        @"outline view context menu"
#define ID_VIDEO_WND_CONTEXT_MENU           @"video wnd context menu"
#define KEY_POLLING_GROUP                   @"polling group"
#define KEY_POLLING_INFO                    @"polling info"

////////////////////////////////////////////////////////////////////////////////
@implementation PreviewObjState
static NSString *codingKeyViewId = @"viewId";
static NSString *codingKeyIsPlay = @"isPlay";

- (instancetype)init
{
    if (self = [super init]) {
        self.viewId = -1;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.viewId = [[aDecoder decodeObjectForKey:codingKeyViewId] intValue];
        self.play = [[aDecoder decodeObjectForKey:codingKeyIsPlay] boolValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSNumber numberWithInt:self.viewId] forKey:codingKeyViewId];
    [aCoder encodeObject:[NSNumber numberWithBool:self.isPlay] forKey:codingKeyIsPlay];
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation PollingState
static NSString *codingKeyPollMap = @"pollMap";
- (instancetype)init
{
    if (self = [super init]) {
        self.sequenceNum = -1;
        self.timer = nil;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.sequenceNum = -1;
        self.timer = nil;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation ChannelState
- (instancetype)init
{
    if (self = [super init]) {
        self.online = NO;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.online = NO;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
}

@end


@implementation DeviceState

- (instancetype)init
{
    if (self = [super init]) {
        self.online = NO;
    }
    
    return self;
}

@end
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface VideoMonitoringController ()<NSSplitViewDelegate,
NSOutlineViewDataSource,NSOutlineViewDelegate,NSMenuDelegate> {
    TreeNode *_draggedNode;
    int _draggedViewId;
}

@property (nonatomic,weak) IBOutlet NSView *placeHolder1;
@property (nonatomic,weak) IBOutlet DMSplitView *splitview;
@property (nonatomic,weak) IBOutlet JFBackground *cloudConsoleView;
@property (nonatomic,weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic,weak) IBOutlet NSButton *presetAddBT;
@property (nonatomic,weak) IBOutlet NSTextField *presetNameTF;
@property (nonatomic,weak) IBOutlet NSButton *presetDelete;
@property (nonatomic,weak) IBOutlet NSButton *presetRun;
@property (nonatomic,weak) IBOutlet NSButton *patrolSetting;
@property (nonatomic,weak) IBOutlet NSButton *cruiseStartBT;
@property (nonatomic,weak) IBOutlet NSButton *cruiseStopBT;
@property (nonatomic,weak) IBOutlet NSButton *ptzToggle;
@property (nonatomic,weak) IBOutlet NSSlider *horizontalSlider;
@property (nonatomic,weak) IBOutlet NSMenu *contextMenu;
@property (nonatomic,weak) IBOutlet NSPopUpButton *presetPointListBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *cruiseMapListBtn;
@property (nonatomic,strong) PTZCruiseViewController *cruiseVC;

@property (nonatomic,weak) IBOutlet NSView *cruiseZone;

@property (nonatomic,assign, getter=isCollapsed) BOOL collapsed;
@property (nonatomic,strong) NSArray *outlineViewContents;

@property (nonatomic,strong) NSMutableDictionary *deviceMap;//设备状态表
@property (nonatomic,strong) NSMutableDictionary *preViewMap;//预览通道状态表
@property (nonatomic,strong) NSWindowController *sheetController;
@property (nonatomic,strong) NSWindowController *settingController;
@property (nonatomic,strong) NSTimer *pagePollingTimer;
@property (nonatomic,strong) NSTimer *onLineTestTimer;
@property (nonatomic,assign) int pagePollingInterval;
@property (nonatomic,strong) AudioGrabber *audioGrabber;
@property (nonatomic,assign) NSInteger scanInterver;
@property (nonatomic,weak) IBOutlet NSView *ptzZone;
@property (nonatomic,weak) IBOutlet NSView *zoomZone;
@property (nonatomic,weak) IBOutlet NSImageView *ptzBkView;

@end


@implementation VideoMonitoringController
static NSString * cfgKeyPreviewMap = @"previewMap";

#pragma mark - public api
- (void)previewAll
{
    TreeNode    *root       = [self.outlineView itemAtRow :0];
    SEL         aSelector   = @selector(performBeginPreviewWithItem:viewId:);
    
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:aSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    int viewId = -1;
   
    [invocation setTarget:self];
    [invocation setSelector:aSelector];
    [invocation setArgument:&root atIndex:2];
    [invocation setArgument:&viewId atIndex:3];
    
    [self walkThroughTree:root withInvocation:invocation];
}

- (void)stopPreviewAll
{
    TreeNode* root = [self.outlineView itemAtRow :0];
    SEL aSelector = @selector(performStop:);
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:aSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:self];
    [invocation setSelector:aSelector];
    [invocation setArgument:&root atIndex:2];
    
    [self walkThroughTree:root withInvocation:invocation];
}

- (void)archive
{
    [self.multyVideoViewsManager archive];
    //遍历Map,开始归档
    NSMutableDictionary *map = self.preViewMap;
    NSArray *allKeys = map.allKeys;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (NSString *key in allKeys) {
        PreviewObjState *previewObjState = [self.preViewMap valueForKey:key];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:previewObjState];
        [dict setValue:data forKey:key];
    }
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:cfgKeyPreviewMap];
}

- (void)unArchive
{
    [self.multyVideoViewsManager unArchive];
    //遍历Map,开始解档
    NSMutableDictionary *map = self.preViewMap;
    NSArray             *allKeys = map.allKeys;
    NSMutableDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:cfgKeyPreviewMap];
    
    for (NSString *key in allKeys) {
        NSData *data = [dict valueForKey:key];
        PreviewObjState *previewObjState = [NSKeyedUnarchiver unarchiveObjectWithData:data];

        if (previewObjState) {
            [map setValue:previewObjState forKey:key];
        }
    }
    
    [self onUnArchive];
}

- (void)onUnArchive
{
    TreeNode *root = [self.outlineViewContents firstObject];
    SEL                 aSelector           = @selector(performRestorePreviewWithItem:);
    NSMethodSignature   *methodSignature    = [self methodSignatureForSelector:aSelector];
    NSInvocation        *invocation         = [NSInvocation invocationWithMethodSignature:methodSignature];
    
    [invocation setTarget:self];
    [invocation setSelector:aSelector];
    [invocation setArgument:&root atIndex:2];
    
    [self walkThroughTree:[self.outlineViewContents firstObject] withInvocation:invocation];
    
    //查看是否需要自动解档
    BOOL existAutoPlay = NO;
    VMSBasicSetting *basicSetting = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
    if ((basicSetting.options & VMS_AUTO_FULLSCREEN) && existAutoPlay) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
                           [self toggleFullScreenMode:nil];
                       });
    }
}

- (void)removeAllDevice
{
    NSArray *devices = [[VMSDatabase sharedVMSDatabase] fetchDevices];
    //通知数据库，移除所有设备信息记录
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    [db deleteAllFromEntity:@"t_group"];
    [db deleteAllFromEntity:@"t_device"];
    
    for (CDevice *device in devices) {
        [[DispatchCenter sharedDispatchCenter] logoutDevice:device needReset:YES];
    }
    //广播消息
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    
    [userInfo setValue:[NSNumber numberWithUnsignedInteger:VMS_DISCARD] forKey:NOTIFI_KEY_DB_OP];
    [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_CHANGED_NOTIFICATION
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)removeDevice :(CDevice *)device
{
    if (device) {
        if ([[VMSDatabase sharedVMSDatabase] deleteDevice:device]) {
            [[DispatchCenter sharedDispatchCenter] logoutDevice:device needReset:YES];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:VMS_DEVICE_REMOVE], NOTIFI_KEY_DB_OP,device,NOTIFI_KEY_DEVICE,nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_CHANGED_NOTIFICATION
                                                                object:self
                                                              userInfo:userInfo];
        }
    }
}

#pragma mark - life cycle
- (void)dealloc
{
    [self.audioGrabber stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[DispatchCenter sharedDispatchCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    //由于这个MVC是重nib文件中加载的，该该nib文件可能归档在其它nib文件中，因此嵌入的nib文件
    //将会加载多次,这里对这一情况做一次预防.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
        //由于该xib文件有view-based outlineview/tableview ，这将引起多次调用awakeFromNib
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleVideoViewToolbarBtnStateChange:)
                                                     name:VIDEO_VIEW_TOOLBAR_STATE_CHANGE_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDatabaseChanged:)
                                                     name:DATABASE_CHANGED_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDispatchCenterNotification:)
                                                     name:CONNECTION_STATE_DID_CHANGE_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDispatchCenterNotification:)
                                                     name:DEVICE_ONLINE_STATE_DID_CHANGE_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBasicSettingDidChangeNotification:)
                                                     name:BASIC_SETTING_DID_CHANGE_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDispatchCenterNotification:)
                                                     name:DEVICE_CRUISE_MAP_DID_CHANGE_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDispatchCenterNotification:)
                                                     name:DEVICE_RELOAD_NOTIFICATION
                                                   object:nil];
        [[DispatchCenter sharedDispatchCenter] addObserver:self];
    });
}

- (void)onViewLoad
{
    [self setupSplitView];
    [self setupPTZ];
    [self setupMultyVideoViewsManager];
    [self.outlineView setDoubleAction:@selector(doubleClick:)];
    [self.outlineView expandItem:nil expandChildren:YES];
    [self setupLayout];
    [self.onLineTestTimer fire];
}

- (void)loadView
{
    [super loadView];
    
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) {
        [self onViewLoad];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self onViewLoad];
}



- (void)setupMultyVideoViewsManager
{
    //We should keep the jfSplitview's size same as placeholder
    //add auto layout constraint for it
    NSView *view = self.multyVideoViewsManager.view;
    [self.placeHolder1 addSubview:view];
    
    NSLayoutAttribute layoutAttributes[4] = {
        NSLayoutAttributeTop,
        NSLayoutAttributeLeading,
        NSLayoutAttributeBottom,
        NSLayoutAttributeTrailing
    };
    
    NSView *superView = [view superview];
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    for (int i = 0; i < 4; i++) {
        NSLayoutAttribute layoutAttribute = layoutAttributes[i];
        NSLayoutConstraint *constraint =
        [NSLayoutConstraint constraintWithItem:view
                                     attribute:layoutAttribute
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:superView
                                     attribute:layoutAttribute
                                    multiplier:1.0
                                      constant:0.0];
        [superView addConstraint:constraint];
    }
    
    [superView updateConstraints];
}

- (void)setupLayout
{
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    VMSBasicSetting *basicSetting = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
    int wndStreamType = basicSetting.wndStreamType;
    VMS_OPTION options = basicSetting.options;
    
    [manager setWndStreamTypeOption:wndStreamType];
    if (options & VMS_SAVE_LAYOUT) {
        [self unArchive];
    }
}

- (void)setupPTZ
{
    NSColor *titleColor = [NSColor colorWithCalibratedRed:0/255.0 green:51/255.0 blue:92/255.0 alpha:1];
    [self.presetAddBT setTitleColor:titleColor];
    [self.presetDelete setTitleColor:titleColor];
    [self.presetRun setTitleColor:titleColor];
    [self.patrolSetting setTitleColor:titleColor];
    [self.cruiseStartBT setTitleColor:titleColor];
    [self.cruiseStopBT setTitleColor:titleColor];
    [self.ptzToggle.cell setHighlightsBy:NSNoCellMask];
    [self hidePtz];
}

- (void)setupSplitView
{
    [self.splitview setCanCollapse:YES subviewAtIndex:1];
}


#pragma mark - Action & observe & event
- (void)refetch
{
    //重载通道、设备、信息参数
    [self setOutlineViewContents:nil];
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (void)handleDatabaseChanged :(NSNotification *)aNotific
{
    //数据库发生了改变,应该做些什么呢?
    NSDictionary    *userInfo   = aNotific.userInfo;
    VMS_DATABASE_OP op          = [[userInfo valueForKey:NOTIFI_KEY_DB_OP] unsignedIntegerValue];
    CDevice         *device     = [userInfo valueForKey:NOTIFI_KEY_DEVICE];
    
    switch (op) {
        case VMS_DEVICE_ADD: {
            //标记为自动播放
            for (Channel *ch in device.children){
                NSString *cKey = [NSString stringWithFormat:@"G-1_C%d",ch.uniqueId];
                ChannelState *cState = [[ChannelState alloc] init];
                cState.autoPlay = YES;
                
                [self.preViewMap setValue:cState forKey:cKey];
            }
            [self refetch];
            
            //在列表中查找ID相同的设备，并测试是否在线
            CDevice *newDevice = nil;
            [self findDevice:&newDevice withId:device.uniqueId inTree:[self.outlineViewContents firstObject]];
            [self testOnlineWithItem:newDevice];
        }
            break;
            
        case VMS_DEVICE_REMOVE: {
            NSString *dKey = [NSString stringWithFormat:@"D%d",device.uniqueId];
            [self.deviceMap setValue:nil forKey:dKey];
            
            MultyVideoViewsManager *manager = self.multyVideoViewsManager;
            for (Channel *c in device.children) {
                NSString *key = [NSString stringWithFormat:@"G-1_C%d",c.uniqueId];
                ChannelState *cState = [self.preViewMap valueForKey:key];
                
                [manager setView:cState.viewId group:nil channel:nil];
            }
            [self refetch];
        }
            break;
            
        case VMS_DEVICE_UPDATE:
            [self refetch];
            break;
            
        case VMS_SHEDULE_RECORD_UPDATE:
            return;
            
        case VMS_DISCARD:
            [self.multyVideoViewsManager stopAcceptAll];
            self.deviceMap = nil;
            self.preViewMap = nil;
            [self refetch];
            break;
            
        default:
            break;
    }
}

//追踪记录窗口中通道状态
- (void)handleVideoViewToolbarBtnStateChange :(NSNotification *)aNotific
{
    id              sender      = aNotific.object;
    NSDictionary    *userInfo   = aNotific.userInfo;
    VVTB_CMD        cmd         = [[userInfo valueForKey:KEY_VIDEO_VIEW_TOOLBAR_CMD] unsignedIntegerValue];
    
    if ([sender isKindOfClass:[VideoViewController class]]) {
        VideoViewController *vvc = sender;
        TreeNode *previewObj = nil;
        
        [self findPreviewObj:&previewObj withViewId:vvc.viewId inTree:[self.outlineViewContents firstObject]];
        
        switch (cmd) {
            case VVTB_CLOSE:
                [self performStop:previewObj];
                break;
            default:
            break;
        }
    }
}

//Outline view row double click action
- (void)doubleClick :(id)sender
{
    NSInteger row = [self.outlineView clickedRow];
    id obj = [self.outlineView itemAtRow:row];
    
    if ([obj isKindOfClass:[CDevice class]]) {
        CDevice *device = (CDevice *)obj;
        switch (device.type) {
            case IPC:
                obj = [device.children firstObject];
                break;
            default:
                break;
        }
    }

    [self performBeginPreviewWithItem:obj viewId:-1];
}


- (void)onlineTestingAction :(NSTimer *)timer
{
    //Excute query device state task
    TreeNode*           root                = [self.outlineView itemAtRow :0];
    SEL                 aSelector           = @selector(testOnlineWithItem:);
    NSMethodSignature   *methodSignature    = [self methodSignatureForSelector:aSelector];
    NSInvocation        *invocation         = [NSInvocation invocationWithMethodSignature:methodSignature];
    
    [invocation setTarget:self];
    [invocation setSelector:aSelector];
    [invocation setArgument:&root atIndex:2];
    [self walkThroughTree:root withInvocation:invocation];
    
    if (self.scanInterver < 300.0)
        self.scanInterver *= 2;
    
    self.onLineTestTimer = [NSTimer scheduledTimerWithTimeInterval:self.scanInterver
                                                            target:self
                                                          selector:@selector(onlineTestingAction:)
                                                          userInfo:nil
                                                           repeats:NO];
}

//窗口轮巡事件
- (void)pollingAction :(NSTimer *)timer
{
    //开启本次轮巡事件
    Group           *g      = timer.userInfo;
    NSString        *gKey   = [NSString stringWithFormat:@"G%d",g.uniqueId];
    PollingState    *gState = [self.preViewMap valueForKey:gKey];
    NSArray         *polls  = [g children];
    
    if (gState.isPlay) {
        id root = [self.outlineViewContents firstObject];
        MultyVideoViewsManager  *manager    = self.multyVideoViewsManager;
        
        int curPollIndex = gState.sequenceNum;
        for (int i = 0; i < polls.count; i++) {
            gState.sequenceNum = (curPollIndex + i + 1) % polls.count;
            //获取到这一轮训通道
            Poll    *poll = polls[gState.sequenceNum];
            Channel *c = nil;
            [self findChannel:&c withId:poll.channelId inTree:root];
            
            if (c) {
                NSString        *cKey       = [NSString stringWithFormat:@"%@_C%d",gKey,poll.channelId];
                ChannelState    *cState     = [self.preViewMap valueForKey:cKey];
                
        
                [manager setView:gState.viewId group:g channel:c];
                [self updateViewState:gState.viewId withChannelState:cState];
                
                gState.timer =  [NSTimer scheduledTimerWithTimeInterval:poll.waitSec
                                                                 target:self
                                                               selector:@selector(pollingAction:)
                                                               userInfo:g
                                                                repeats:NO];
                
                break;
            }
        }
    }
}

- (void)pagePollingAction :(NSTimer *)timer
{
    [self.multyVideoViewsManager pageDown];
    //开启下一次轮巡等待
    self.pagePollingTimer = [NSTimer scheduledTimerWithTimeInterval :self.pagePollingInterval
                                                             target :self
                                                           selector :@selector(pagePollingAction:)
                                                           userInfo :nil
                                                            repeats :NO];
}

- (IBAction)togglePTZ :(NSButton *)sender
{
    [self.splitview collapseOrExpandSubviewAtIndex:1 animated:NO];
    [self setCollapsed:!self.collapsed];
}

- (NSString *)errMsg :(int)code
{
    switch (code) {
        case -1:
            return NSLocalizedString(@"Failed", nil);
        
        case 1:
            return NSLocalizedString(@"preset point does not exist", nil);
            
        case 2:
            return NSLocalizedString(@"parameter error", nil);
            
        case 3:
            return NSLocalizedString(@"has been set to boot preset point", nil);
            
        case 4:
            return NSLocalizedString(@"preset point already exists in cruise path", nil);

        default:
            return NSLocalizedString(@"unknow error", nil);
    }
}

- (void)postPresetActionWithTag :(int)tag command :(PTZ_CMD *)cmd result :(int)code
{
    if (0 == code) {
        switch (tag) {
            case 0:
                [self.presetPointListBtn addItemWithTitle:[NSString stringWithCString:cmd->param5
                                                                             encoding:NSASCIIStringEncoding]];
                break;
            case 1:
                [self.presetPointListBtn removeItemWithTitle:[NSString stringWithCString:cmd->param5
                                                                                encoding:NSASCIIStringEncoding]];
                break;
            default:
                break;
        }
        
        return;
    }
    
    //alert
    NSAlert *alert = [[NSAlert alloc] init];
    
    alert.messageText = [self errMsg:code];
    alert.informativeText = @"";
    
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}

- (void)closeSheetController
{
    [self.sheetController close];
    [self setSheetController:nil];
}

- (IBAction)presetAction :(id)sender
{
    NSButton *btn = (NSButton *)sender;
    [btn setEnabled:NO];
    
    //获取选中的通道号
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    NSInteger       idx = [self.presetPointListBtn indexOfSelectedItem];
    int             chnId = [manager selectedChannelId];
    Channel         *c = nil;
    unsigned int    tag = (unsigned int)[sender tag];
    
    [self findChannel:&c withId:chnId inTree:[self.outlineView itemAtRow :0]];
    //预制点名称
    if (idx >= 0 && c && tag < 3) {
        PTZ_CMD cmd;
        char tmp[FOS_MAX_PRESETPOINT_NAME_LEN];
        int ptzCmds[] = {FOSCAM_IPC_PTZ_CMD_ADD_PRESET,FOSCAM_IPC_PTZ_CMD_CLEAR_PRESET,FOSCAM_IPC_PTZ_CMD_GOTO_RRESET};
        
        cmd.param1 = (int)idx + 1;
        cmd.param2 = 0;
        cmd.param3 = 0;
        cmd.param4 = 0;
        cmd.param5 = tmp;
        cmd.ptzCmd = ptzCmds[tag];
        
        if (0 == tag) {
            AddPresetWindowController *apwc = [[AddPresetWindowController alloc] initWithWindowNibName:@"AddPresetWindowController"];
            self.sheetController = apwc;//这里需要使用strong属性，引用改controller,直到关闭
            
            [apwc.window center];
            switch ([NSApp runModalForWindow:apwc.window]) {
                case NSModalResponseCancel:
                    [self closeSheetController];
                    [btn setEnabled:YES];
                    
                    return;
                
                case NSModalResponseOK:
                    [apwc.presetPointName getCString:cmd.param5 maxLength:FOS_MAX_PRESETPOINT_NAME_LEN encoding:NSASCIIStringEncoding];
                    [self closeSheetController];
                    
                    break;
                    
                default:
                    break;
            }
        }
        else {
            [self.presetPointListBtn.titleOfSelectedItem getCString:cmd.param5 maxLength:64 encoding:NSASCIIStringEncoding];
        }
       
        int result = [[DispatchCenter sharedDispatchCenter] sendPTZControlCommand:cmd toDevice:c.device channel:c.logicId];
        [self postPresetActionWithTag:(int)[sender tag] command:&cmd result:result];
    }
    
    [btn setEnabled:YES];
}

- (IBAction)cruiseAction:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    [btn setEnabled:NO];
    
    //获取选中的通道号
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    NSInteger       idx     = [self.cruiseMapListBtn indexOfSelectedItem];
    int             chnId   = [manager selectedChannelId];
    Channel         *c      = nil;
    unsigned int    tag     = (unsigned int)[sender tag];
    
    [self findChannel:&c withId:chnId inTree:[self.outlineView itemAtRow :0]];
    
    if (idx >= 0 && c && tag < 2) {
        PTZ_CMD cmd;
        unsigned int ptzCmds[] = {FOSCAM_IPC_PTZ_CMD_START_PATTERN,FOSCAM_IPC_PTZ_CMD_STOP_PATTERN};
        char tmp[FOS_MAX_CURISEMAP_NAME_LEN];
        
        cmd.param1 = 0;
        cmd.param2 = 0;
        cmd.param3 = 0;
        cmd.param4 = 0;
        cmd.param5 = tmp;
        cmd.ptzCmd = ptzCmds[tag];
        
        [self.cruiseMapListBtn.titleOfSelectedItem getCString:cmd.param5
                                                    maxLength:FOS_MAX_CURISEMAP_NAME_LEN
                                                     encoding:NSASCIIStringEncoding];
        
        [[DispatchCenter sharedDispatchCenter] sendPTZControlCommand:cmd
                                                            toDevice:c.device
                                                             channel:c.logicId];
    }
    [btn setEnabled:YES];
}

/*- (void)beginAddingPresetPoint
{
    [self.presetPointListBtn setHidden:YES];
    [self.presetDelete setHidden:YES];
    [self.presetAddBT setTitle:@"确定"];
    [self.presetRun setTitle:@"取消"];
    [self.presetNameTF setHidden:NO];
    [self.presetNameTF setStringValue:@""];
}

- (void)endAddingPresetPoint
{
    [self.presetNameTF setHidden:YES];
    [self.presetDelete setHidden:NO];
    [self.presetAddBT setTitle:@"添加"];
    [self.presetRun setTitle:@"运行"];
    [self.presetPointListBtn setHidden:NO];
}*/

- (IBAction)turnPage :(id)sender
{
    switch ([sender tag]) {
        case 0:
            [self.multyVideoViewsManager pageUp];
            break;
        case 1:
            [self.multyVideoViewsManager pageDown];
            break;
    }
}

- (IBAction)toggleFullScreenMode :(id)sender
{
    [self.multyVideoViewsManager toggleFullScreenMode];
}

- (IBAction)closeAll :(id)sender
{
    [self stopPreviewAll];
}

- (IBAction)togglePageSize :(id)sender
{
    [self.multyVideoViewsManager setPageSize :(int)[sender tag]];
}

- (IBAction)pagePolling :(id)sender
{
    BOOL state = [sender state];
    switch (state) {
        case NSOnState:
            self.pagePollingTimer =
            [NSTimer scheduledTimerWithTimeInterval :self.pagePollingInterval
                                             target :self
                                           selector :@selector(pagePollingAction:)
                                           userInfo :nil
                                            repeats :NO];
            break;
        case NSOffState:
            [self.pagePollingTimer invalidate];
            [self setPagePollingTimer :nil];
            break;
        default:
            break;
    }
}

- (IBAction)outlineViewContextMenuAction:(NSMenuItem *)item
{
    id treeItem = [self selectedItemOfOultineView:self.outlineView];

    switch ([item tag]) {
        case 0://Add Device
            [(AppDelegate *)[[NSApplication sharedApplication] delegate] addDevice:self];
            break;
        case 1: //Add group
            [self performSetGroup:[[Group alloc] initWithUniqueId:-1
                                                             name:NSLocalizedString(@"New Group", nil)
                                                             type:NORMAL_GROUP
                                                           remark:@""]];
            break;
        case 2://New Polling Group
            [self performSetPollingGroup:[[Group alloc] initWithUniqueId:-1
                                                                    name:NSLocalizedString(@"New Group", nil)
                                                                    type:PATROL_GROUP
                                                                  remark:@""]];
            break;
        case 3:
            //全部开始
            [self previewAll];
            break;
        case 4://全部停止
            [self stopPreviewAll];
            break;
        case 5: {//移除全部
            NSAlert *alert = [[NSAlert alloc] init];
            
            alert.messageText = NSLocalizedString(@"Are you sure you want to remove all devices?", nil);
            alert.alertStyle = NSAlertStyleWarning;
            
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            
            if (NSAlertSecondButtonReturn == [alert runModal])
                [self removeAllDevice];
        }
            break;
        case 6://组设置
            [self performSetGroup :(Group *)treeItem];
            break;
        case 7://取消分组
            [self performCancelGroup :(Group *)treeItem];
            break;
        case 8: {
            //轮巡/停止轮巡
            Group *group = (Group *)treeItem ;
            if (item.state)
                [self performStopPolling:group];
            else
                [self performBeginPolling :group withViewId:-1];
        }
            break;
        case 9://轮巡设置
            [self performSetPollingGroup :(Group *)treeItem];
            break;
        case 10://取消轮巡组
            [self performCancelGroup:(Group *)treeItem];
            break;
        case 11: {
            //预览/停止预览
            //如果结点是设备，取其第一通道
            Channel *c = nil;
            if ([treeItem isKindOfClass:[CDevice class]])
                c = [[(CDevice *)treeItem children] objectAtIndex:0];
            else if ([treeItem isKindOfClass:[Channel class]])
                c = (Channel *)treeItem;
        
            if (item.state)
                [self performStopPreview:c];
            else
                [self performBeginPreview:c withViewId:-1];
        }
            break;
        case 12://设备参数设置
            [self performConfigSetting :treeItem];
            break;
        case 13://设备连接设置
            [self performConnectionSetting :treeItem];
            break;
        case 14: {//移除设备
            NSAlert *alert = [[NSAlert alloc] init];
            
            alert.messageText = NSLocalizedString(@"Are you sure you want to remove the device?", nil);
            alert.alertStyle = NSAlertStyleWarning;
            
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            
            if (NSAlertSecondButtonReturn == [alert runModal])
                [self removeDevice:treeItem];
        }
            break;
        default:
            break;
    }
}

- (IBAction)videoViewContextMenuAction :(id)sender
{
    NSInteger tag = [sender tag];
    switch (tag) {
        case 0 :
            [self.multyVideoViewsManager setHideToolbar :![sender state]];
            break;
            
        case 2 :
            [self toggleFullScreenMode :sender];
            break;
            
        case 3 : {
            //关闭选中窗口对应通道
            id obj = [self.multyVideoViewsManager selectedObj];
            assert(obj != nil);
            [self performStop:obj];
        }
            break;
            
        case 4: {
            
            int     vId = self.multyVideoViewsManager.selectedViewId;
            Channel *c = [self.multyVideoViewsManager channelWithViewId:vId];
            
            assert(c != nil);
            Channel *ch;
            [self findChannel:&ch withId:c.uniqueId inTree:[self.outlineViewContents firstObject]];
            [self performConfigSetting:ch.device];
        }
            break;
        default:
            break;
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    VMS_LOCKED_ALERT;
    [super mouseDown:theEvent];
}


#pragma mark - private method
- (void)performCancelGroup :(Group *)group
{
    if (!group) return;
    
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    switch (group.type) {
        case PATROL_GROUP: {
            NSString        *gKey    = [NSString stringWithFormat:@"G%d",group.uniqueId];
            PollingState    *gState  = [self.preViewMap valueForKey:gKey];
            NSAlert         *alert   = [[NSAlert alloc] init];
            
            alert.messageText = NSLocalizedString(@"Are you sure you want to cancel the group?", nil);
            alert.alertStyle = NSAlertStyleWarning;
            
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            
            if (NSAlertSecondButtonReturn == [alert runModal]) {
                if (gState.isPlay)
                    [self performStopPolling:group];
                
                //数据库移除纪录
                [db cancelGroup :group];
                [self refetch];
            }
        }
            break;
            
        case NORMAL_GROUP:
            [db cancelGroup:group];
            [self refetch];
            break;
        default:
            break;
    }
}

- (void)performSetPollingGroup :(Group *)group
{
    if (!group)
        return;
    
    if (!self.settingController) {
        AddPollingGroupSheetController *apgsc =
        [[AddPollingGroupSheetController alloc] initWithWindowNibName :NIB_ADD_POLLING_GROUP_SHEET];
        [apgsc setGroup :group];
        [self setSettingController :apgsc];//Hold住
        
        if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
            [[NSApplication sharedApplication] beginSheet:self.settingController.window
                                           modalForWindow:self.view.window
                                            modalDelegate:self
                                           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                                              contextInfo:NULL];
        else {
            [self.view.window beginSheet :apgsc.window
                       completionHandler :^(NSModalResponse returnCode) {
                           [self didEndSheet:apgsc.window
                                  returnCode:returnCode
                                 contextInfo:NULL];
                       }];
        }
    }
}

- (void)performSetGroup :(Group *)group
{
    if (!group)
        return;
    
    if (!self.settingController) {
        AddDeviceGroupSheetController *adgsc =
        [[AddDeviceGroupSheetController alloc] initWithWindowNibName :NIB_ADD_DEVICE_GROUP_SHEET];
        adgsc.group = group;
        self.settingController = adgsc;

        if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
            [[NSApplication sharedApplication] beginSheet:self.settingController.window
                                           modalForWindow:self.view.window
                                            modalDelegate:self
                                           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                                              contextInfo:(void *)group];
        else
            [self.view.window beginSheet:adgsc.window
                       completionHandler:^(NSModalResponse returnCode) {
                           [self didEndSheet:adgsc.window returnCode:returnCode contextInfo:(void *)group];
                       }];
        
    }
}

//通道连接成功之后的回调
- (void)onConnectedStateChangeWithViewId :(int)vId
{
    //更新PTZUI
    if (vId == self.multyVideoViewsManager.selectedViewId) {
        [self updatePtzUI];
    }
}

#pragma mark - Begin && Stop Preview
- (void)updateViewState :(int)vId withChannelState :(ChannelState *)cState
{
    if (cState && cState.viewId == vId) {
        VIDEO_STATE vState = NO_VIDEO;
        
        if (vId >= 0 && cState.isPlay) {
            FOSSTREAM_TYPE streamType = [self.multyVideoViewsManager streamTypeOfViewId:vId];
            
            if (cState.connected & (1 << streamType)) {
                vState = cState.isOnline? VIDEO_PLAYING : DISCONNECTED;
            }
            else if (cState.connectings & (1 << streamType)) {
                vState = CONNECTING;
            }
            else {
                vState = CONNECT_FAILED;
            }
        }
        
        [self.multyVideoViewsManager setView:vId state:vState];
    }
}

//预览通道
- (void)performPreview:(Channel *)c withViewId :(int)vId groupId :(long)gId
{
    NSString        *cKey   = [NSString stringWithFormat:@"G%ld_C%d",gId,c.uniqueId];
    ChannelState    *cState = [self.preViewMap valueForKey:cKey];
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    FOSSTREAM_TYPE streamType = [manager streamTypeOfViewId:vId];
    
    if (vId >= 0 && cState != nil) {
        cState.viewId = vId;
        cState.autoPlay = NO;
        
        [self updateViewState:vId withChannelState:cState];
        if (cState.isOnline) {
            if (!(cState.connected & (1 << streamType))) {
                //标记为连接中
                cState.connectings |= (1 << streamType);
                
                //向中心发起请求
                [self updateViewState:vId withChannelState:cState];
                [[DispatchCenter sharedDispatchCenter] startRealTimeVideoFromDevice:c.device
                                                                            channel:c.logicId
                                                                         streamType:streamType
                                                                              queue:dispatch_get_main_queue()
                                                               withCompletionHandle:^(BOOL success)
                 {
                     //取消连接中
                     cState.connectings &= ~(1 << streamType);
                     
                     //查看是否有取消请求
                     PREVIEW_CANCEL_CNT cancelCnt = cState.cancelCtn;
                     if (cancelCnt.cnt[streamType] > 0) {
                         cancelCnt.cnt[streamType] = cancelCnt.cnt[streamType] -1;
                         cState.cancelCtn = cancelCnt;
                         
                         if (success) {
                             [[DispatchCenter sharedDispatchCenter] stopRealTimeVideoFromDevice:c.device
                                                                                        channel:c.logicId
                                                                                     streamType:streamType];
                         }
                     }
                     else {
                         if (success) {
                             //登记
                             cState.connected |= (1 << streamType);
                             [self onConnectedStateChangeWithViewId:vId];
                         }
                         else {
                             cState.autoPlay = YES;
                         }
                     }
                     
                     [self updateViewState:vId withChannelState:cState];
                 }];
            }
        }
        else {
            //设备不在线，或者断线中，标记为在线后重新打开
            cState.autoPlay = YES;
        }
    }
}


//预览组
- (BOOL)performPreviewGroup :(Group *)g withViewId:(int)vId
{
    NSString        *gKey    = [NSString stringWithFormat:@"G%d",g.uniqueId];
    PollingState    *gState  = [self.preViewMap valueForKey:gKey];
    NSArray         *polls = g.children;
    MultyVideoViewsManager  *manager = self.multyVideoViewsManager;
    int viewId = (vId < 0)? [manager freeViewId] : vId;
    
    if ((viewId >= 0) && polls.count > 0) {
        gState.autoPlay = NO;
        gState.viewId = viewId;
        gState.sequenceNum = (0 + 1) % polls.count;
        gState.play = YES;
        
        for (Poll *poll in g.children) {
            NSString *cKey = [NSString stringWithFormat:@"G%d_C%d",g.uniqueId,poll.channelId];
            ChannelState *cState = [self.preViewMap valueForKey:cKey];
            
            cState.play = YES;
        }
        //开启轮巡
        [gState.timer invalidate];
        gState.timer = [NSTimer scheduledTimerWithTimeInterval:[[polls firstObject] waitSec]
                                                        target:self
                                                      selector:@selector(pollingAction:)
                                                      userInfo:g
                                                       repeats:NO];
        
        [manager setView:viewId group:g channel:nil];
        [gState.timer fire];
        
        return YES;
    }
    
    return NO;
}

//反预览
- (void)performUnPreView :(Channel *)channel groupId :(long)gId
{
    NSString        *cKey           = [NSString stringWithFormat:@"G%ld_C%d",gId,channel.uniqueId];
    ChannelState    *cState         = [self.preViewMap valueForKey:cKey];
    FOSSTREAM_TYPE  streamTypes[2]  = {FOSSTREAM_MAIN,FOSSTREAM_SUB};
    
    //通知中心，取消实时
    for (int i =0; i < 2; i++) {
        FOSSTREAM_TYPE streamType = streamTypes[i];
        
        if (cState.connectings & (1 << streamType)) {
            //取消
            PREVIEW_CANCEL_CNT cancelCnt = cState.cancelCtn;
            cancelCnt.cnt[streamType] = cancelCnt.cnt[streamType] + 1;
            cState.cancelCtn = cancelCnt;
        } else if (cState.connected & (1 << streamType)) {
            //结束
            [[DispatchCenter sharedDispatchCenter] stopRealTimeVideoFromDevice:channel.device
                                                                       channel:channel.logicId
                                                                    streamType:streamType];
        }
    }
    
    //通知界面更改状态
    cState.connectings = 0;
    cState.connected = 0;
    cState.autoPlay = NO;
    cState.viewId = -1;
    cState.play = NO;
    
    [self onConnectedStateChangeWithViewId:cState.viewId];
}

//预览对象(可以是通道或者轮巡组)
- (void)performPreview :(id)obj viewId :(int)vId
{
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    
    if ([obj isKindOfClass:[Channel class]]) {
        [manager setView:vId group:nil channel:obj];
        [self performPreview:obj withViewId:vId groupId:-1];
    }
    else if ([obj isKindOfClass:[Group class]]){
        Group *g = obj;
        if ([self performPreviewGroup:g withViewId:vId]) {
            for (Poll *p in g.children) {
                Channel *c = nil;
                
                [self findChannel:&c withId:p.channelId inTree:[self.outlineViewContents firstObject]];
                [self performPreview:c withViewId:vId groupId:g.uniqueId];
            }
        }
    }
}

//恢复预览对象(可以是通道或者轮询组)
- (void)performRestorePreviewWithItem :(TreeNode *)item
{
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    
    if ([item isKindOfClass:[Channel class]]) {
        Channel         *c = (Channel *)item;
        NSString        *cKey = [NSString stringWithFormat:@"G-1_C%d",c.uniqueId];
        ChannelState    *cState = [self.preViewMap valueForKey:cKey];
        
        if (cState.isPlay && cState.viewId >= 0) {
            [manager setView:cState.viewId group:nil channel:c];
            [self performPreview:c withViewId:cState.viewId groupId:-1];
        }
    }
    else if ([item isKindOfClass:[Group class]]) {
        Group           *g = (Group *)item;
        NSString        *gKey    = [NSString stringWithFormat:@"G%d",g.uniqueId];
        PollingState    *gState  = [self.preViewMap valueForKey:gKey];
        
        if (gState.isPlay && gState.viewId >= 0) {
            //恢复轮询
            if ([self performPreviewGroup:g withViewId:gState.viewId]) {
                for (Poll *poll in g.children) {
                    Channel *c = nil;
                    
                    [self findChannel:&c withId:poll.channelId inTree:[self.outlineViewContents firstObject]];
                    [self performPreview:c withViewId:gState.viewId groupId:g.uniqueId];
                }
            }
            else {
                gState.play = NO;
                gState.viewId = -1;
            }
        }
    }
}

//开始预览对象(可以是通道或者轮巡组)
- (void)performBeginPreviewWithItem :(TreeNode *) item viewId :(int)vId
{
    if ([item isKindOfClass:[Channel class]])
        [self performBeginPreview:(Channel *)item withViewId:vId];
    else if ([item isKindOfClass:[Group class]]) {
        Group *group = (Group *)item;
        if (group.type == PATROL_GROUP)
            [self performBeginPolling :group withViewId:vId];
    }
}

//开始预览
- (void)performBeginPreview :(Channel *)c withViewId :(int)viewId
{
    NSString        *cKey   = [NSString stringWithFormat:@"G-1_C%d",c.uniqueId];
    ChannelState    *cState = [self.preViewMap valueForKey:cKey];
    
    if (cState.isOnline) {
        if (!cState.isPlay) {
            MultyVideoViewsManager *manager = self.multyVideoViewsManager;
            
            if (viewId < 0) {
                viewId = [manager freeViewId];
            }
            
            if (viewId >= 0) {
                cState.viewId = viewId;
                cState.play = YES;
                
                [manager setView:viewId group:nil channel:c];
                [self performPreview:c withViewId:viewId groupId:-1];
            }
        }
    }
}

//结束预览
- (void)performStopPreview :(Channel *)c
{
    NSString        *cKey   = [NSString stringWithFormat:@"G-1_C%d",c.uniqueId];
    ChannelState    *cState = [self.preViewMap valueForKey:cKey];
    
    if (cState.isPlay) {
        int vId = cState.viewId;
        assert(vId >= 0);
        
        [self performUnPreView:c groupId:-1];
        [self.multyVideoViewsManager setView:vId group:nil channel:nil];
    }
}

//开始预览组
- (BOOL)performBeginPreviewGroup :(Group *)g withViewId:(int)viewId
{
    NSString                *gKey    = [NSString stringWithFormat:@"G%d",g.uniqueId];
    PollingState            *gState  = [self.preViewMap valueForKey:gKey];

    return gState.isPlay? NO : [self performPreviewGroup:g withViewId:viewId];
}

//开始轮巡
- (void)performBeginPolling :(Group *)g withViewId :(int)viewId
{
    if ([self performBeginPreviewGroup:g withViewId:viewId]) {
        NSString        *gKey = [NSString stringWithFormat:@"G%d",g.uniqueId];
        PollingState    *gState = [self.preViewMap valueForKey:gKey];
        NSArray         *polls = [g children];
        TreeNode        *root = [self.outlineView itemAtRow :0];
        
        for (Poll *poll in polls) {
            Channel *c;
            
            [self findChannel:&c withId:[poll channelId] inTree :root];
            [self performPreview:c withViewId:gState.viewId groupId:g.uniqueId];
        }
    }
}

//停止轮巡
- (void)performStopPolling :(Group *)g
{
    NSString        *gKey = [NSString stringWithFormat:@"G%d",g.uniqueId];
    PollingState    *gState = [self.preViewMap valueForKey:gKey];
    
    if (gState.isPlay) {
        assert(gState.viewId >= 0);
        
        NSArray *polls = g.children;
        TreeNode *root = [self.outlineView itemAtRow :0];
        
        for (Poll *poll in polls) {
            Channel *c;
            [self findChannel:&c withId:poll.channelId inTree:root];
            [self performUnPreView:c groupId:g.uniqueId];
        }

        [gState.timer invalidate];
        [self.multyVideoViewsManager setView:gState.viewId group:nil channel:nil];
        
        gState.timer = nil;
        gState.play = NO;
        gState.viewId = -1;
    }
}

//停止
- (void)performStop :(id)obj
{
    if ([obj isKindOfClass:[Group class]]) {
        Group *g = obj;
        if (g.type == PATROL_GROUP) {
            [self performStopPolling :g];
        }
    }
    else if ([obj isKindOfClass:[Channel class]]) {
        [self performStopPreview:obj];
    }
}

#pragma mark - Connection && Config Setting
- (void)performConnectionSetting :(CDevice *)device
{
    if (!device)
        return;
    
    if (!self.settingController) {
        NSString *nibFileName = @"DeviceConnectionSettingSheetController";
        DeviceConnectionSettingSheetController *dcssc =
        [[DeviceConnectionSettingSheetController alloc] initWithWindowNibName :nibFileName device :device];
        
        self.settingController = dcssc;
    
        if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
            [[NSApplication sharedApplication] beginSheet:self.settingController.window
                                           modalForWindow:self.view.window
                                            modalDelegate:self
                                           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                                              contextInfo:NULL];
        
        else
            [self.view.window beginSheet:dcssc.window
                       completionHandler:^(NSModalResponse returnCode) {
                           [self didEndSheet:dcssc.window returnCode:returnCode contextInfo:NULL];
                           
                       }];
    }
}

- (void)performConfigSetting :(CDevice *)device
{
    if (!device)
        return;
    
    if (!self.settingController) {
        DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
        //向中心发起开启配置请求
        [center beginConfigDevice:device
                            queue:dispatch_get_main_queue()
             withCompletionHandle:^(BOOL success) {
                 
                 if (success) {
                     self.settingController = [[DeviceSettingSheetController alloc] initWithWindowNibName:NIB_IPC_SETTING_SHEET device:device];
                     
                     if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9){
                         [[NSApplication sharedApplication] beginSheet:self.settingController.window
                                                        modalForWindow:self.view.window
                                                         modalDelegate:self
                                                        didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                                                           contextInfo:(void *)device];
                     }
                     else {
                         [self.view.window beginSheet:self.settingController.window
                                    completionHandler:^(NSModalResponse returnCode) {
                                        [self didEndSheet:self.settingController.window
                                               returnCode:returnCode
                                              contextInfo:NULL];
                                    }];
                     }
                 }
             }];
    }
}

#pragma mark - Walk Through The Tree
- (void)walkThroughTree :(TreeNode *)root withInvocation :(NSInvocation *)invocation
{
    [invocation setArgument:&root atIndex:2];
    [invocation invoke];
    
    if ([root respondsToSelector:@selector(children)]) {
        NSArray *children = [root children];
        for (id item in children)
            [self walkThroughTree:item withInvocation:invocation];
    }
}

#pragma mark - Find Node In Tree
- (void)findDevice :(CDevice **)device withId :(int)uniqueId inTree :(TreeNode *)root
{
    if ([root isKindOfClass:[CDevice class]] && ([root uniqueId] == uniqueId))
        *device = (CDevice *)root;
    else if ([root respondsToSelector:@selector(children)]) {
        NSArray *children = [root children];
        for (id item in children)
            [self findDevice:device withId:uniqueId inTree:item];
    }
}

- (void)findChannel :(Channel **)channel withId :(int)uniqueId inTree :(TreeNode *)root
{
    if ([root isKindOfClass:[Channel class]] && ([root uniqueId] == uniqueId))
        *channel = (Channel *)root;
    else if ([root respondsToSelector:@selector(children)]) {
        NSArray *children = [root children];
        for (id item in children)
            [self findChannel :channel withId:uniqueId inTree :item];
    }
}

- (void)findPreviewObj :(id *)obj withViewId :(int)viewId inTree :(TreeNode *)tree
{
    if (viewId >= 0) {
        NSDictionary *map = self.preViewMap;
        NSString *key;
        
        if ([tree isKindOfClass:[Channel class]])
            key = [NSString stringWithFormat:@"G-1_C%d",[(Channel *)tree uniqueId]];
        else if ([tree isKindOfClass:[Group class]])
            key = [NSString stringWithFormat:@"G%d",[(Group *)tree uniqueId]];
        PreviewObjState *state = [map valueForKey:key];
        
        if (state && state.viewId == viewId)
            *obj = tree;
        if ([tree respondsToSelector:@selector(children)]) {
            //没有找到，在它的字节点中寻找
            NSArray *children = [tree children];
            for (id item in children)
                [self findPreviewObj :obj withViewId :viewId inTree :item];
        }
    }
}

- (void)testOnlineWithItem :(TreeNode *) item
{
    if ([item isKindOfClass:[CDevice class]])
        [[DispatchCenter sharedDispatchCenter] testOnlineUseDevice:(CDevice *)item];
}

- (NSString *)identifierOfPreviewItem :(TreeNode *)item
{
    NSString *identifier = nil;
    
    if ([item isKindOfClass:[Channel class]])
        identifier = [NSString stringWithFormat:@"G-1_C%d",[item uniqueId]];
    else if ([item isKindOfClass:[Group class]]) {
        Group *group = (Group *)item;
        if (group.type == PATROL_GROUP) {
            identifier = [NSString stringWithFormat:@"G%d",group.uniqueId];
        }
    }
    
    return identifier;
}

#pragma mark - Sheet Return
- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
    NSWindowController *controller = sheet.windowController;
    
    if ([controller isKindOfClass:[AddDeviceGroupSheetController class]]) {
        AddDeviceGroupSheetController *adgsc = (AddDeviceGroupSheetController *)controller;
        Group *group = (__bridge Group *)contextInfo;
        
        if (returnCode == NSModalResponseOK) {
            //插入或者更改group
            VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
            if (group.uniqueId == -1) {
                int uniqueID = [db insertGroup:adgsc.group];
                
                if(uniqueID < 0) {
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = NSLocalizedString(@"Failed to add group", nil);
                    alert.informativeText = NSLocalizedString(@"persistent error", nil);
                    
                    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                    [alert runModal];
                }
                else
                    [group setUniqueId:uniqueID];
            } else
                [db updateGroup:adgsc.group];
            
            if (group.uniqueId >= 0) {
                //更新group外的设备
                [adgsc.groupOutDevices enumerateObjectsUsingBlock:^(id obj,NSUInteger idx,BOOL *stop) {
                    //原先在组内的设备，剔除出去的设备组设置为空
                    if ([(CDevice *)obj group].uniqueId == group.uniqueId) {
                        [(CDevice *)obj setGroup:nil];
                        [db updateDevice:obj];
                    }
                }];
                
                //更新group内的设备
                [adgsc.groupInDevices enumerateObjectsUsingBlock:^(id obj,
                                                                   NSUInteger idx,
                                                                   BOOL *stop)
                {
                     [(CDevice *)obj setGroup:group];
                     [db updateDevice:obj];
                }];
                //通知出去
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setValue:[NSNumber numberWithUnsignedInteger:VMS_DEVICE_UPDATE] forKey:NOTIFI_KEY_DB_OP];
                [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_CHANGED_NOTIFICATION
                                                                    object:nil
                                                                  userInfo:userInfo];
            }
        }
        
        [adgsc close];
        [self setSettingController:nil];
    }
    else if ([controller isKindOfClass:[AddPollingGroupSheetController class]]) {
        AddPollingGroupSheetController *apgsc = (AddPollingGroupSheetController *)controller;
        if (NSModalResponseOK == returnCode) {
            //获取输出
            Group *group = apgsc.group;
            NSArray *polls = [apgsc polls];
            //写入数据库
            VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
            //取消旧的分组，插入新分组
            [db cancelGroup :group];
            group.uniqueId = [db insertGroup:group];
            for (Poll *poll in polls) {
                poll.group = group;
                int pollId = [db insertPoll :poll];
                
                if (pollId < 0) {
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = NSLocalizedString(@"Failed to add group", nil);
                    alert.informativeText = NSLocalizedString(@"persistent error", nil);
                    
                    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                    [alert runModal];
                    break;
                }
            }
            //重载
            [self refetch];
        }
        [apgsc close];
        [self setSettingController:nil];
    }
    else if ([controller isKindOfClass:[DeviceConnectionSettingSheetController class]]) {
        DeviceConnectionSettingSheetController *dcssc = (DeviceConnectionSettingSheetController *)controller;
        CDevice *device = dcssc.device;
        
        if (returnCode == NSModalResponseOK) {
            //用户确认了修改，更新设备信息
            VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
            [db updateDevice:device];
            [db fetchChannelsWithDevice:device];
            //更新设备下通道信息
            for (Channel *channel in device.children) {
                [db updateChannelName:(device.type == IPC)? device.name : [NSString stringWithFormat:@"%@_CH%d",device.name,channel.logicId + 1]
                            uniquelId:channel.uniqueId];
            }
            //通知出去
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:VMS_DEVICE_UPDATE], NOTIFI_KEY_DB_OP,device,NOTIFI_KEY_DEVICE,nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_CHANGED_NOTIFICATION
                                                                object:nil
                                                              userInfo:userInfo];
            
            [self.onLineTestTimer fire];
        }
        [self.settingController close];
        [self setSettingController:nil];
        
    }
    else if ([controller isKindOfClass:[DeviceSettingSheetController class]]) {
        CDevice *device = (__bridge CDevice *)contextInfo;
        [[DispatchCenter sharedDispatchCenter] endConfigDevice:device];
        [self.settingController close];
        [self setSettingController:nil];
    }
}

#pragma mark - VMSTabView Delegate
- (BOOL)shouldRespondHitTestForView:(NSView *)view
{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    UserGroup   *group = [[VMSDatabase sharedVMSDatabase] fetchUserGroupWithUniqueId:[appDelegate currentUser].groupId];
    
    return !appDelegate.isAppLocked && (group.level < 2);
}

#pragma mark - Menu Delegate
typedef NS_OPTIONS(NSUInteger, OLV_Node_Type){
    OLV_None    = 0,
    OLV_Blank = 1 << 0,
    OLV_Group = 1 << 1,
    OLV_Polling = 1 << 2,
    OLV_Device = 1 << 3,
    OLV_Root = 1 << 4,
    OLV_Channel = 1 << 5,
};

- (id)selectedItemOfOultineView :(NSOutlineView *)outlineView
{
    id          selectedItem    = nil;
    NSInteger   targetRow       = [self.outlineView clickedRow];
    NSInteger   selectedRow     = [self.outlineView selectedRow];
    
    if (targetRow >= 0)
        selectedItem = [self.outlineView itemAtRow:targetRow];
    else if (selectedRow >= 0)
        selectedItem = [self.outlineView itemAtRow:selectedRow];
    else
        return nil;
    
    return selectedItem;
}

- (OLV_Node_Type)nodeTypeOfItem :(id)item
{
    OLV_Node_Type node = OLV_None;
    
    if (!item)
        node |= OLV_Blank;
    else if ([item isKindOfClass:[Channel class]])
        node |= OLV_Channel;
    else if ([item isKindOfClass:[CDevice class]])
        node |= OLV_Device;
    else if ([item isKindOfClass:[Group class]]) {
        Group *group = (Group *)item;
        switch (group.type) {
            case NORMAL_GROUP:
                node |= OLV_Group;
                break;
            case PATROL_GROUP:
                node |= OLV_Polling;
                break;
            case ROOT_GROUP:
                node |= OLV_Root;
                break;
            default:
                break;
        }
    } else {
        assert(false);
        exit(0);
    }
    
    return node;
}

- (BOOL)existItems
{
    id root  = [self.outlineViewContents firstObject];
    
    if ([root respondsToSelector:@selector(children)])
        return [root children].count > 0;
    
    return NO;
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    //在上下文菜单即将打开前，设置菜单项的隐藏属性
    if (menu == self.outlineView.menu) {
        id              selectedItem    = [self selectedItemOfOultineView:self.outlineView];
        OLV_Node_Type   nodeType = [self nodeTypeOfItem:selectedItem];
        UserGroup       *group =
        [[VMSDatabase sharedVMSDatabase] fetchUserGroupWithUniqueId:[appDelegate currentUser].groupId];
        
        for (NSMenuItem *item in menu.itemArray) {
            NSInteger tag = item.tag;
            switch (tag) {
                case 5://全部删除
                    [item setEnabled:(group.level == 0) && [self existItems]];
                    [item setHidden :!(nodeType & OLV_Root) || (nodeType & OLV_Blank)];
                    break;
                case 0://添加设备
                case 1://添加组
                case 2://添加轮巡组
                    [item setEnabled:(group.level == 0)];
                case 3://全部开始
                case 4://全部停止
                    [item setHidden :!(nodeType & OLV_Root) || (nodeType & OLV_Blank)];
                    break;
                    
                case 6://组设置
                case 7://取消分组
                    [item setEnabled:(group.level == 0)];
                    [item setHidden :!(nodeType & OLV_Group) || (nodeType & OLV_Blank)];
                    break;
                    
                case 8: {
                    //轮巡
                    NSString *gKey = [NSString stringWithFormat:@"G%d",((Group *)selectedItem).uniqueId];
                    PreviewObjState *gState = [self.preViewMap valueForKey:gKey];
                    
                    [item setState  :gState.isPlay];
                    [item setHidden :!(nodeType & OLV_Polling) || (nodeType & OLV_Blank)];
                }
                    break;
                    
                case 9: {
                    //轮巡设置
                    NSString *gKey = [NSString stringWithFormat:@"G%d",((Group *)selectedItem).uniqueId];
                    PreviewObjState *gState = [self.preViewMap valueForKey:gKey];
                    
                    [item setEnabled:(group.level == 0) && !gState.isPlay];
                    [item setHidden :!(nodeType & OLV_Polling) || (nodeType & OLV_Blank)];
                }
                    break;
                    
                case 10://取消轮巡组
                    [item setEnabled:(group.level == 0)];
                    [item setHidden :!(nodeType & OLV_Polling) || (nodeType & OLV_Blank)];
                    break;
                    
                case 11:{
                    //预览(只有通道可见)
                    BOOL bHide = YES;
                    Channel *channel = nil;
                    
                    if (nodeType & OLV_Device) {
                        CDevice *device = (CDevice *)selectedItem;
                        
                        if (device.type == IPC) {
                            channel = [device.children firstObject];
                            bHide = NO;
                        }
                    } else if (nodeType & OLV_Channel) {
                        channel = (Channel *)selectedItem;
                        bHide = NO;
                    }
                    
                    if (channel) {
                        NSString *cKey = [NSString stringWithFormat:@"G-1_C%d",channel.uniqueId];
                        PreviewObjState *cState = [self.preViewMap valueForKey:cKey];
                        
                        item.state = (cState.isPlay);
                    }
                    
                    [item setHidden :bHide || (nodeType & OLV_Blank)];
                }
                    break;
                    
                case 12: {
                    //设备参数设置
                    if (nodeType & OLV_Device) {
                        CDevice     *d = (CDevice *)selectedItem;
                        NSString    *dKey = [NSString stringWithFormat:@"D%d",d.uniqueId];
                        DeviceState *dState = [self.deviceMap valueForKey:dKey];
                        
                        [item setEnabled:dState.isOnline];
                    }
                    
                    [item setHidden :!(nodeType & OLV_Device) || (nodeType & OLV_Blank)];
                }
                    break;
                    
                case 13://设备连接设置
                case 14://移除设备
                    [item setEnabled:(group.level == 0)];
                    [item setHidden:(nodeType & OLV_Blank) || !(nodeType & OLV_Device)];
                default:
                    break;
            }
        }
    } else if (menu == self.contextMenu) {
        MultyVideoViewsManager *manager = self.multyVideoViewsManager;
        
        for (NSMenuItem *item in menu.itemArray) {
            
            switch (item.tag) {
                case 0://隐藏工具栏
                    [item setState :manager.isHideToolbar];
                    break;
                    
                case 2://全屏
                    [item setState:self.multyVideoViewsManager.isFullScreenMode];
                    break;
                    
                case 3: //关闭按钮
                    [item setEnabled: [self.multyVideoViewsManager selectedObj] != nil];
                    break;
                    
                case 4:{
                    id obj = [manager selectedObj];
                    [item setEnabled:[obj isKindOfClass:[Channel class]]];
                }
                    break;
                default:
                    break;
            }
        }
    }
}

#pragma mark - OullineView datasource
- (NSInteger)outlineView :(NSOutlineView *)outlineView numberOfChildrenOfItem :(id) item
{
    return !item? [self.outlineViewContents count] : [[item children] count];
}

- (id)outlineView :(NSOutlineView *)outlineView child :(NSInteger)index ofItem :(id)item
{
    id result = nil;

    if (!item)
        result = self.outlineViewContents[index];

    else if ([item isKindOfClass:[CDevice class]]) {
        //这里重点关注设备类型
        CDevice *device = item;
        switch (device.type) {
            case IPC:
                result = nil;//IPC不显示其下面的通道
                break;
            case NVR:
                result = [[item children] objectAtIndex:index];
                break;
            default:
                break;
        }
    }
    else
        result = [[item children] objectAtIndex:index];
    
    return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    BOOL expandable = ([[item children] count] != 0);
    
    if ([item isKindOfClass:[Group class]]) {
        Group *group = (Group *)item;
        if (group.type == PATROL_GROUP)
            expandable = NO;
    }
    else if ([item isKindOfClass:[CDevice class]]) {
        CDevice *device = (CDevice *)item;
        if (device.type == IPC)
            expandable = NO;
    }
    
    return expandable;
}

- (id <NSPasteboardWriting>)outlineView :(NSOutlineView *)outlineView
                pasteboardWriterForItem :(id)item
{
    if ([item isKindOfClass:[CDevice class]]) {
        CDevice *device = (CDevice *)item;
        switch (device.type) {
            case IPC:
                return [device.children firstObject];
            default:
                return nil;
        }
    }
    else if ([item isKindOfClass:[Channel class]])
        return (Channel *)item;
    
    else if ([item isKindOfClass:[Group class]]) {
        Group *group = item;
        switch (group.type) {
            case PATROL_GROUP:
                return group;
            default:
                return nil;
        }
    }
    
    return nil;
}

- (void)outlineView :(NSOutlineView *)outlineView
    draggingSession :(NSDraggingSession *)session
   willBeginAtPoint :(NSPoint)screenPoint
           forItems :(NSArray *)draggedItems
{
    id draggedItem = [draggedItems firstObject];
    
    if ([draggedItem isKindOfClass:[CDevice class]]) {
        CDevice *device = draggedItem;
        switch (device.type) {
            case IPC:
                _draggedNode = [device.children firstObject];
                break;
            default:
                _draggedNode = nil;
                break;
        }
    }
    else
        _draggedNode = draggedItem;
}

- (void)outlineView :(NSOutlineView *)outlineView
    draggingSession :(NSDraggingSession *)session
       endedAtPoint :(NSPoint)screenPoint
          operation :(NSDragOperation)operation
{
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    
    if (NSDragOperationCopy == operation) {
        //有对象接受了这次拖拽操作
        //询问多窗口管理器，释放点对应的端口号
        int viewId = [manager viewIdForPoint:screenPoint];
        if (viewId >= 0 && [manager isFreeView:viewId]) {
            
            NSString *key = [self identifierOfPreviewItem:_draggedNode];
            PreviewObjState *state = [self.preViewMap valueForKey:key];
            
            if (state.isPlay) {
                [self performPreview:_draggedNode viewId:viewId];
            }
            else {
                [self performBeginPreviewWithItem:_draggedNode viewId:viewId];
            }
        }
    }
}

#pragma mark - NSOutlineViewDelegate
- (NSView *)outlineView:(NSOutlineView *)outlineView
     viewForTableColumn:(NSTableColumn *)tableColumn
                   item:(id)item
{
    //根据节点的类型，贴出不同的图标
    NSTableCellView *cellView = [outlineView makeViewWithIdentifier:@"Main Cell View" owner:self];
    NSString *imageName,*title;
    
    if ([item isKindOfClass:[CDevice class]]) {
        CDevice     *d = (CDevice *)item;
        NSString    *dKey = [NSString stringWithFormat:@"D%d",d.uniqueId];
        DeviceState *dState = [self.deviceMap valueForKey:dKey];
        
        switch (d.type) {
            case IPC:
                imageName = dState.isOnline? @"ChannelConnected" : @"ChannelDisconnected";
                break;
            case NVR:
                imageName = dState.isOnline? @"NVR_Online" : @"NVR_Offline";
                break;
            default:
                break;
        }
        title = [item name];
    }
    else if ([item isKindOfClass:[Group class]]) {
    
        switch (((Group *)item).type) {
            case ROOT_GROUP:
                imageName = @"INPUT";
                break;
            case PATROL_GROUP:
                imageName = @"PatrolGroup";
                break;
            case NORMAL_GROUP:
                imageName = @"NormalGroup";
                break;
            default:
                break;
        }
        title = [item name];
    }
    else if ([item isKindOfClass:[Channel class]]) {
        Channel         *c = (Channel *)item;
        NSString        *cKey = [NSString stringWithFormat:@"G-1_C%d",c.uniqueId];
        ChannelState    *cState = [self.preViewMap valueForKey :cKey];
        
        imageName = cState.isOnline? @"ChannelConnected" : @"ChannelDisconnected";
        title = (c.device.type == IPC)? [item name] : [NSString stringWithFormat:@"CH%d",c.logicId + 1];
    }
    
    [cellView.imageView setImage:[NSImage imageNamed:imageName]];
    [cellView.textField setObjectValue:title];

    return cellView;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView
   shouldSelectItem:(id)item
{
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
shouldEditTableColumn:(NSTableColumn *)tableColumn
               item:(id)item
{
    return NO;
}

#pragma mark - multy video view manager
- (void)syncSelectedStateWithViewId :(int)vId inTree :(TreeNode *)node
{
    if (vId < 0 || !node)
        return;
    
    NSInteger row = [self.outlineView rowForItem:node];
    
    if (row >= 0) {
        Channel *c = nil;
        Group *g = nil;
        NSIndexSet *index = [NSIndexSet indexSetWithIndex:row];
        
        if ([node isKindOfClass:[CDevice class]] && ((CDevice *)node).type == IPC)
            c = [node.children firstObject];
        else if ([node isKindOfClass:[Channel class]])
            c = (Channel *)node;
        else if ([node isKindOfClass:[Group class]] && ((Group *)node).type == PATROL_GROUP)
            g = (Group *)node;
        
        if (c) {
            NSString *cKey = [NSString stringWithFormat:@"G-1_C%d",c.uniqueId];
            ChannelState *cState = [self.preViewMap valueForKey:cKey];
            
            if (cState.viewId == vId)
                [self.outlineView selectRowIndexes:index byExtendingSelection:NO];
        }
        else if (g) {
            NSString *gKey = [NSString stringWithFormat:@"G%d",g.uniqueId];
            PollingState *gState = [self.preViewMap valueForKey:gKey];
            
            if (gState.viewId == vId)
                [self.outlineView selectRowIndexes:index byExtendingSelection:NO];
        }
        else if ([node respondsToSelector:@selector(children)]) {
            [[node children] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self syncSelectedStateWithViewId:vId inTree:obj];
            }];
        }

    }
}

- (void)selectionDidChange:(NSNotification *)aNotific
{
    int selectedVId = self.multyVideoViewsManager.selectedViewId;

    if (selectedVId >= 0) {
        [self.outlineView deselectAll:nil];
        [self syncSelectedStateWithViewId:selectedVId inTree:[self.outlineViewContents firstObject]];
        [self updatePtzUI];
    }
}

- (void)wndStreamTypeDidChange:(NSNotification *)aNotific
{
    if (aNotific.object == self.multyVideoViewsManager) {
        int viewId = [[aNotific.userInfo valueForKey:KEY_PORT] intValue];
        //以新码流身份重新登录设备
        if (viewId >= 0) {
            TreeNode *item = nil;
            [self findPreviewObj:&item withViewId:viewId inTree:[self.outlineView itemAtRow :0]];
            [self performPreview:item viewId:viewId];
        }
    }
}

- (BOOL)shouldEnterSingleWnd
{
    return [self.multyVideoViewsManager selectedObj] != nil;
}

- (void)didExitFullScreenMode:(NSNotification *)aNotific
{
    [self setupMultyVideoViewsManager];
}

#pragma mark - drag view delegate
- (NSArray *)dragView:(DragView *)dv draggingItemsAtPoint:(NSPoint)screenPoint
{
    int vId     = [self.multyVideoViewsManager viewIdForPoint:screenPoint];
    id  node    = [self.multyVideoViewsManager objOfView:vId];
    
    if (node) {
        NSDraggingItem *item = [[NSDraggingItem alloc] initWithPasteboardWriter:node];
        [item setImageComponentsProvider:^NSArray *{
            //prepare contents
            NSImage *image;
            if ([node isKindOfClass:[Channel class]])
                image = [NSImage imageNamed:@"ChannelConnected"];
            else if ([node isKindOfClass:[Group class]])
                image = [NSImage imageNamed:@"PatrolGroup"];
            
            //prepare frame
            NSRect          rcInScreen = NSMakeRect(screenPoint.x, screenPoint.y, 0, 0);
            NSRect          rcInWindow = [self.placeHolder1.window convertRectFromScreen:rcInScreen];
            NSPoint         ptInView = [self.placeHolder1 convertPoint:rcInWindow.origin fromView:nil];
            NSTableCellView *cellView = [self.outlineView makeViewWithIdentifier:@"Main Cell View" owner:self];
            NSImageView     *imageView = cellView.imageView;
            NSSize          size = imageView? imageView.frame.size : NSZeroSize;
            
            
            NSDraggingImageComponent *component = [[NSDraggingImageComponent alloc] initWithKey:NSDraggingImageComponentIconKey];//[[NSDraggingImageComponent alloc] init];
            component.contents = image;
            component.frame = NSMakeRect(ptInView.x + 5, ptInView.y - 5, size.width, size.height);
            return @[component];
        }];
        
        return @[item];
    }
    
    return nil;
}

- (NSDragOperation)dragView:(DragView *)dv validateDrop:(id<NSDraggingInfo>)info
{
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    int viewId = [manager viewIdForPoint:[NSEvent mouseLocation]];
    
    if (self.outlineView == [info draggingSource])
        return [manager isFreeView:viewId]? NSDragOperationCopy : NSDragOperationNone;
    else {
        NSString        *key = [self identifierOfPreviewItem:_draggedNode];
        PreviewObjState *previewObjState = [self.preViewMap valueForKey:key];
        int             draggingViewId = previewObjState.viewId;
        
        return viewId != draggingViewId? NSDragOperationCopy : NSDragOperationNone;
    }
    
    return NSDragOperationNone;
}

- (void)dragView :(DragView *)dv
 draggingSession :(NSDraggingSession *)session
willBeginAtPoint :(NSPoint)screenPoint
{
    
    int viewId  = [self.multyVideoViewsManager viewIdForPoint:screenPoint];
    id  node    = [self.multyVideoViewsManager objOfView:viewId];

    if (node) {
        _draggedNode = node;
        _draggedViewId = viewId;
    }
}

- (void)dragView :(DragView *)dv
 draggingSession :(NSDraggingSession *)session
    endedAtPoint :(NSPoint)screenPoint
       operation :(NSDragOperation)operation
{
    if (NSDragOperationCopy == operation) {
        int src = _draggedViewId;
        int dst = [self.multyVideoViewsManager viewIdForPoint:screenPoint];
        
        if (src != dst) {
            TreeNode *obj1,*obj2;
            TreeNode *root = [self.outlineViewContents firstObject];
            
            [self findPreviewObj:&obj1 withViewId:src inTree:root];
            [self findPreviewObj:&obj2 withViewId:dst inTree:root];
            
            NSAssert(obj1 != obj2, @"交换对象不能相同");
            
            [self performPreview:obj1 viewId:dst];
            [self performPreview:obj2 viewId:src];
        }
    }
}

#pragma mark - split view delegate
-(void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize
{
    ///当splitview大小发生改变时，锁定PTZ
    NSString *identifier = sender.identifier;
    if ([identifier isEqualToString:IDENTIFIER_TOP_BOTTOM_SPLITVIEW]) {
        NSSize newSize = sender.bounds.size;
        NSRect topRect = [[self.splitview subviews][0] frame];
        NSRect bottomRect = [[self.splitview subviews][1] frame];
        CGFloat dividerThickness = [self.splitview dividerThickness];
        topRect.origin = CGPointZero;
        topRect.size.height = newSize.height - dividerThickness - bottomRect.size.height;
        topRect.size.width = newSize.width;
        
        bottomRect.origin.y = topRect.size.height + dividerThickness;
        
        [[self.splitview subviews][0] setFrame:topRect];
        [[self.splitview subviews][1] setFrame:bottomRect];
    }
}


- (CGFloat)splitView:(NSSplitView *)splitView
constrainSplitPosition:(CGFloat)proposedPosition
         ofSubviewAt:(NSInteger)dividerIndex
{
    return [self positionOfDividerAtIndex:dividerIndex];
}


- (CGFloat)positionOfDividerAtIndex :(NSInteger)dividerIndex
{
    CGFloat result = 0;
    CGFloat dividerThickness = self.splitview.dividerThickness;
    switch (dividerIndex) {
        case 0:
            result = self.splitview.frame.size.height - kPTZViewHeight - dividerThickness;
            break;
            
        default:
            break;
    }
    
    return result;
}

#pragma mark - ptz button delegate
- (void)sendPTZCmd :(unsigned int)cmd withSpeed :(int)speed state :(int)state channelId :(int)cId
{
    if (state >= 0) {
        PTZ_CMD ptzCmd;
        ptzCmd.ptzCmd = cmd;
        ptzCmd.param1 = state;
        ptzCmd.param2 = speed;
        ptzCmd.param3 = 0;
        ptzCmd.param4 = 0;
        ptzCmd.param5 = 0;
        
        Channel *c = nil;
        [self findChannel:&c withId:cId inTree:[self.outlineView itemAtRow :0]];
        [[DispatchCenter sharedDispatchCenter] sendPTZControlCommand:ptzCmd toDevice:c.device channel:c.logicId];
    }
}

#define CMD_CNT 15
- (unsigned int)cmdForTag :(NSUInteger)tag
{
    static unsigned int cmds[CMD_CNT] = {
        FOSCAM_IPC_PTZ_CMD_UP,
        FOSCAM_IPC_PTZ_CMD_RIGHT_UP,
        FOSCAM_IPC_PTZ_CMD_RIGHT,
        FOSCAM_IPC_PTZ_CMD_RIGHT_DOWN,
        FOSCAM_IPC_PTZ_CMD_DOWN,
        FOSCAM_IPC_PTZ_CMD_LEFT_DOWN,
        FOSCAM_IPC_PTZ_CMD_LEFT,
        FOSCAM_IPC_PTZ_CMD_LEFT_UP,
        FOSCAM_IPC_PTZ_CMD_AUTO,
        FOSCAM_IPC_PTZ_CMD_ZOOM_IN,
        FOSCAM_IPC_PTZ_CMD_ZOOM_OUT,
        FOSCAM_IPC_PTZ_CMD_FOCUS_NEAR,
        FOSCAM_IPC_PTZ_CMD_FOCUS_FAR,
        FOSCAM_IPC_PTZ_CMD_IRIS_OPEN,
        FOSCAM_IPC_PTZ_CMD_IRIS_CLOSE,
    };

    return (tag < CMD_CNT)? cmds[tag] : 0;
}

//开启
- (void)ptzButtonDown:(id)sender
{
    [self onPtzButtonPressed:YES withTag:(int)[sender tag]];
}

//结束
- (void)ptzButtonUp:(id)sender
{
    [self onPtzButtonPressed:NO withTag:(int)[sender tag]];
}

- (void)onPtzButtonPressed :(BOOL)isPress withTag :(int)tag
{
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    int chnId = [manager selectedChannelId];
    
    if (chnId >= 0) {
        unsigned int cmd = [self cmdForTag:tag];
        int state = 0;
        if (isPress)
            state = (cmd == FOSCAM_IPC_PTZ_CMD_AUTO)? -1 : 1;
        else
            state = (cmd == FOSCAM_IPC_PTZ_CMD_AUTO)? 1 : 0;
        [self sendPTZCmd :[self cmdForTag:tag]
               withSpeed :self.horizontalSlider.intValue
                   state :state
               channelId :chnId];
    }
}


- (void)hidePtz
{
    self.zoomZone.hidden = YES;
    self.ptzZone.hidden = YES;
    self.ptzBkView.image = nil;
}

- (void)updatePtzUI
{
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    int viewId = [manager selectedViewId];
    id obj = nil;
    [self findPreviewObj:&obj withViewId:viewId inTree:[self.outlineViewContents firstObject]];
    
    if ([obj isKindOfClass:[Channel class]]) {
        Channel *c = obj;
        FosAbility *ability = [[DispatchCenter sharedDispatchCenter] abilityOfDevice:c.device channel:c.logicId];
        
        self.zoomZone.hidden = (ability.zoomFlag == 0);
        
        if (ability.ptFlag == 0) {
            self.ptzZone.hidden = YES;
            self.ptzBkView.image = nil;
        }
        else {
            self.ptzZone.hidden = NO;
            self.ptzBkView.image = [NSImage imageNamed:@"PTZ"];
            
            [self updateCruiseListUIWithChannel:c];
        }
    }
    else {
        [self hidePtz];
    }
}

- (void)updateCruiseListUIWithChannel :(Channel *)c
{
    //异步获取巡航列表
    [self.cruiseZone.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [(NSControl *)obj setEnabled:NO];
    }];
    
    //通过已有的代码去获取和解析
    switch (c.device.type) {
        case IPC:
            self.cruiseVC = [[PTZCruiseViewController alloc] init];
            break;
            
        case NVR:
            self.cruiseVC = [[NVRPTZCruiseViewController alloc] init];
            break;
            
        default:
            return;
    }
    
    __weak VideoMonitoringController *weakSelf = self;
    
    self.cruiseVC.device = c.device;
    self.cruiseVC.fetchPresetPtsCompleteHandle = ^(BOOL success,
                                                   const FOS_RESETPOINTLIST pts,
                                                   const FOS_CRUISEMAPLIST cruises,
                                                   id owner)
    {
        if (owner == self.cruiseVC) {
            
            if (success) {
                [weakSelf.cruiseZone.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [(NSControl *)obj setEnabled:YES];
                }];
                
                [weakSelf.cruiseMapListBtn removeAllItems];
                [weakSelf.presetPointListBtn removeAllItems];
                
                for (int i = 0; i < cruises.cruiseMapCnt; i++) {
                    [weakSelf.cruiseMapListBtn addItemWithTitle:[NSString stringWithCString:cruises.cruiseMapName[i]
                                                                                   encoding:NSASCIIStringEncoding]];
                }
                
                for (int i = 0; i < pts.pointCnt; i++) {
                    [weakSelf.presetPointListBtn addItemWithTitle:[NSString stringWithCString:pts.pointName[i]
                                                                                     encoding:NSASCIIStringEncoding]];
                }
            }
            
            weakSelf.cruiseVC = nil;
        }
    };
    
    [self.cruiseVC fetchPresetPointAndCruiseMapList];
}


#pragma mark - Basic Setting Did Change
- (void)handleBasicSettingDidChangeNotification :(NSNotification *)aNotific
{
    NSString *name = aNotific.name;
    
    if ([name isEqualToString:BASIC_SETTING_DID_CHANGE_NOTIFICATION]) {
        VMSBasicSetting *basicSetting = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
        [self.multyVideoViewsManager setWndStreamTypeOption:basicSetting.wndStreamType];
    }
}

#pragma mark - Dispatch Center Protocal
- (void)handleDispatchCenterNotification :(NSNotification *)aNotific
{
    NSString *name = aNotific.name;
    NSDictionary *userInfo = aNotific.userInfo;
    
    if ([name isEqualToString:CONNECTION_STATE_DID_CHANGE_NOTIFICATION]) {
        //解析通知
        int devId = [[userInfo valueForKey:KEY_EVENT_DEVICE_ID] intValue];
        int  chId = [[userInfo valueForKey:KEY_EVENT_CHANNEL_ID] intValue];
        BOOL state  = [[userInfo valueForKey:KEY_EVENT_CONNECTION_STATE] boolValue];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            int channelId = [[VMSDatabase sharedVMSDatabase] fetchChannelIdWithDeviceId:devId logicId:chId];
            if (channelId >= 0) {
                [self onConnectionStateChanged:state withChannelId:channelId];
            }
        });
    }
    else if ([name isEqualToString:DEVICE_ONLINE_STATE_DID_CHANGE_NOTIFICATION]) {
        int devId = [[userInfo valueForKey:KEY_EVENT_DEVICE_ID] intValue];
        BOOL state  = [[userInfo valueForKey:KEY_DEVICE_STATE] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            DeviceState *devState = [self.deviceMap valueForKey:[NSString stringWithFormat:@"D%d",devId]];
            CDevice *device = nil;
            [self findDevice:&device withId:devId inTree:[self.outlineViewContents firstObject]];
            
            if (device) {
                NSInteger   row = [self.outlineView rowForItem:device];
                //更新纪录
                devState.online = state;
                //更新UI
                [self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                            columnIndexes:[NSIndexSet indexSetWithIndex:0]];
                
            }
        });
    }
    else if ([name isEqualToString:DEVICE_CRUISE_MAP_DID_CHANGE_NOTIFICATION]) {
        //巡航路径发生改变
        //该消息仅向ipc发送，nvr不处理改通知(nvr不修改巡航路径)
        long devId = [[userInfo valueForKey:KEY_EVENT_DEVICE_ID] longValue];
        NSData *data = [userInfo valueForKey:KEY_CRUISE_MAP];
        
        FOSCRUISEMAP cruiseMap;
        
        [data getBytes:&cruiseMap length:sizeof(FOSCRUISEMAP)];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //查看选中的窗口
            int vId = self.multyVideoViewsManager.selectedViewId;
            id obj = nil;
            [self findPreviewObj:&obj withViewId:vId inTree:[self.outlineViewContents firstObject]];
            
            if ([obj isKindOfClass:[Channel class]]) {
                Channel *c = obj;
                
                if (c.device && c.device.uniqueId == devId) {
                    //更新巡航路径
                    [self.cruiseMapListBtn removeAllItems];
                    for (int i = 0; i < cruiseMap.cnt; i++) {
                        [self.cruiseMapListBtn addItemWithTitle:[NSString stringWithCString:cruiseMap.mapList[i]
                                                                                   encoding:NSASCIIStringEncoding]];
                    }
                }
            }
        });
    }
    else if ([name isEqualToString:DEVICE_RELOAD_NOTIFICATION]) {
        //设备发生了重载,关闭所有该设备正在进行的活动
        int devId = [[userInfo valueForKey:KEY_EVENT_DEVICE_ID] intValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CDevice *device = nil;
            [self findDevice:&device withId:devId inTree:[self.outlineViewContents firstObject]];
            
            //关闭设备下的所有通道预览
            for (Channel *c in device.children) {
                [self performStopPreview:c];
            }
            
            //重新load设备信息
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:VMS_DEVICE_UPDATE], NOTIFI_KEY_DB_OP,device,NOTIFI_KEY_DEVICE,nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:DATABASE_CHANGED_NOTIFICATION
                                                                object:self
                                                              userInfo:userInfo];
            
        });
    }
}


- (BOOL)getGId :(NSInteger *)gId fromKey:(NSString *)key
{
    NSUInteger GLocation = [key rangeOfString:@"G"].location;
    NSUInteger _Location = [key rangeOfString:@"_"].location;
    
    if (GLocation == NSNotFound || _Location == NSNotFound) {
        return NO;
    }
    
    NSString *str = [key substringWithRange:NSMakeRange(GLocation + 1, _Location - GLocation -1)];
    
    if (str) {
        *gId = str.integerValue;
        return YES;
    }
    
    return NO;
}

//处理通道连接状态发生改变,在主线程操作
- (void)onConnectionStateChanged :(BOOL)state
                   withChannelId :(int)chnId
{
    if (mor_debug) {
        NSLog(@"Running in %@,'%@'",[self class],NSStringFromSelector(_cmd));
    }
    
    if (chnId >= 0) {
        Channel *c;
        [self findChannel:&c withId:chnId inTree:[self.outlineView itemAtRow :0]];
        
        if (c) {
            //如果设备在线，查看是否需要自动预览
            NSArray *allKeys = self.preViewMap.allKeys;
            for (NSString *key in allKeys) {
                NSRange range = [key rangeOfString:[NSString stringWithFormat:@"C%d",chnId]];
                if (range.location == NSNotFound)
                    continue;
                
                ChannelState *cState = [self.preViewMap valueForKey:key];
                cState.online = state;
                
                if (cState.isAutoPlay) {
                    NSInteger gId = -1;
                    if ([self getGId:&gId fromKey:key]) {
                        if (cState.isPlay)
                            [self performPreview:c withViewId:cState.viewId groupId:gId];
                        else
                            [self performBeginPreview:c withViewId:cState.viewId];
                    }
                }
            }
            
            //更新Outline view ui
            NSInteger row = [self.outlineView rowForItem:c];
            [self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                        columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        }
    }
}

#pragma mark - tab mvc protocol
- (void)willTab:(NSNotification *)aNotific stop:(BOOL *)stop
{
    *stop = NO;
}


#pragma mark - setter and getter
-(MultyVideoViewsManager *)multyVideoViewsManager
{
    if (!_multyVideoViewsManager) {
        _multyVideoViewsManager =
        [[MultyVideoViewsManager alloc] initWithNibName:@"MultyVideoViewManager" bundle:[NSBundle mainBundle]];
        
        if (!_multyVideoViewsManager) {
            NSLog(@"failed to load MultyVideoViewsManager");
            exit(0);
        }
        //组装
        for (int viewId = 0; viewId < 64; viewId++) {
            VideoViewController *videoController =
            [[VideoViewController alloc] initWithNibName :@"JFVideoView"
                                                  bundle :nil
                                                  viewId :viewId
                                                    type :AVPLAY_TYPE_STREAM];
            
            if (!videoController) {
                NSLog(@"failed to load JFVideoView");
                exit(0);
            }
            
            [self.audioGrabber addObserver:videoController];
            [_multyVideoViewsManager addVideoViewController:videoController];
        }
        [_multyVideoViewsManager setPageSize:1];
        
        JFSplitView *contentView = (JFSplitView *)_multyVideoViewsManager.view;
        [contentView setMenu :self.contextMenu];
        [contentView setDelegate:self];
        [contentView registerForDraggedTypes:@[NSPasteboardTypeString]];
        
        [[DispatchCenter sharedDispatchCenter] addObserver:_multyVideoViewsManager];
        //设置委托
        [_multyVideoViewsManager setDelegate:self];
    }
    
    return _multyVideoViewsManager;
}


- (NSArray *)outlineViewContents
{
    //Lazy init
    //If we want to fresh the device infos,just specify nil.
    //Building tree level
    if (!_outlineViewContents) {
        //Building the first level
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        Group *root = [[Group alloc] initWithUniqueId:-1 name:NSLocalizedString(@"Video Input Device", nil) type:ROOT_GROUP remark:@""];
        [root addChildren:[db fetchGroups]];
        
        NSMutableArray *groups = [[NSMutableArray alloc] initWithArray:root.children];
        [groups addObject:root];
        
        for (Group *group in groups) {
            //Building the second level
            int type = group.type;
            switch (type) {
                case PATROL_GROUP: {
                    [db fetchPollsWithGroup:group];
                    //查看map是否存在
                    NSString        *gKey        = [NSString stringWithFormat:@"G%d",group.uniqueId];
                    PollingState    *gState  = [self.preViewMap valueForKey:gKey];
                    NSArray         *polls      = [group children];
                    
                    if (!gState) {
                        gState = [[PollingState alloc] init];
                        [self.preViewMap setValue:gState forKey:gKey];
                    }
                    
                    for (Poll *poll in polls) {
                        NSString        *gcKey = [NSString stringWithFormat:@"%@_C%d",gKey,poll.channelId];
                        ChannelState    *gcState = [self.preViewMap valueForKey:gcKey];
                        
                        if (!gcState) {
                            //这里需要将通道的在线状态同步过来
                            NSString *cKey = [NSString stringWithFormat:@"G-1_C%d",poll.channelId];
                            ChannelState *cState = [self.preViewMap valueForKey:cKey];
                            
                            gcState = [[ChannelState alloc] init];
                            gcState.online = cState.isOnline;
                            [self.preViewMap setValue:gcState forKey:gcKey];
                        }
                    }
                }
                    break;
                case ROOT_GROUP:
                case NORMAL_GROUP: {
                    NSArray *devices = [[VMSDatabase sharedVMSDatabase] fetchDevicesWithGroup:group];
                    //Building the third level
                    for (CDevice *device in devices) {
                        NSString *key = [NSString stringWithFormat:@"D%d",device.uniqueId];
                        if (![self.deviceMap valueForKey:key]) {
                            [self.deviceMap setValue:[[DeviceState alloc] init] forKey:key];
                        }
                        NSArray *channels = [[VMSDatabase sharedVMSDatabase] fetchChannelsWithDevice:device];
                        for (Channel *channel in channels) {
                            NSString *key = [NSString stringWithFormat:@"G-1_C%d",channel.uniqueId];
                            if (![self.preViewMap valueForKey:key])
                                [self.preViewMap setValue:[[ChannelState alloc] init] forKey:key];
                        }
                    }
                }
                default:
                    break;
            }
        }
        _outlineViewContents = [[NSArray alloc] initWithObjects:root, nil];
    }
    
    return _outlineViewContents;
}

- (NSMutableDictionary *)preViewMap
{
    if (!_preViewMap) {
        _preViewMap = [[NSMutableDictionary alloc] init];
    }
    return _preViewMap;
}

- (NSMutableDictionary *)deviceMap
{
    if (!_deviceMap) {
        _deviceMap = [[NSMutableDictionary alloc] init];
    }
    
    return _deviceMap;
}

- (int)pagePollingInterval
{
    VMSBasicSetting *basicSetting = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
    return basicSetting.pollTime;
}

- (NSTimer *)onLineTestTimer
{
    if (!_onLineTestTimer) {
        self.scanInterver = QUERY_DEVICE_STATE_INTERVAL;
        _onLineTestTimer = [NSTimer scheduledTimerWithTimeInterval:self.scanInterver
                                                            target:self
                                                          selector:@selector(onlineTestingAction:)
                                                          userInfo:nil
                                                           repeats:NO];
    }
    
    return _onLineTestTimer;
}

- (AudioGrabber *)audioGrabber
{
    if (!_audioGrabber) {
        _audioGrabber = [[AudioGrabber alloc] init];
        [_audioGrabber start];
    }
    
    return _audioGrabber;
}
@end
