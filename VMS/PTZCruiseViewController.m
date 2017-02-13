//
//  PTZCruiseViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "PTZCruiseViewController.h"


#define TVID_PRESET_POINT_LIST  @"preset point list"
#define TVID_CRUISE_MAP_INFO    @"cruise map info"

#define TVCID_NAME              @"name"
#define TVCID_TIME              @"time"

@interface PTZCruiseViewController ()

@property(nonatomic,weak) IBOutlet NSView *zone1;
@property(nonatomic,weak) IBOutlet NSView *zone2;
@property(nonatomic,weak) IBOutlet NSButton *saveBT;
@property(nonatomic,weak) IBOutlet NSPopUpButton *cruiseModeBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *cruiseTimeBtn;
@property(nonatomic,weak) IBOutlet NSTextField *cruiseTimeCustomedTF;
@property(nonatomic,weak) IBOutlet NSTextField *cruiseLoopCntTF;
@property(nonatomic,weak) IBOutlet NSPopUpButton *cruiseTracksBtn;
@property(nonatomic,weak) IBOutlet NSTableView *presetPointListTV;
@property(nonatomic,weak) IBOutlet NSTableView *cruiseMapInfoTV;
@property(nonatomic,weak) IBOutlet NSView *placeHolder;
@property(nonatomic,weak) IBOutlet NSView *cruiseMapNameEditView;
@property(nonatomic,weak) IBOutlet NSView *cruiseMapListEditView;
@property(nonatomic,weak) IBOutlet NSTextField *cruiseNameTF;
@property(nonatomic,weak) IBOutlet NSButton *moveInBtn;
@property(nonatomic,weak) IBOutlet NSSegmentedControl *moveOutBtn;
@property(nonatomic,weak) IBOutlet NSButton *doneBtn;
@property(nonatomic,weak) IBOutlet NSTextField *timeLabel;

@property(nonatomic,assign,getter=isCustomedCruiseTime) BOOL customedCruiseTime;
@property(nonatomic,assign,getter=isCruiseTimeMode) BOOL cruiseTimeMode;
@property(nonatomic,assign) int curCruiseMapIdx;

@end

@implementation PTZCruiseViewController

#pragma mark - public api
- (void)fetchPresetPointAndCruiseMapList
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOS_CRUISEMAPLIST cruiseMapList;
        FOS_RESETPOINTLIST preSetPointList;
        void *infos[] = {
            &cruiseMapList,
            &preSetPointList,
            NULL
        };
        int types[] = {
            FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_LIST,
            FOSCAM_NET_CONFIG_PTZ_PRESET_POINT_LIST,
        };
        
        FOSCAM_NET_CONFIG config;
        BOOL success = YES;
        for (int i = 0;; i++) {
            if (!success || infos[i] == NULL) {
                break;
            }
            
            config.info = infos[i];
            success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                               forType:types[i]
                                                            fromDevice:self.device];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.fetchPresetPtsCompleteHandle(success,preSetPointList,cruiseMapList,self);
        });
    });
}

- (void)fetchCruiseMode
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOS_CRUISECTRLMODE mode;
        FOS_CRUISETIMECUSTOMED cruiseTimeCustomed;
        unsigned int cruiseTime;
        int cruiseLoopCnt;

        void *infos[] = {
            &mode,
            &cruiseTime,
            &cruiseTimeCustomed,
            &cruiseLoopCnt,
            NULL
        };
        int types[] = {
            FOSCAM_NET_CONFIG_PTZ_CRUISE_CTRL_MODE,
            FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME,
            FOSCAM_NET_CONFIG_PTZ_CRUISE_TIME_CUSTOM,
            FOSCAM_NET_CONFIG_PTZ_CRUISE_LOOP_CNT,
        };
        
        FOSCAM_NET_CONFIG config;
        BOOL success = YES;
        for (int i = 0;; i++) {
            if (!success || infos[i] == NULL) {
                break;
            }
            
            config.info = infos[i];
            success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                               forType:types[i]
                                                            fromDevice:self.device];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self.cruiseTracksBtn selectItemAtIndex:0];
                [self setCruiseCtrlMode:mode];
                [self setCruiseTime:cruiseTime];
                [self setCruiseTimeCustomed:cruiseTimeCustomed];
                [self setCruiseLoopCnt:cruiseLoopCnt];
            } else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (void)fetchCruiseInfo :(NSString *)name
{
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOS_CRUISEMAPINFO map_info;
        FOS_CRUISEMAPPREPOINTLINGERTIME prepointLingerTime;
        memset(&map_info, 0, sizeof(FOS_CRUISEMAPINFO));
        memset(&prepointLingerTime, 0, sizeof(FOS_CRUISEMAPPREPOINTLINGERTIME));
        [name getCString:map_info.cruiseMapName maxLength:128 encoding:NSASCIIStringEncoding];
        [name getCString:prepointLingerTime.cruiseMapName maxLength:128 encoding:NSASCIIStringEncoding];
        
        
        void *infos[] = {
            &map_info,
            &prepointLingerTime,
            NULL
        };
        int types[] = {
            FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_INFO,
            FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_PREPOINT_TINGGER_TIME,
        };
        
        FOSCAM_NET_CONFIG config;
        BOOL success = YES;
        for (int i = 0;; i++) {
            if (!success || infos[i] == NULL) {
                break;
            }
            
            config.info = infos[i];
            success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                               forType:types[i]
                                                            fromDevice:self.device];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setCruiseMapInfo:map_info];
                [self setCruiseMapPrepointLingerTime:prepointLingerTime];
            } else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (void)performRemoveCruiseMap :(NSString *)mapName
{
    //清空map info
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NET_CONFIG config;
        char cruiseMapName[FOS_MAX_CURISEMAP_NAME_LEN] = {0};
        BOOL success = NO;
        
        if ([mapName getCString:cruiseMapName
                      maxLength:FOS_MAX_CURISEMAP_NAME_LEN
                       encoding:NSASCIIStringEncoding]) {
            
            config.info = cruiseMapName;
            success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                               forType:FOSCAM_NET_CONFIG_PTZ_PATTERN_DEL
                                                              toDevice:self.device];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success)
                [self alert:NSLocalizedString(@"failed to remove", nil)
                       info:@""];
            [self setActivity:NO];
        });
    });
}

- (void)performSaveCruiseMap :(NSString *)mapName
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
       
        FOSCAM_NET_CONFIG               config;
        FOS_CRUISEMAPPREPOINTLINGERTIME mapPrepointTingerTime = self.cruiseMapPrepointLingerTime;
        FOS_CRUISEMAPINFO               mapInfo = self.cruiseMapInfo;
        
        [mapName getCString:mapInfo.cruiseMapName maxLength:FOS_MAX_CURISEMAP_NAME_LEN encoding:NSASCIIStringEncoding];
        [mapName getCString:mapPrepointTingerTime.cruiseMapName maxLength:FOS_MAX_CURISEMAP_NAME_LEN encoding:NSASCIIStringEncoding];
        
        void *infos[] = {
            &mapInfo,
            &mapPrepointTingerTime
        };
        
        FOSCAM_NET_CONFIG_TYPE types[] = {
            FOSCAM_NET_CONFIG_PTZ_PATTERN_MAP_INFO,
            FOSCAM_NET_CONFIG_PTZ_CRUISE_MAP_PREPOINT_TINGGER_TIME
        };
        
        BOOL success = YES;
        for (int i = 0; (i < 2) && success; i++) {
            config.info = infos[i];
            success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                               forType:types[i]
                                                              toDevice:self.device];
        }
    
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success)
                [self alert:NSLocalizedString(@"failed to save cruise track", nil)
                       info:@""];
            [self setActivity:NO];
        });
    });
}

- (void)fetch
{
    self.curCruiseMapIdx = 0;
    [self fetchCruiseMode];
    [self fetchPresetPointAndCruiseMapList];
}

- (void)push
{}

- (NSString *)description
{
    return NSLocalizedString(@"Cruise Settings", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH;
}

- (BOOL)enableCruiseModeOption
{
    return YES;
}
- (BOOL)enableCruiseMapPrepointLingerTime
{
    return YES;
}

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDispatchCenterNotification:)
                                                 name:DEVICE_CRUISE_MAP_DID_CHANGE_NOTIFICATION
                                               object:nil];
}

- (void)dealloc
{
    NSLog(@"Running in class %@,selector %@",self.className,NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - notification
- (void)handleDispatchCenterNotification :(NSNotification *)aNotific
{
    NSString *name = aNotific.name;
    NSDictionary *userInfo = aNotific.userInfo;
    
    
    if (self.device.uniqueId != [[userInfo valueForKey:KEY_EVENT_DEVICE_ID] longValue])
        return;
    
    if ([name isEqualToString:DEVICE_CRUISE_MAP_DID_CHANGE_NOTIFICATION]) {
        NSData *data = [userInfo valueForKey:KEY_CRUISE_MAP];

        if (data) {
            FOSCRUISEMAP cruiseMap;
            FOS_CRUISEMAPLIST cruiseList;
            
            [data getBytes:&cruiseMap length:sizeof(FOSCRUISEMAP)];
            
            cruiseList.cruiseMapCnt = cruiseMap.cnt;
            
            for (int i = 0; i < FOS_MAX_CURISEMAP_COUNT; i++) {
                strcpy(cruiseList.cruiseMapName[i], cruiseMap.mapList[i]);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.cruiseMapList = cruiseList;
            });
        }
    }
}

#pragma mark - action
- (IBAction)cruiseButtonAction :(id)sender
{
    NSInteger tag = [sender tag];
    
    switch (tag) {
        case 0:
            self.cruiseTimeMode = self.cruiseModeBtn.indexOfSelectedItem == ([self availableCruiseMode].count - 1);
            //self.customedCruiseTime = self.cruiseTimeMode && (self.cruiseTimeBtn.indexOfSelectedItem == ([self availableCruiseTime].count -1));
            
            break;
            
        case 1:
            self.customedCruiseTime = self.cruiseTimeBtn.indexOfSelectedItem == ([self availableCruiseTime].count -1);
            break;
            
        case 2: {
            int cruiseMapIdx = (int)self.cruiseTracksBtn.indexOfSelectedItem;
            if (self.curCruiseMapIdx != cruiseMapIdx) {
                self.curCruiseMapIdx = cruiseMapIdx;
                [self fetchCruiseInfo:self.cruiseTracksBtn.titleOfSelectedItem];
            }
        }
            break;
        default:
            break;
    }
}


#pragma mark - layout
- (void)setup
{
    if (![self enableCruiseModeOption]) {
        [self.zone1.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setHidden:YES];
        }];
        
        NSPoint origin = self.zone2.frame.origin;
        origin.y += self.zone1.frame.size.height;
        [self.zone2 setFrameOrigin:origin];
    }
    [self toggleCruiseMapView:0];
}

- (void)toggleCruiseMapView :(int)tag
{
    [self.cruiseMapListEditView removeFromSuperview];
    [self.cruiseMapNameEditView removeFromSuperview];
    
    NSView *view = ((0 == tag)? self.cruiseMapListEditView : self.cruiseMapNameEditView);
    
    CGFloat x = self.placeHolder.frame.origin.x;
    CGFloat y = self.placeHolder.frame.origin.y;
    CGFloat h = self.placeHolder.frame.size.height;
    
    [self.zone2 addSubview:view];
    [view setFrameOrigin:NSMakePoint(x, y + h - view.frame.size.height)];
}

#pragma mark - modify cruise map
/*
 *brief:move point from preset point list to cruise point list.
 *return:0-success | 1-full | 2-duplicate
 */
- (int)movePresetPointToCruiseMap
{
    //移动预制点到巡检路径中
    NSInteger idxOfPresetPoint      = [self.presetPointListTV selectedRow];
    NSInteger cruiseMapPointsCount  = [self numberOfPresetPointsInCruiseMap];
    
    if (cruiseMapPointsCount < FOS_MAX_PRESETPOINT_COUNT_OF_MAP) {
        const char *presetPointName = self.presetPointList.pointName[idxOfPresetPoint];
        //修改路径中对应点的名称
        //结构体类型不能直接引用，需要copy一份，进行修改.
        FOS_CRUISEMAPINFO mapInfo = self.cruiseMapInfo;
        
        if (cruiseMapPointsCount > 0) {
            //查看是否存在连续的重复预置点
            char *lastPointName =  mapInfo.pointName[cruiseMapPointsCount - 1];
            if (0 == strcmp(lastPointName, presetPointName))
                return 2;
        }
        
        strcpy(mapInfo.pointName[cruiseMapPointsCount], presetPointName);
        self.cruiseMapInfo = mapInfo;
    
        return 0;
    }
    
    return 1;
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
    int destIdx = 0;
    for (int srcIdx = 0; srcIdx < FOS_MAX_PRESETPOINT_COUNT_OF_MAP; srcIdx++) {
        char *point = mapInfoCopy.pointName[srcIdx];
        int time = mapPresetPointLingerTimeCopy.time[srcIdx];
        
        if ((srcIdx != idxOfMapPoint) && (strcmp("", point) != 0)) {
            strcpy(newPointName[destIdx], point);
            newPointTime[destIdx] = time;
            destIdx++;
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


#pragma mark - edit cruise map
- (BOOL)addable
{
    //满足一下条件可以添加巡航路径
    //1、巡航路径名称长度(0,20],支持英文、数字、字母及符号_-
    //2、至少两个预置点
    
    NSString *name = self.cruiseNameTF.stringValue;
    
    if (name.length > 0 && name.length <= 20 && [name isMatchedByRegex:@"^[0-9a-zA-Z_-]*$"]) {
        return [self numberOfPresetPointsInCruiseMap] > 1;
    }
    
    return NO;
}

- (void)onEdit
{
    self.doneBtn.enabled = [self addable];
}

- (void)beginEditCruiseMap
{
    self.cruiseNameTF.stringValue = @"";
    self.moveInBtn.enabled = YES;
    self.moveOutBtn.enabled = YES;
    self.doneBtn.enabled = NO;
    
    FOS_CRUISEMAPINFO cruiseMapInfo;
    memset(&cruiseMapInfo, 0, sizeof(FOS_CRUISEMAPINFO));
    
    self.cruiseMapInfo = cruiseMapInfo;
    
    
    [self toggleCruiseMapView:1];
}

- (void)endEditCruiseMap
{
    self.moveInBtn.enabled = NO;
    self.moveOutBtn.enabled = NO;
    
    [self toggleCruiseMapView:0];
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
    
    [self onEdit];
}

- (IBAction)add:(id)sender
{
    NSString    *errMsg = nil;
    
    switch ([self movePresetPointToCruiseMap]) {
        case 0:
            [self.cruiseMapInfoTV reloadData];
            break;
        case 1:
            errMsg = NSLocalizedString(@"maximum number of cruise path points exceeded", nil);
            break;
        case 2:
            errMsg = NSLocalizedString(@"two consecutive preset points can not be the same", nil);
            break;
        default:
            break;
    }
    
    if (errMsg)
        [self alert:NSLocalizedString(@"failed to add",nil)
               info:errMsg];
    
    [self onEdit];
}

#define MAX_CRUISE_TIME 10080
- (IBAction)saveCruiseConfig:(id)sender
{
    [self setActivity:YES];
    NSString *errMsg = nil;
    do {
        //保存巡航配置信息
        NSInteger idx = [self.cruiseModeBtn indexOfSelectedItem];
        if (idx < 0) {
            //未选择巡航模式
            errMsg = NSLocalizedString(@"Unchecked", nil);
            break;
        }
        self.cruiseCtrlMode = (FOS_CRUISECTRLMODE)idx;
        //巡航时间
        idx = [self.cruiseTimeBtn indexOfSelectedItem];
        if (idx < 0) {
            //未选择巡航时间
            errMsg = NSLocalizedString(@"Unchecked", nil);
            break;
        }
        self.cruiseTime = (unsigned int)idx;
        //巡航次数
        self.cruiseLoopCnt = (int)self.cruiseLoopCntTF.integerValue;
        
        if ((self.cruiseCtrlMode == CRUISECTRLMODE_LOOPCOUNT) &&
            (self.cruiseLoopCnt < 1 || self.cruiseLoopCnt > 100)) {
            errMsg = NSLocalizedString(@"invalid loops", nil);
            break;
        }
        
        //巡航自定义时间
        FOS_CRUISETIMECUSTOMED cruiseTimeCustomed;
        cruiseTimeCustomed.customed =
        ([self.cruiseTimeBtn indexOfSelectedItem] == [self availableCruiseTime].count -1);
        cruiseTimeCustomed.time = (int)self.cruiseTimeCustomedTF.integerValue;
        self.cruiseTimeCustomed = cruiseTimeCustomed;
        
        if ((self.cruiseCtrlMode == CRUISECTRLMODE_TIME) &&
            (cruiseTimeCustomed.customed == 1) &&
            (cruiseTimeCustomed.time > MAX_CRUISE_TIME)) {
            errMsg = NSLocalizedString(@"invalid cruise time", nil);
            break;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
            FOSCAM_NET_CONFIG config;
            FOS_CRUISECTRLMODE mode = self.cruiseCtrlMode;
            
            config.info = &mode;
            //保存巡航模式
            BOOL success = NO;
            if ([center setConfig:&config
                          forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_CTRL_MODE
                         toDevice:self.device]) {
                switch (mode) {
                    case CRUISECTRLMODE_TIME: {
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
                    }
                        break;
                        
                    case CRUISECTRLMODE_LOOPCOUNT: {
                        int count = (self.cruiseLoopCnt);
                        config.info = &count;
                        success = [center setConfig:&config
                                            forType:FOSCAM_NET_CONFIG_PTZ_CRUISE_LOOP_CNT
                                           toDevice:self.device];
                    }
                        break;
                        
                    default:
                        break;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success)
                    [self alert:NSLocalizedString(@"failed to set the settings", nil)
                           info:NSLocalizedString(@"time out",nil)];
                
                [self setActivity:NO];
            });
        });
        
        return;
    }while (0);
    
    //处理错误提示
    [self alert:NSLocalizedString(@"failed to set the settings", nil)
           info:errMsg];
    [self setActivity:NO];
}

- (int)addCruiseMapWithName :(NSString *)name
{
    [[[NSApplication sharedApplication] keyWindow] endEditingFor:self.cruiseMapInfoTV];
    
    if ([name isEqualToString:@""])
        return 1;
    
    if ([self numberOfPresetPointsInCruiseMap] < 2)
        return 2;
    
    FOS_CRUISEMAPINFO cruiseMapInfo = self.cruiseMapInfo;
    
    if ([self isCruiseMapDuplicate:&cruiseMapInfo])
        return 3;
    
    [self performSaveCruiseMap :name];
    
    return 0;
}

- (NSString *)errMsg :(int)code
{
    switch (code) {
        case 0:
            return NSLocalizedString(@"success", nil);
            
        case 1:
            return NSLocalizedString(@"empty cruise track name", nil);
            
        case 2:
            return NSLocalizedString(@"The number of preset points of cruise path is less than 2", nil);
            
        case 3:
            return NSLocalizedString(@"two consecutive preset points can not be the same", nil);
            
        default:
            return NSLocalizedString(@"unknow error", nil);
    }
}

const int minPerDay = 1440;
const int minPerHour = 60;

- (NSString *)timeFromMin :(int)value
{
    NSString *time = @"";
    int day = value / minPerDay;
    int tmp = value % minPerDay;
    int hour = tmp / minPerHour;
    int min = tmp % minPerHour;
    
    if (day > 0) {
        time = [NSString stringWithFormat:@"%@ %d%@",time,day,NSLocalizedString(@"Days", nil)];
    }
    
    if (hour > 0) {
        time = [NSString stringWithFormat:@"%@ %d%@",time,hour,NSLocalizedString(@"Hours", nil)];
    }
    
    if (min > 0) {
        time = [NSString stringWithFormat:@"%@ %d%@",time,min,NSLocalizedString(@"Minutes", nil)];
    }
    
    return time;
}

- (IBAction)addCruiseMap:(id)sender
{
    switch ([(NSButton *)sender tag]) {
        case 0:{
            //确定
            //通知tableview 停止编辑
            int code = [self addCruiseMapWithName:self.cruiseNameTF.stringValue];
            
            if (code != 0) {
                [self alert:NSLocalizedString(@"failed to add",nil)
                       info:[self errMsg :code]];
                return;
            }
        }
            break;
            
        case 1:
            //取消
            [self fetchCruiseInfo:self.cruiseTracksBtn.titleOfSelectedItem];
            break;
        default:
            break;
    }
    [self endEditCruiseMap];
}

- (IBAction)editCruiseMap :(id)sender
{
    [self beginEditCruiseMap];
}

- (IBAction)removeCruiseMap:(id)sender
{
    if (self.cruiseTracksBtn.indexOfSelectedItem < 2)
        [self alert:NSLocalizedString(@"failed to remove", nil)
               info:NSLocalizedString(@"default cruise track cannot be removed", nil)];
    else
        [self performRemoveCruiseMap:[self.cruiseTracksBtn titleOfSelectedItem]];
}

- (BOOL)isCruiseMapDuplicate :(FOS_CRUISEMAPINFO *)info
{
    char lastPtName[FOS_MAX_CURISEMAP_NAME_LEN] = {0};
    
    for (int i = 0; i < FOS_MAX_PRESETPOINT_COUNT_OF_MAP; i++) {
        char *ptName = info->pointName[i];
        
        if (strcmp(ptName, "") == 0)
            continue;
    
        if (strcmp(ptName, lastPtName) == 0)
            return YES;
        
        strcpy(lastPtName, ptName);
    }
    
    return NO;
}

- (IBAction)saveCruiseMap:(id)sender
{
    NSString *name = self.cruiseTracksBtn.titleOfSelectedItem;
    int code = [self addCruiseMapWithName:name];
    
    if (0 != code) {
        [self alert:NSLocalizedString(@"failed to save cruise track", nil)
               info:[self errMsg :code]];
    }
}

#pragma mark - update UI
- (void)updateCruiseCtrlModeUI
{
    //巡航模式
    NSInteger idx = self.cruiseCtrlMode;
    if (idx >= 0 && idx < [self availableCruiseMode].count)
        [self.cruiseModeBtn selectItemAtIndex:idx];
    //根据巡航模式，决定是否启用巡航时间
    self.cruiseTimeMode = self.cruiseModeBtn.indexOfSelectedItem == ([self availableCruiseMode].count - 1);
}

- (void)updateCruiseTimeUI
{
    NSUInteger idx = self.cruiseTime;
    if (idx < [self availableCruiseTime].count)
        [self.cruiseTimeBtn selectItemAtIndex:idx];
}

- (void)updateCruiseTimeCustomedUI
{
    self.customedCruiseTime = self.cruiseTimeCustomed.customed;
    if (self.customedCruiseTime) {
        NSUInteger idx = [self availableCruiseTime].count - 1;
        [self.cruiseTimeBtn selectItemAtIndex:idx];
        [self.cruiseTimeCustomedTF setIntegerValue:self.cruiseTimeCustomed.time];
        [self.timeLabel setStringValue:[self timeFromMin:self.cruiseTimeCustomed.time]];
    }
}

- (void)updateCruiseLoopCntUI
{
    NSInteger count = self.cruiseLoopCnt;
    if (count >= 0)
        [self.cruiseLoopCntTF setIntegerValue:count];
}

- (void)updateCruiseMapListUI
{
    [self.cruiseTracksBtn removeAllItems];
    
    for (int i = 0; i < self.cruiseMapList.cruiseMapCnt; i++) {
        [self.cruiseTracksBtn addItemWithTitle:[NSString stringWithCString:self.cruiseMapList.cruiseMapName[i]
                                                                  encoding:NSASCIIStringEncoding]];
    }
    
    [self.cruiseTracksBtn selectItemAtIndex:0];
    [self fetchCruiseInfo:self.cruiseTracksBtn.titleOfSelectedItem];
}

- (void)updateCruiseMapInfoUI
{
    //NSArray *titles = self.cruiseTracksBtn.itemTitles;
    NSString *cruiseMapName = [NSString stringWithCString:self.cruiseMapInfo.cruiseMapName encoding:NSASCIIStringEncoding];
    NSLog(@"%@",cruiseMapName);
    NSArray *titles = self.cruiseTracksBtn.itemTitles;
    NSUInteger idx = [titles indexOfObject:cruiseMapName];
    if (idx == NSNotFound) {
        idx = 0;
    }
    //[self.cruiseTracksBtn selectItemAtIndex:idx];
    [self.cruiseMapInfoTV reloadData];
}

#pragma mark - data
- (NSArray *)availableCruiseMode
{
    return @[NSLocalizedString(@"Cruise time", nil),
             NSLocalizedString(@"Cruise loops", nil)];
}

- (NSArray*)availableCruiseTime
{
    return @[NSLocalizedString(@"15 Minute", nil),
             NSLocalizedString(@"30 Minute", nil),
             NSLocalizedString(@"1 Hour", nil),
             NSLocalizedString(@"2 Hour", nil),
             NSLocalizedString(@"Unlimited", nil),
             NSLocalizedString(@"Customized(unit：minute)", nil)];
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
        NSString *point = [NSString stringWithCString:self.cruiseMapInfo.pointName[idx] encoding:NSASCIIStringEncoding];
        
        if (![point isEqualToString:@""]) {
            count++;
        }
    }
    return count;
}


#pragma mark - tableview datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger idx = [[self tableViewIDs] indexOfObject:tableView.identifier];
    
    switch (idx) {
        case 0:
            return self.presetPointList.pointCnt;
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
            if ([cIdentifier isEqualToString:TVCID_NAME]) {
                return [NSString stringWithCString:self.presetPointList.pointName[row] encoding:NSASCIIStringEncoding];
            }
        }
        case 1:{
            if ([cIdentifier isEqualToString:TVCID_NAME])
                return [NSString stringWithCString:self.cruiseMapInfo.pointName[row] encoding:NSASCIIStringEncoding];
            else
                return [NSNumber numberWithInt:self.cruiseMapPrepointLingerTime.time[row]];
        }
            break;
        default:
            break;
    }
    return nil;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
    return NO;
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


#pragma mark - textfield delegate
- (void)controlTextDidChange:(NSNotification *)obj
{
    NSTextField *tf = [obj object];
    int num = [tf intValue];
    
    if ([tf.identifier isEqualToString:@"loop cnt"]) {
        if (num < 1)
            [tf setIntValue:1];
        else if (num > 100)
            [tf setIntValue:100];
    }
    else if ([tf.identifier isEqualToString:@"cruise map name"]) {
        [self onEdit];
    }
    else if ([tf.identifier isEqualToString:@"custom cruise time"]) {
        int min = tf.intValue;
        if (min > MAX_CRUISE_TIME) {
            tf.intValue = MAX_CRUISE_TIME;
        }
        self.timeLabel.stringValue = [self timeFromMin:tf.intValue];
    }
    else {//tinger time
        if (num > 60) {
            [tf setIntValue:60];
        }
    }
}

#pragma mark - setter & getter
- (void)setCruiseCtrlMode:(FOS_CRUISECTRLMODE)cruiseCtrlMode
{
    _cruiseCtrlMode = cruiseCtrlMode;
    [self updateCruiseCtrlModeUI];
}

- (void)setCruiseTime:(unsigned int)cruiseTime
{
    _cruiseTime = cruiseTime;
    [self updateCruiseTimeUI];
}

- (void)setCruiseTimeCustomed :(FOS_CRUISETIMECUSTOMED)cruiseTimeCustomed
{
    _cruiseTimeCustomed = cruiseTimeCustomed;
    [self updateCruiseTimeCustomedUI];
}

- (void)setCruiseLoopCnt:(int)cruiseLoopCnt
{
    _cruiseLoopCnt = cruiseLoopCnt;
    [self updateCruiseLoopCntUI];
}


- (void)setCruiseMapList:(FOS_CRUISEMAPLIST)cruiseMapList
{
    _cruiseMapList = cruiseMapList;
    [self updateCruiseMapListUI];
}

- (void)setPresetPointList:(FOS_RESETPOINTLIST)presetPointList
{
    _presetPointList = presetPointList;
    [self.presetPointListTV reloadData];
}

- (void)setCruiseMapInfo:(FOS_CRUISEMAPINFO)cruiseMapInfo
{
    _cruiseMapInfo = cruiseMapInfo;
    [self updateCruiseMapInfoUI];
}

- (void)setCruiseMapPrepointLingerTime:(FOS_CRUISEMAPPREPOINTLINGERTIME)cruiseMapPrepointLingerTime
{
    _cruiseMapPrepointLingerTime = cruiseMapPrepointLingerTime;
    [self.cruiseMapInfoTV reloadData];
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

- (void)setCruiseMapInfoTV:(NSTableView *)cruiseMapInfoTV
{
    _cruiseMapInfoTV = cruiseMapInfoTV;
    if (![self enableCruiseMapPrepointLingerTime]) {
        NSTableColumn *col = [_cruiseMapInfoTV tableColumnWithIdentifier:TVCID_TIME];
        [_cruiseMapInfoTV removeTableColumn:col];
    }
}

- (Fetch_PresetPts_CompleteHandle)fetchPresetPtsCompleteHandle
{
    if (!_fetchPresetPtsCompleteHandle) {
        
        __weak PTZCruiseViewController *weakSelf = self;
        _fetchPresetPtsCompleteHandle = ^(BOOL success,
                                          const FOS_RESETPOINTLIST pts,
                                          const FOS_CRUISEMAPLIST cruises,
                                          id owner)
        {
            if (success) {
                [weakSelf setCruiseMapList:cruises];
                [weakSelf setPresetPointList:pts];
            } else
                [weakSelf alert:NSLocalizedString(@"failed to get the settings", nil)
                           info:@""];
            [weakSelf setActivity:NO];
        };
    }
    
    return _fetchPresetPtsCompleteHandle;
}

@end
