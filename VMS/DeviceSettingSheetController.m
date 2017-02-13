//
//  DeviceManagementController.m
//  VMS
//
//  Created by mac_dev on 15/6/25.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "DeviceSettingSheetController.h"

#define KEY_DEVICE_MANAGEMENT_ITEMS             @"Device Management Items"
#define KEY_GROUP                               @"Group"
#define KEY_SUB_ITEMS                           @"Sub Items"
#define KEY_CLASS                               @"Class"
#define KEY_NIB                                 @"Nib"
#define ID_COLUMN_NAME                          @"Name"

@interface DeviceSettingSheetController ()

@property (readwrite) CDevice *device;

@property (nonatomic,weak) IBOutlet NSProgressIndicator *indicator;
@property (nonatomic,weak) IBOutlet NSProgressIndicator *reconnectIndicator;
@property (nonatomic,weak) IBOutlet NSOutlineView* sourceview;
@property (nonatomic,weak) IBOutlet NSTabView *tabView;
@property (nonatomic,weak) IBOutlet NSButton *refreshBtn;
@property (nonatomic,weak) IBOutlet NSButton *saveBtn;
@property (nonatomic,weak) IBOutlet NSButton *doneBtn;
@property (nonatomic,weak) IBOutlet NSTextField *tips;

@property (nonatomic,assign) NSInteger curEntries;
@property (nonatomic,strong) NSArray *tabViewControllers;
@property (nonatomic,strong) NSArray *entries;
@property (nonatomic,strong) SettingViewController *curSettingViewController;
@property (nonatomic,assign) BOOL activity;
@property (nonatomic,assign) BOOL reconnect;
@property (nonatomic,assign) int reLoadWaitTime;
@end

@implementation DeviceSettingSheetController
#pragma mark - Public API
- (id)initWithWindowNibName:(NSString *)windowNibName
                     device:(CDevice *)device
{
    if (self = [super initWithWindowNibName:windowNibName]) {
        self.device = device;
        self.activity = YES;
    }
    
    return self;
}

- (void)dealloc
{
    NSLog(@"Running in %@,'%@'",self.class,NSStringFromSelector(_cmd));

    SettingViewController *svc = (SettingViewController *)self.tabView.selectedTabViewItem.viewController;
    
    svc.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - action
- (IBAction)done :(id)sender
{
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseOK];
    else
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)refresh:(id)sender
{
    SettingViewController *svc = (SettingViewController *)[self.tabView selectedTabViewItem].viewController;
    [svc fetch];
}

- (IBAction)save :(id)sender
{
    SettingViewController *svc = (SettingViewController *)[self.tabView selectedTabViewItem].viewController;
    [svc push];
}


- (void)reloadWaitAction :(NSTimer *)timer
{
    if (--self.reLoadWaitTime > 0) {
        self.tips.stringValue = [NSString stringWithFormat:@"%@%ds",NSLocalizedString(@"set successful,please wait......", nil),self.reLoadWaitTime];
        
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(reloadWaitAction:) userInfo:nil repeats:NO];
    }
    else {
        //加载时间已到
        self.tips.stringValue = NSLocalizedString(@"re login.....", nil);
        
        [[DispatchCenter sharedDispatchCenter] reLoadDevice:self.device
                                       withCompletionHandle:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.tips.stringValue = @"";
                self.reconnect = NO;
                self.doneBtn.enabled = YES;
            });
        }];
    }
}

#pragma mark - tabview delegate
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    SettingViewController *svc = (SettingViewController *)tabViewItem.viewController;
    SVC_OPTION option = svc.option;
    
    [self.refreshBtn setHidden:!(option & SVC_REFRESH)];
    [self.saveBtn setHidden:!(option & SVC_SAVE)];
    [svc fetch];
}

#pragma mark - life cycle
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *disableItems = [[NSMutableArray alloc] init];
        //收集禁用项
        BOOL setupAble = NO;
        
        if (IPC == self.device.type) {
            FosAbility *ability = [[DispatchCenter sharedDispatchCenter] abilityOfDevice:self.device channel:0];
            
            if (ability.model > 0) {
                //是否支持wifi
                if (ability.wifiType == 0) {
                    [disableItems addObject:@"WifiConfigViewController"];
                }
                
                //是否支持隐私遮盖
                if (!(ability.model > 4000 && ability.model < 6000)) {
                    [disableItems addObject:@"OSDMaskViewController"];
                }
                
                //是否支持ptz
                if (ability.ptFlag != 1) {
                    [disableItems addObject:@"PTZ"];
                }
                
                setupAble = YES;
            }
        }
        else if (NVR == self.device.type) {
            setupAble = YES;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (setupAble) {
                [self setupWithDisableItems :disableItems];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(handleOnlineStateChangeNotification:)
                                                             name:DEVICE_ONLINE_STATE_DID_CHANGE_NOTIFICATION
                                                           object:nil];
            }
            else {
                //提示
            }
        });
    });
}

- (void)setupWithDisableItems :(NSArray *)items
{
    NSString *profile = nil;
    
    if (self.device) {
        
        if (self.device.type == IPC)
            profile = @"IPC_Cfg";
        else if (self.device.type == NVR)
            profile = @"NVR_Cfg";
        
        if (profile) {
            NSString        *dataFilePath = [[NSBundle mainBundle] pathForResource:profile ofType:@"plist"];
            NSDictionary    *initData = [NSDictionary dictionaryWithContentsOfFile:dataFilePath];
            NSMutableArray  *entris = [initData[KEY_DEVICE_MANAGEMENT_ITEMS] mutableCopy];
            
            //移除禁用项
            [entris enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *entity = obj;
                NSString *group = [entity valueForKey:KEY_GROUP];
                NSMutableArray  *subItems = [entity valueForKey:KEY_SUB_ITEMS];
                
                if ([items containsObject:group])
                    [entris removeObject:entity];
                else {
                    //从子节点中移除
                    [subItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSDictionary *subItem = obj;
                        NSString *cls = [subItem valueForKey:KEY_CLASS];
                        
                        if ([items containsObject:cls]) {
                            [subItems removeObject:obj];
                        }
                    }];
                    
                    //重新设置为子节点
                    [entity setValue:subItems forKey:KEY_SUB_ITEMS];
                }
            }];
        
            self.entries = entris;
            if (entris.count > 0) {
                [self.sourceview reloadData];
                [self.sourceview selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
            }
        }
    }
}

#pragma mark - dispatch center notification
- (void)handleOnlineStateChangeNotification :(NSNotification *)aNotific
{
    NSString *name = aNotific.name;
    NSDictionary *userInfo = aNotific.userInfo;
    
    if ([name isEqualToString:DEVICE_ONLINE_STATE_DID_CHANGE_NOTIFICATION]) {
        long devId = [[userInfo valueForKey:KEY_EVENT_DEVICE_ID] longValue];
        BOOL state  = [[userInfo valueForKey:KEY_DEVICE_STATE] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.device.uniqueId == devId) {
                if (!state) {
                    self.tips.stringValue = state? NSLocalizedString(@"device reconnected", nil): NSLocalizedString(@"device is disconnected,being re connected......", nil);
                    self.reconnect = YES;
                }
                else {
                    self.tips.stringValue = NSLocalizedString(@"device reconnected", nil);
                    self.reconnect = NO;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                                   dispatch_get_main_queue(), ^{
                                       self.tips.stringValue = @"";
                                   });
                }
            }
        });
    }
}
#pragma mark - svc delegate
- (void)svc:(NSViewController *)svc
  willFetch:(NSNotification *)aNotific
{
    self.activity = NO;
}

- (void)svc:(NSViewController *)svc
   didFetch:(NSNotification *)aNotific
{
    self.activity = YES;
}

- (void)svc :(NSViewController *)svc deviceInfoDidChange :(NSNotification *)aNotific
{
    NSString *name = aNotific.name;
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    BOOL needReset = [name isEqualToString:KEY_RESTORE_NOTIFICATION];
    
    if ([db updateDevice:self.device]) {
        self.reLoadWaitTime = [[aNotific.userInfo valueForKey:KEY_RELOAD_WAIT_TIME] intValue];
        self.reconnect = YES;
        self.doneBtn.enabled = NO;
        
        [[DispatchCenter sharedDispatchCenter] logoutDevice:self.device needReset:needReset];
        [[NSTimer scheduledTimerWithTimeInterval:1
                                          target:self
                                        selector:@selector(reloadWaitAction:)
                                        userInfo:nil
                                         repeats:NO] fire];
    }
}


#pragma mark - vms tab view delegate
- (BOOL)shouldRespondHitTestForView:(NSView *)view
{
    return self.activity && !self.reconnect;
}

#pragma mark - outline view datasource
- (NSInteger)outlineView:(NSOutlineView *)outlineView
  numberOfChildrenOfItem:(id)item
{
    return !item? _entries.count : 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(NSInteger)index
           ofItem:(id)item
{
    return !item? [_entries objectAtIndex:index] : nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return !item? YES : NO;
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item
{
    if ([[tableColumn identifier] isEqualToString:@"Device Management Item"]) {
        return NSLocalizedString([item valueForKey:KEY_GROUP], nil);
    }
    
    return nil;
}

#pragma mark - outline view delegate
- (NSView *)outlineView:(NSOutlineView *)outlineView
     viewForTableColumn:(NSTableColumn *)tableColumn
                   item:(id)item
{
    NSString *identifier = [tableColumn identifier];
    if ([identifier isEqualToString:ID_COLUMN_NAME]) {
        NSTableCellView *cellView = [outlineView makeViewWithIdentifier:@"DataCell"
                                                                  owner:self];
        [cellView.textField setStringValue:NSLocalizedString([item valueForKey:KEY_GROUP], nil)];
        return cellView;
    }
    
    return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSUInteger  selectedRow = [self.sourceview selectedRow];
    NSArray     *entries = self.entries;
    
    if (selectedRow < entries.count) {
        NSDictionary    *entiry = entries[selectedRow];
        NSArray         *subItems = [entiry valueForKey:KEY_SUB_ITEMS];
        NSMutableArray  *svcs = [[NSMutableArray alloc] init];
        
        for (NSInteger idx = 0; idx < subItems.count; idx++) {
            NSDictionary *subItem = subItems[idx];
            SettingViewController *svc = [[NSClassFromString(subItem[KEY_CLASS]) alloc] initWithNibName:subItem[KEY_NIB] bundle:nil];
            [svc setDevice:self.device];
            [svc setDelegate:self];
            [svcs addObject:svc];
        }
        
        [self setTabViewControllers:svcs];
    }
}

#pragma mark setter && getter
- (void)setActivity:(BOOL)activity
{
    _activity = activity;
    if (_activity) {
        [self.indicator setHidden:YES];
        [self.indicator stopAnimation:self];
    } else {
        [self.indicator setHidden:NO];
        [self.indicator startAnimation:self];
    }
}

- (void)setTabViewControllers:(NSArray *)tabViewControllers
{
    //重置tabview的items
    //NSArray *tabViewItems = self.tabView.tabViewItems;
    [self.tabView.tabViewItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSTabViewItem *item = (NSTabViewItem *)obj;
        if (item.tabState != NSSelectedTab) {
            [self.tabView removeTabViewItem:obj];
        }
    }];
    
    [self.tabView.tabViewItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSTabViewItem *item = (NSTabViewItem *)obj;
        if (item.tabState == NSSelectedTab) {
            [self.tabView removeTabViewItem:obj];
        }
    }];
    
    [tabViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSTabViewItem *item = [NSTabViewItem tabViewItemWithViewController:obj];
        [item setLabel:[obj description]];
        [self.tabView addTabViewItem:item];
    }];
}

- (void)setReconnect:(BOOL)reconnect
{
    _reconnect = reconnect;
    if (reconnect) {
        [self.reconnectIndicator setHidden:NO];
        [self.reconnectIndicator startAnimation:nil];
        
    }
    else {
        [self.reconnectIndicator setHidden:YES];
        [self.reconnectIndicator stopAnimation:nil];
        
    }
}
@end
