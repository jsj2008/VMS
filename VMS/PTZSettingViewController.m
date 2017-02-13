//
//  PTZSettingViewController.m
//  VMS
//
//  Created by mac_dev on 15/12/22.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "PTZSettingViewController.h"

#define CBID_SPEED              @"speed"
#define CBID_CRUISE_MODE        @"cruise mode"
#define CBID_CRUISE_TIME        @"cruise time"
#define CBID_CRUISE_MAP_LIST    @"cruise map list"
#define CBID_SELF_TEST_MODE     @"self test mode"

#define TVID_PRESET_POINT_LIST  @"preset point list"
#define TVID_CRUISE_MAP_INFO    @"cruise map info"
#define TVCID_NUMBER            @"number"
#define TVCID_NAME              @"name"
#define TVCID_TIME              @"time"

@interface PTZSettingViewController ()

@property(nonatomic,weak) IBOutlet NSPopUpButton *speedBtn;

@property(nonatomic,weak) IBOutlet NSButton *saveBT;
@property(nonatomic,weak) IBOutlet NSPopUpButton *cruiseModeBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *cruiseTimeBtn;
@property(nonatomic,weak) IBOutlet NSTextField *cruiseTimeCustomedTF;
@property(nonatomic,weak) IBOutlet NSTextField *cruiseLoopCntTF;
//@property(nonatomic,weak) IBOutlet NSComboBox *cruiseTracksCB;
@property(nonatomic,weak) IBOutlet NSPopUpButton *cruiseTracksBtn;
@property(nonatomic,weak) IBOutlet NSTableView *presetPointListTV;
@property(nonatomic,weak) IBOutlet NSTableView *cruiseMapInfoTV;
@property(nonatomic,assign,getter=isCustomedCruiseTime) BOOL customedCruiseTime;
@property(nonatomic,assign,getter=isCruiseTimeMode) BOOL cruiseTimeMode;

@property(nonatomic,weak) IBOutlet NSPopUpButton *startUpOptionsBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *presetOptionBtn;
@property(nonatomic,assign,getter=isHidePresetOption) BOOL hidePresetOption;
@end

@implementation PTZSettingViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    NSTabViewItem *item = self.tabView.selectedTabViewItem;
    NSInteger index = [self.tabView indexOfTabViewItem:item];
    
    [self refetch:index];
}


#pragma mark - action
- (IBAction)cruiseButtonAction :(id)sender
{
    NSInteger tag = [sender tag];
    
    switch (tag) {
        case 0:
            self.cruiseTimeMode = self.cruiseModeBtn.indexOfSelectedItem == ([self availableCruiseMode].count - 1);
            break;
            
        case 1:
            self.customedCruiseTime = self.cruiseTimeBtn.indexOfSelectedItem != ([self availableCruiseTime].count -1);
            break;
            
        case 2:
            [self refetchMapInfoWithMapName:[NSString stringWithFormat:@"%ld",self.cruiseTracksBtn.indexOfSelectedItem + 1]];
            break;
        default:
            break;
    }
}

- (IBAction)StartOptionButtonAction:(id)sender
{
    NSPopUpButton *startUpOptionBtn = sender;
    NSInteger  idxOfSelectedItem = startUpOptionBtn.indexOfSelectedItem;
    self.hidePresetOption = (2 == idxOfSelectedItem);
}

#pragma mark - public api
- (void)push:(NSInteger)tag
{
    [self setActivity:YES];
    
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    __block FOSCAM_NET_CONFIG config;
    __block BOOL success = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^
    {
        switch (tag) {
            case 0: {
                //获取PTZ速度
                int idx = (int)[self.speedBtn indexOfSelectedItem];
                if (idx >= 0) {
                    FOSPTZ_SPEED speed = idx;
                    config.info = &speed;
                    
                    success = [center setConfig:&config
                                        forType:FOSCAM_NET_CONFIG_PTZ_SPEED
                                       toDevice:device];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!success) [self alert:@"超时"];
                        [self setActivity:NO];
                    }); 
                }
            }
                break;
            case 1:
                assert(false);
                break;
            case 2: {
                NSInteger   idxOfStartUpOption = [self.startUpOptionsBtn indexOfSelectedItem];
                NSInteger   idxOfPresetOption  = [self.presetOptionBtn indexOfSelectedItem];
                NSString    *presetOption = nil;
         
                do {
                    config.info = &idxOfStartUpOption;
                    success = [center setConfig:&config
                                        forType:FOSCAM_NET_CONFIG_PTZ_SELF_TEST_MODE
                                       toDevice:device];
                    if (!success) break;
                    
                    presetOption = [NSString stringWithFormat:@"%ld",[self presetOptionRange].location + idxOfPresetOption];
                    config.info = (void *)presetOption.UTF8String;
                    success = [center setConfig:&config
                                        forType:FOSCAM_NET_CONFIG_PTZ_SELF_TEST_PRESET_NAME
                                       toDevice:device];
                }while (0);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!success) [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
            default:
                break;
        }
    });
}

- (void)refetch:(NSInteger)tag
{
    [self setActivity:YES];
    
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    __block FOSCAM_NET_CONFIG config;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^
    {
        switch (tag) {
            case 0: {
                int speed = 0;
                config.info = &speed;
                BOOL success = [center getConfig:&config
                                         forType:FOSCAM_NET_CONFIG_PTZ_SPEED
                                      fromDevice:self.device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) [self setSpeed:speed];
                    else [self alert:@"超时"];
                    
                    [self setActivity:NO];
                });
            }
                
                break;
            case 1: {
                FOS_CRUISECTRLMODE mode;
                config.info = &mode;
                
                BOOL success = [center getConfig:&config
                                         forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_CTRL_MODE
                                      fromDevice:self.device];
                
                unsigned int cruise_time;
                config.info = &cruise_time;
                success = [center getConfig:&config
                                    forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME
                                 fromDevice:self.device];
                
                FOS_CRUISETIMECUSTOMED cruise_time_customed;
                config.info = &cruise_time_customed;
                success = [center getConfig:&config
                                    forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME_CUSTOM
                                 fromDevice:self.device];
                
                int cruise_loop_cnt;
                config.info = &cruise_loop_cnt;
                success = [center getConfig:&config
                                    forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_LOOP_CNT
                                 fromDevice:self.device];
                
                FOS_CRUISEMAPLIST cruise_map_list;
                config.info = &cruise_map_list;
                success = [center getConfig:&config
                                    forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_LIST
                                 fromDevice:self.device];
                
                FOS_RESETPOINTLIST preset_point_list;
                config.info = &preset_point_list;
                success = [center getConfig:&config
                                    forType:FOSCAM_NET_CONFIG_PTZ_PRESET_POINT_LIST
                                 fromDevice:self.device];
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [self setCruiseCtrlMode:mode];
                        [self setCruiseTime:cruise_time];
                        [self setCruiseTimeCustomed:cruise_time_customed];
                        [self setCruiseLoopCnt:cruise_loop_cnt];
                        [self setCruiseMapList:cruise_map_list];
                        [self setPresetPointList:preset_point_list];
                        [self updateCruiseUI];
                    } else [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
            case 2: {
                //获取自检模式和自检模式预制位.
                int     self_test_mode;
                char    tmp[128];
                BOOL    success = NO;
                NSString *presetName = nil;
                memset(tmp, 0, 128);
                
                do {
                    config.info = &self_test_mode;
                    success = [center getConfig:&config
                                        forType:FOSCAM_NET_CONFIG_PTZ_SELF_TEST_MODE
                                     fromDevice:self.device];
                    if (!success) break;
                    config.info = tmp;
                    success = [center getConfig:&config
                                        forType:FOSCAM_NET_CONFIG_PTZ_SELF_TEST_PRESET_NAME
                                     fromDevice:self.device];
                    if (success) presetName = [NSString stringWithUTF8String:tmp];
                }while (0);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [self setSelfTestMode:self_test_mode];
                        [self setSelfTestPresetName:presetName];
                    }
                    else [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
            default: {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
        }
    });
}

#pragma mark - modify cruise map
- (void)movePresetPointToCruiseMap
{
    //移动预制点到巡检路径中
    NSInteger idxOfPresetPoint = [self.presetPointListTV selectedRow] + FOS_DEFAULT_PRESETPOINT_COUNT;
    NSInteger cruiseMapPointsCount = [self numberOfPresetPointsInCruiseMap];
    
    if (cruiseMapPointsCount < FOS_MAX_PRESETPOINT_COUNT_OF_MAP) {
        const char *presetPointName = self.presetPointList.pointName[idxOfPresetPoint];
        //修改路径中对应点的名称
        //结构体类型不能直接引用，需要copy一份，进行修改.
        FOS_CRUISEMAPINFO mapInfo = self.cruiseMapInfo;
        strcpy(mapInfo.pointName[cruiseMapPointsCount], presetPointName);
        self.cruiseMapInfo = mapInfo;
    }
}

- (void)moveOutPointFromCruiseMap
{
    NSInteger idxOfMapPoint = [self.cruiseMapInfoTV selectedRow];
    
    char newPointName[FOS_MAX_PRESETPOINT_COUNT_OF_MAP][FOS_MAX_CURISEMAP_NAME_LEN];
    int newPointTime[FOS_MAX_PRESETPOINT_COUNT_OF_MAP];
    //初始化
    for (int i = 0; i < FOS_MAX_PRESETPOINT_COUNT_OF_MAP; i++) {
        for (int j = 0; j < FOS_MAX_CURISEMAP_NAME_LEN; j++) {
            newPointName[i][j] = '\0';
            newPointTime[i] = 0;
        }
    }
    
    FOS_CRUISEMAPINFO mapInfoCopy = self.cruiseMapInfo;
    FOS_CRUISEMAPPREPOINTLINGERTIME mapPresetPointLingerTimeCopy = self.cruiseMapPrepointLingerTime;
    //遍历巡检轨迹,将合适的点添加进新容器内
    int c = 0;
    for (int idx = 0; idx < FOS_MAX_PRESETPOINT_COUNT_OF_MAP; idx++) {
        char *point = mapInfoCopy.pointName[idx];
        int time = mapPresetPointLingerTimeCopy.time[idx];
        if (c != idxOfMapPoint && strcmp("", point) != 0) {
            strcpy(newPointName[idx], point);
            newPointTime[idx] = time;
            c++;
        }
    }
    //复制
    for (int idx = 0; idx < FOS_MAX_PRESETPOINT_COUNT_OF_MAP; idx++) {
        strcpy(mapInfoCopy.pointName[idx], newPointName[idx]);
        mapPresetPointLingerTimeCopy.time[idx] = newPointTime[idx];
    }
    
    self.cruiseMapInfo = mapInfoCopy;
    self.cruiseMapPrepointLingerTime = mapPresetPointLingerTimeCopy;
}
#pragma mark - user interaction
- (IBAction)delete:(id)sender
{
    NSInteger clickedSegment = [sender selectedSegment];
    NSInteger clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
    
    if (0 == clickedSegmentTag) {
        [self moveOutPointFromCruiseMap];
        [self.cruiseMapInfoTV reloadData];
    }
}

- (IBAction)add:(id)sender
{
    NSInteger mapPointCount = [self numberOfPresetPointsInCruiseMap];
    if (mapPointCount < FOS_MAX_PRESETPOINT_COUNT_OF_MAP) {
        [self movePresetPointToCruiseMap];
        [self.cruiseMapInfoTV reloadData];
    } else {
        [self alert:@"超出路径点上限"];
    }
}

- (IBAction)saveCruiseConfig:(id)sender
{
    [self setActivity:YES];
    NSString *errMsg = nil;
    do {
        //保存巡航配置信息
        NSInteger idx = [self.cruiseModeBtn indexOfSelectedItem];
        if (idx < 0) {
            //未选择巡航模式
            errMsg = @"未选择巡航模式!";
            break;
        }
        self.cruiseCtrlMode = (FOS_CRUISECTRLMODE)idx;
        //巡航时间
        idx = [self.cruiseTimeBtn indexOfSelectedItem];
        if (idx < 0) {
            //未选择巡航时间
            errMsg = @"未选择巡航时间!";
            break;
        }
        self.cruiseTime = (unsigned int)idx;
        //巡航次数
        self.cruiseLoopCnt = (int)self.cruiseLoopCntTF.integerValue;
        //巡航自定义时间
        FOS_CRUISETIMECUSTOMED cruiseTimeCustomed;
        cruiseTimeCustomed.customed =
        ([self.cruiseTimeBtn indexOfSelectedItem] == [self availableCruiseTime].count -1);
        cruiseTimeCustomed.time = (int)self.cruiseTimeCustomedTF.integerValue;
        self.cruiseTimeCustomed = cruiseTimeCustomed;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^
        {
            DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
            FOSCAM_NET_CONFIG config;
            
            FOS_CRUISECTRLMODE mode = self.cruiseCtrlMode;
            config.info = &mode;
            __block BOOL success = [center setConfig:&config
                                             forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_CTRL_MODE
                                            toDevice:self.device];
            
            int count = (self.cruiseLoopCnt);
            config.info = &count;
            success = [center setConfig:&config
                                forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_LOOP_CNT
                               toDevice:self.device];
            
            unsigned int time = self.cruiseTime;
            config.info = &time;
            success = [center setConfig:&config
                                forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME
                               toDevice:self.device];
            
            FOS_CRUISETIMECUSTOMED time_customed = self.cruiseTimeCustomed;
            config.info = &time_customed;
            success = [center setConfig:&config
                                forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME_CUSTOM
                               toDevice:self.device];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success) [self alert:@"超时"];
                [self setActivity:NO];
            });
        });
        return;
    }
    while (0);
    
    //处理错误提示
    [self alert:errMsg];
    [self setActivity:NO];
}

- (IBAction)removeCruiseMap:(id)sender
{
    [self setActivity:YES];
    NSInteger selectedIdx = [self.cruiseTracksBtn indexOfSelectedItem];
    if (selectedIdx >= 0) {
        //清空map info
        DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
        __block FOSCAM_NET_CONFIG config;
        __block BOOL success = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            NSString *mapName = [NSString stringWithFormat:@"%ld",selectedIdx + 1];
            config.info = (char *)mapName.UTF8String;
            success = [center setConfig:&config
                                forType:FOSCAM_NET_CONFIG_PTZ_PATTERN_DEL
                               toDevice:self.device];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success) [self alert:@"超时"];
                [self refetchMapInfoWithMapName:mapName];
                [self setActivity:NO];
            });
        });
    }
}

- (IBAction)saveCruiseMap:(id)sender
{
    //通知tableview 停止编辑
    [[[NSApplication sharedApplication] keyWindow] endEditingFor:self.cruiseMapInfoTV];
    [self setActivity:YES];
    NSInteger selectedIdx = [self.cruiseTracksBtn indexOfSelectedItem];
    
    if (selectedIdx >= 0) {
        NSString                        *mapName = [NSString stringWithFormat:@"%ld",selectedIdx + 1];
        FOS_CRUISEMAPPREPOINTLINGERTIME mapPrepointTingerTime = self.cruiseMapPrepointLingerTime;
        FOS_CRUISEMAPINFO               mapInfo = self.cruiseMapInfo;
        
        strcpy(mapInfo.cruiseMapName, mapName.UTF8String);
        strcpy(mapPrepointTingerTime.cruiseMapName, mapName.UTF8String);
        NSLog(@"Tracing:获取到了最新的tinger time");
        //首先移除，再添加
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            DispatchCenter      *center = [DispatchCenter sharedDispatchCenter];
            FOSCAM_NET_CONFIG   config;
            BOOL                success = NO;
            
            do {
                config.info = (char *)mapName.UTF8String;
                success = [center setConfig:&config
                                    forType:FOSCAM_NET_CONFIG_PTZ_PATTERN_DEL
                                   toDevice:self.device];
                if (!success) break;
                
                config.info = (void *)&mapInfo;
                success = [center setConfig:&config
                                    forType:FOSCAM_NET_CONFIG_PTZ_PATTERN_MAP_INFO
                                   toDevice:self.device];
                if (!success) break;
                
                config.info = (void *)&mapPrepointTingerTime;
                success = [center setConfig:&config
                                    forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_PREPOINT_TINGGER_TIME
                                   toDevice:self.device];
            }while (0);
            //异步回主线程显示
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success) [self alert:@"超时"];
                [self refetchMapInfoWithMapName:mapName];
                [self setActivity:NO];
            });
        });
    }
}

#pragma mark - update UI
- (void)updateSpeedUI
{
    int idx = self.speed;
    if (idx >= 0 && idx < [self availableSpeed].count)
        [self.speedBtn selectItemAtIndex:idx];
}

- (void)updateCruiseUI
{
    //巡航模式
    NSInteger idx = self.cruiseCtrlMode;
    if (idx >= 0 && idx < [self availableCruiseMode].count)
        [self.cruiseModeBtn selectItemAtIndex:idx];
    //根据巡航模式，决定是否启用巡航时间
    self.cruiseTimeMode = self.cruiseModeBtn.indexOfSelectedItem == ([self availableCruiseMode].count - 1);
    
    
    //巡航时间
    NSInteger customed = self.cruiseTimeCustomed.customed;
    if (customed) {
        //自定义
        NSInteger time = self.cruiseTimeCustomed.time;
        [self.cruiseTimeCustomedTF setIntegerValue:time];
        
        NSInteger idx = [self availableCruiseTime].count - 1;
        [self.cruiseTimeBtn selectItemAtIndex:idx];
    } else {
        idx = self.cruiseTime;
        if (idx >= 0 && idx < [self availableCruiseTime].count)
            [self.cruiseTimeBtn selectItemAtIndex:idx];
    }
    //根据巡航时间，决定是否启用自定义巡航时间
    self.customedCruiseTime = self.cruiseTimeBtn.indexOfSelectedItem != ([self availableCruiseTime].count -1);
    
    //巡航次数
    NSInteger count = self.cruiseLoopCnt;
    if (count >= 0)
        [self.cruiseLoopCntTF setIntegerValue:count];
    
    //巡航轨迹列表
    FOS_CRUISEMAPLIST cruise_map_list = self.cruiseMapList;
    if (cruise_map_list.cruiseMapCnt > 0) {
//        [self.cruiseTracksCB reloadData];
//        [self.cruiseTracksCB selectItemAtIndex:0];
    }
    //巡航轨迹信息
    [self updateCruiseMapInfoUI];
    
    [self refetchMapInfoWithMapName:[NSString stringWithFormat:@"%ld",self.cruiseTracksBtn.indexOfSelectedItem + 1]];
}

- (void)updateCruiseMapInfoUI
{
    [self.presetPointListTV reloadData];
    [self.cruiseMapInfoTV reloadData];
}

- (void)updateStartUpModeUI
{
    int idx = self.selfTestMode;
    if (idx >= 0 && idx < [self availableSelfTestMode].count)
        [self.startUpOptionsBtn selectItemAtIndex:idx];
    self.hidePresetOption = (2 == self.startUpOptionsBtn.indexOfSelectedItem);
}

- (void)updateStartUpPresetUI
{
    NSString    *presetName = self.selfTestPresetName;
    NSRange     presetRange = [self presetOptionRange];
    NSUInteger  selectedIdx = 0;
    
    for (NSInteger idx = 0; idx < presetRange.length; idx++) {
        NSString *name = [NSString stringWithFormat:@"%ld",idx + presetRange.location];
        if ([presetName isEqualToString:name]) {
            selectedIdx = idx;
            break;
        }
    }
    [self.presetOptionBtn selectItemAtIndex:selectedIdx];
}
#pragma mark - data
- (NSRange)presetOptionRange
{
    return NSMakeRange(1, 8);
}

- (NSArray *)availableSpeed
{
    return @[@"非常快",@"快",@"正常",@"慢",@"非常慢"];
}

- (NSArray *)availableCruiseMode
{
    return @[@"巡航时间",@"巡航圈数"];
}

- (NSArray*)availableCruiseTime
{
    return @[@"15分钟",@"30分钟",@"1小时",@"2小时",@"无限制",@"自定义（单位：分钟）"];
}

- (NSArray *)availableSelfTestMode
{
    return @[@"不自检",@"正常启动",@"启动后到预制点"];
}

- (NSArray*)comboboxIDs
{
    static NSArray *comboboxIDs;
    
    if (!comboboxIDs) {
        comboboxIDs = @[CBID_SPEED,CBID_CRUISE_MODE,CBID_CRUISE_TIME,CBID_CRUISE_MAP_LIST,CBID_SELF_TEST_MODE];
    }
    return comboboxIDs;
}

- (NSArray *)tableViewIDs
{
    static NSArray *tableViewIDs;
    
    if (!tableViewIDs) {
        tableViewIDs = @[TVID_PRESET_POINT_LIST,TVID_CRUISE_MAP_INFO];
    }
    return tableViewIDs;
}

- (NSInteger)numberOfPresetPointsInCruiseMap
{
    NSInteger count = 0;
    
    for (int idx = 0; idx < FOS_MAX_PRESETPOINT_COUNT_OF_MAP; idx++) {
        NSString *point = [NSString stringWithUTF8String:self.cruiseMapInfo.pointName[idx]];
        if (![point isEqualToString:@""]) {
            count++;
        }
    }
    return count;
}

- (NSRange)cruiseMapRange
{
    return NSMakeRange(1, VMS_MAX_CURISEMAP_COUNT);
}
#pragma mark - combobox datasource
- (void)refetchMapInfoWithMapName :(NSString *)name
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^
    {
        FOSCAM_NET_CONFIG_TEST test;
        __block FOS_CRUISEMAPINFO map_info;
        FOSCAM_NET_CONFIG config;
        test.input = (void *)name.UTF8String;
        test.result = &map_info;
        config.info = &test;
        
        DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
        BOOL success = [center getConfig:&config
                                 forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_INFO
                              fromDevice:self.device];
        
        __block FOS_CRUISEMAPPREPOINTLINGERTIME prepointLingerTime;
        test.result = &prepointLingerTime;
        success = [center getConfig:&config
                            forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_PREPOINT_TINGGER_TIME
                         fromDevice:self.device];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success) {
                strcpy(map_info.cruiseMapName, name.UTF8String);
                for (int i = 0; i<FOS_MAX_PRESETPOINT_COUNT_OF_MAP; i++) {
                    strcpy(map_info.pointName[i], "");
                }
                
                strcpy(prepointLingerTime.cruiseMapName, name.UTF8String);
                for (int i = 0; i<FOS_MAX_PRESETPOINT_COUNT_OF_MAP; i++) {
                    prepointLingerTime.time[i] = 0;
                }
            }
            [self setCruiseMapInfo:map_info];
            [self setCruiseMapPrepointLingerTime:prepointLingerTime];
            [self setActivity:NO];
        });
    });
}

//- (void)comboBoxSelectionDidChange:(NSNotification *)notification;
//{
//    NSComboBox *sender = notification.object;
//    NSInteger cbIndex = [[self comboboxIDs] indexOfObject:sender.identifier];
//    
//    switch (cbIndex) {
//        case 0:
//            break;
//        case 1:
//            self.cruiseTimeMode = self.cruiseModeCB.indexOfSelectedItem == ([self availableCruiseMode].count - 1);
//            break;
//        case 2:
//            self.customedCruiseTime = self.cruiseTimeCB.indexOfSelectedItem != ([self availableCruiseTime].count -1);
//            break;
//        case 3: {
//            //切换轨迹，重载轨迹信息
//            //获取路径名
//            NSInteger selectedIdx = [sender indexOfSelectedItem];
//            NSString *cruisePathName = [NSString stringWithFormat:@"%ld",selectedIdx + 1];
//            [self refetchMapInfoWithMapName:cruisePathName];
//        }
//            break;
//        default:
//            break;
//    }
//}

#pragma mark - tableview datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger idx = [[self tableViewIDs] indexOfObject:tableView.identifier];
    
    switch (idx) {
        case 0:
            return self.presetPointList.pointCnt - FOS_DEFAULT_PRESETPOINT_COUNT;
        case 1:
            return [self numberOfPresetPointsInCruiseMap];
        default:
            break;
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSInteger idx = [[self tableViewIDs] indexOfObject:tableView.identifier];
    NSString *cIdentifier = tableColumn.identifier;
    switch (idx) {
        case 0: {
            if ([cIdentifier isEqualToString:TVCID_NUMBER])
                return [NSNumber numberWithInteger:row];
            else
                return [NSString stringWithUTF8String:self.presetPointList.pointName[row + FOS_DEFAULT_PRESETPOINT_COUNT]];
        }
        case 1:{
            if ([cIdentifier isEqualToString:TVCID_NUMBER])
                return [NSNumber numberWithInteger:row];
            else if ([cIdentifier isEqualToString:TVCID_NAME])
                return [NSString stringWithUTF8String:self.cruiseMapInfo.pointName[row]];
            else
                return [NSNumber numberWithInt:self.cruiseMapPrepointLingerTime.time[row]];
        }
            break;
        default:
            break;
    }
    return nil;
}
#pragma mark - tableview delegate

- (void)tableView:(NSTableView *)tableView
   setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row
{
    NSString *tIdentifier = [tableView identifier];
    NSString *cIdentifier = [tableColumn identifier];
    
    if ([tIdentifier isEqualToString:TVID_CRUISE_MAP_INFO] &&
        [cIdentifier isEqualToString:TVCID_TIME]) {
        
        NSString *time = object;
        FOS_CRUISEMAPPREPOINTLINGERTIME cruiseLingerTime = self.cruiseMapPrepointLingerTime;
        cruiseLingerTime.time[row] = [time intValue];
        self.cruiseMapPrepointLingerTime = cruiseLingerTime;
        NSLog(@"Tracing:更新了最新的tinger time");
    }
    
    [self.cruiseMapInfoTV reloadData];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [super tabView:tabView didSelectTabViewItem:tabViewItem];
    
    NSInteger idx = [tabView indexOfTabViewItem:tabViewItem];
    [self.saveBT setHidden:(idx == 1)];
}
#pragma mark - setter && getter
- (void)setSpeed:(int)speed
{
    _speed = speed;
    [self updateSpeedUI];
}

- (void)setCruiseMapInfo:(FOS_CRUISEMAPINFO)cruiseMapInfo
{
    _cruiseMapInfo = cruiseMapInfo;
    [self updateCruiseMapInfoUI];
}

- (void)setSelfTestMode:(int)selfTestMode
{
    _selfTestMode = selfTestMode;
    [self updateStartUpModeUI];
}

- (void)setSelfTestPresetName:(NSString *)selfTestPresetName
{
    _selfTestPresetName = selfTestPresetName;
    [self updateStartUpPresetUI];
}
- (void)setSpeedBtn:(NSPopUpButton *)speedBtn
{
    _speedBtn = speedBtn;
    [self setControl:_speedBtn withTitles:[self availableSpeed]];
}

- (void)setStartUpOptionsBtn:(NSPopUpButton *)startUpOptionsBtn
{
    _startUpOptionsBtn = startUpOptionsBtn;
    [self setControl:_startUpOptionsBtn withTitles:[self availableSelfTestMode]];
}

- (void)setCruiseModeBtn:(NSPopUpButton *)cruiseModeBtn
{
    _cruiseModeBtn = cruiseModeBtn;
    [self setControl:_cruiseModeBtn withTitles:[self availableCruiseMode]];
}

- (void)setCruiseTimeBtn:(NSPopUpButton *)cruiseTimeBtn
{
    _cruiseTimeBtn = cruiseTimeBtn;
    [self setControl:_cruiseTimeBtn withTitles:[self availableCruiseTime]];
}

- (void)setCruiseTracksBtn:(NSPopUpButton *)cruiseTracksBtn
{
    _cruiseTracksBtn = cruiseTracksBtn;
    [self setControl:_cruiseTracksBtn withRange:[self cruiseMapRange]];
}

- (void)setPresetOptionBtn:(NSPopUpButton *)presetOptionBtn
{
    _presetOptionBtn = presetOptionBtn;
    [self setControl:_presetOptionBtn withRange:[self presetOptionRange]];
}
@end
