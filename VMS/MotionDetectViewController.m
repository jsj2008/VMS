//
//  MotionDetectViewController.m
//  
//
//  Created by mac_dev on 16/5/25.
//
//

#import "MotionDetectViewController.h"

#define ID_MOTION_SENSITIVITY           @"motion sensitivity"
#define ID_MOTION_TRIGGER_INTERVAL      @"motion trigger interval"
#define ID_MOTION_SNAP_INTERVAL         @"motion snap interval"
#define ID_MOTION_SCHEDULES             @"motion schedules"
#define ID_AUDIO_SENSITIVITY            @"audio sensitivity"
#define ID_AUDIO_TRIGGER_INTERVAL       @"audio trigger interval"
#define ID_AUDIO_SNAP_INTERVAL          @"audio snap interval"
#define ID_AUDIO_SCHEDULES              @"audio schedules"
#define ID_TEMPERATURE_TRIGGER_INTERVAL @"temperature trigger interval"
#define ID_TEMPERATURE_SNAP_INTERVAL    @"temperature snap interval"
#define ID_TEMPERATURE_SCHEDULES        @"temperature schedules"
#define ID_OPTION                       @"option"

@interface MotionDetectViewController ()

@property (nonatomic,assign) BOOL isEnableMotionDetect;
@property (nonatomic,weak) IBOutlet NSView *zone1;
@property (nonatomic,weak) IBOutlet NSView *zone2;
@property (nonatomic,weak) IBOutlet NSPopUpButton *motionSensitivityBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *motionTriggerIntervalBtn;

@property (nonatomic,weak) IBOutlet TimePickerView *motionSchedulesPicker;
@property (nonatomic,weak) IBOutlet NSView *linkageView;
@property (nonatomic,weak) IBOutlet NSButton *audioAlarmBtn;

@property (nonatomic,weak) IBOutlet NSPopUpButton *snapIntervalBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *recordTimeBtn;

@property (nonatomic,strong) DetectionAreasEditWindowController *detectionAreasEditWindowController;

@end

@implementation MotionDetectViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    __block int chn = self.chn;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //获取model
        FosAbility *ability = [[DispatchCenter sharedDispatchCenter] abilityOfDevice:self.device channel:chn];
        self.model = ability.model;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setActivity:NO];
            
            if (self.model > 0) {
                if (self.model > 4000 && ability.model <= 6000) {
                    [self fetchAmbaMotionConfig];
                }
                else {
                    [self fetchHsMotionConfig];
                }
            }
            else {
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"the channel did not add ipc or does not support privacy masking", nil)];
            }
        });
    });
}

- (void)push
{
    [self setActivity:YES];
    __block int chn = self.chn;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //获取model
        FosAbility *ability = [[DispatchCenter sharedDispatchCenter] abilityOfDevice:self.device channel:chn];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setActivity:NO];
            
            if (ability.model > 0) {
                if (ability.model > 4000 && ability.model <= 6000) {
                    [self pushAmbaDetectConfig];
                }
                else {
                    [self pushHsDetectConfig];
                }
            }
            else {
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"the channel did not add ipc or does not support privacy masking", nil)];
            }
        });
    });
}

- (void)fetchHsMotionConfig
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NET_CONFIG_TYPE configType[2] = {FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT,FOSCAM_NET_CONFIG_PC_AUDIO_ALARM};
        FOSCAM_NET_CONFIG config[2];
        FOS_MOTIONDETECTCONFIG motionDetectConfig;
        int isEnablePCAudioAlarm;
        
        config[0].info = &motionDetectConfig;
        config[1].info = &isEnablePCAudioAlarm;
        
        BOOL success = YES;
        for (int i = 0; i < 2; i++) {
            success = [[DispatchCenter sharedDispatchCenter] getConfig:config + i
                                                               forType:configType[i]
                                                            fromDevice:self.device];
            if (!success)
                break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setHsMotionDetectConfig:motionDetectConfig];
                [self setIsEnablePCAudioAlarm:isEnablePCAudioAlarm];
            } else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
        });
    });
}

- (void)fetchAmbaMotionConfig
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NET_CONFIG config[2];
        FOSCAM_NET_CONFIG_TYPE configType[2] = {FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT1,FOSCAM_NET_CONFIG_PC_AUDIO_ALARM};
        
        FOS_MOTIONDETECTCONFIG1 motionDetectConfig;
        int isEnablePCAudioAlarm;
        
        config[0].info = &motionDetectConfig;
        config[1].info = &isEnablePCAudioAlarm;
        
        BOOL success = YES;
        for (int i = 0; i < 2; i++) {
            success = [[DispatchCenter sharedDispatchCenter] getConfig:config + i
                                                               forType:configType[i]
                                                            fromDevice:self.device];
            if (!success)
                break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setAmbaMotionDetectConfig:motionDetectConfig];
                [self setIsEnablePCAudioAlarm:isEnablePCAudioAlarm];
            } else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}


- (void)pushHsDetectConfig
{
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NET_CONFIG_TYPE configType[2] = {FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT,FOSCAM_NET_CONFIG_PC_AUDIO_ALARM};
        FOSCAM_NET_CONFIG config[2];
        FOS_MOTIONDETECTCONFIG motionDetectConfig = [self hsMotionDetectConfigFromUI];
        
        int isEnablePCAudioAlarm = self.isEnablePCAudioAlarm;
        
        for (int i=0; i<FOS_MAX_AREA_COUNT; i++) {
            motionDetectConfig.areas[i] = self.hsMotionDetectConfig.areas[i];
        }
        config[0].info = &motionDetectConfig;
        config[1].info = &isEnablePCAudioAlarm;
        
        BOOL success = YES;
        for (int i = 0; i < 2; i++) {
            success = [[DispatchCenter sharedDispatchCenter] setConfig:config + i
                                                               forType:configType[i]
                                                              toDevice:self.device];
            if (!success)
                break;
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success)
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (void)pushAmbaDetectConfig
{
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NET_CONFIG_TYPE configType[2] = {FOSCAM_NET_CONFIG_VIDEO_MOTION_DETECT1,FOSCAM_NET_CONFIG_PC_AUDIO_ALARM};
        FOSCAM_NET_CONFIG config[2];
        FOS_MOTIONDETECTCONFIG1 motionDetectConfig = [self ambaMotionDetectConfigFromUI];
        int isEnablePCAudioAlarm = self.isEnablePCAudioAlarm;
        
        config[0].info = &motionDetectConfig;
        config[1].info = &isEnablePCAudioAlarm;
        
        BOOL success = YES;
        for (int i = 0; i < 2; i++) {
            success = [[DispatchCenter sharedDispatchCenter] setConfig:config + i
                                                               forType:configType[i]
                                                              toDevice:self.device];
            if (!success)
                break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success)
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}


- (NSString *)description
{
    return NSLocalizedString(@"Motion Detection", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}


#pragma mark - life cyle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isEnableSnap = YES;
    self.isEnableRecord = NO;
}

#pragma mark - init ui
- (NSString *)audioAlarmTitle
{
    return NSLocalizedString(@"PC Sound", nil);
}

- (NSArray *)linkages
{
    return @[@{KEY_LINKAGE_NAME : NSLocalizedString(@"Camera Sound", nil),KEY_LINKAGE_VALUE : @0},
             @{KEY_LINKAGE_NAME : NSLocalizedString(@"Send E-mail", nil),KEY_LINKAGE_VALUE : @1},
             @{KEY_LINKAGE_NAME : NSLocalizedString(@"Take Snapshot", nil),KEY_LINKAGE_VALUE : @2},
             @{KEY_LINKAGE_NAME : NSLocalizedString(@"Record", nil),KEY_LINKAGE_VALUE : @3},
             @{KEY_LINKAGE_NAME : NSLocalizedString(@"Push message to the phone", nil),KEY_LINKAGE_VALUE : @7}];
}

- (NSRange)intervalRange
{
    return NSMakeRange(1, 5);
}

#pragma mark - detect area edit scene
- (DetectionAreasEditWindowController *)daewc
{
    int model = self.model;
    Channel *chn = self.device.children[self.chn];
    
    if (0 == model) {
        return nil;
    }
    else if (model > 4000 && model < 6000) {
        FOS_MOTIONDETECTCONFIG1 motionCfg = [self ambaMotionDetectConfigFromUI];
        return [[AmbaDetectionAreaEditWindowController alloc] initWithWindowNibName:@"AmbaDetectionAreaEditWindowController"
                                                                          channelId:chn.uniqueId
                                                                       detectConfig:motionCfg];
    }
    else {
        FOS_MOTIONDETECTCONFIG  motionCfg = [self hsMotionDetectConfigFromUI];
        return [[HsDetectionAreaEditWindowController alloc] initWithWindowNibName:@"HsDetectionAreasEditWindowController"
                                                                        channelId:chn.uniqueId
                                                                     detectConfig:motionCfg];
    }
    
    return nil;
}

- (void)onEditDone :(void *)cfg
{
    int model = self.model;
    
    if (0 == model) {
        
    }
    else if (model > 4000 && model < 6000) {
        self.ambaMotionDetectConfig = *((FOS_MOTIONDETECTCONFIG1 *)cfg);
    }
    else {
        self.hsMotionDetectConfig = *((FOS_MOTIONDETECTCONFIG *)cfg);
    }
}

#pragma mark - update
- (void)updateRecordTime
{
    [self.recordTimeBtn selectItemWithTag:self.recordTime];
}

- (void)updateUIWithHsMotionDetectConfig
{
    self.zone1.hidden = NO;
    self.isEnableMotionDetect = self.hsMotionDetectConfig.isEnable;
    [self updateLinkageUI:self.hsMotionDetectConfig.linkage];
    [self.motionSchedulesPicker setSchedule:self.hsMotionDetectConfig.schedules];
    [self.motionSensitivityBtn selectItemWithTag:self.hsMotionDetectConfig.sensitivity];
    [self.motionTriggerIntervalBtn selectItemWithTag:self.hsMotionDetectConfig.triggerInterval];
    [self.snapIntervalBtn selectItemWithTag:self.hsMotionDetectConfig.snapInterval];
}

- (void)updateUIWithAmbaMotionDetectConfig
{
    self.zone1.hidden = YES;
    self.isEnableMotionDetect = self.ambaMotionDetectConfig.isEnable;
    [self updateLinkageUI:self.ambaMotionDetectConfig.linkage];
    [self.motionSchedulesPicker setSchedule:self.ambaMotionDetectConfig.schedules];
    [self.motionTriggerIntervalBtn selectItemWithTag:self.ambaMotionDetectConfig.triggerInterval];
    [self.snapIntervalBtn selectItemWithTag:self.ambaMotionDetectConfig.snapInterval];
}

- (FOS_MOTIONDETECTCONFIG1)ambaMotionDetectConfigFromUI
{
    FOS_MOTIONDETECTCONFIG1 config = self.ambaMotionDetectConfig;
    
    config.isEnable = self.isEnableMotionDetect;
    config.linkage = [self linkageFromUI];
    config.snapInterval = (int)[self.snapIntervalBtn selectedTag];
    config.triggerInterval = (int)[self.motionTriggerIntervalBtn selectedTag];
    
    [self.motionSchedulesPicker getSchedule:config.schedules lenght:7];

    return config;
}

- (int)recordTimeFromUI
{
    return (int)self.recordTimeBtn.selectedTag;
}

- (FOS_MOTIONDETECTCONFIG)hsMotionDetectConfigFromUI
{
    FOS_MOTIONDETECTCONFIG config = self.hsMotionDetectConfig;
    
    config.isEnable = self.isEnableMotionDetect;
    config.linkage = [self linkageFromUI];
    config.snapInterval = (int)self.snapIntervalBtn.selectedTag;
    config.sensitivity = (int)[self.motionSensitivityBtn selectedTag];
    config.triggerInterval = (int)[self.motionTriggerIntervalBtn indexOfSelectedItem];
    //计划
    [self.motionSchedulesPicker getSchedule:config.schedules lenght:7];
    
    return config;
}

- (int)linkageFromUI
{
    NSArray *checkBoxs = self.linkageView.subviews;
    int result = 0;
    
    for (NSButton *btn in checkBoxs) {
        
        int tag = (int)btn.tag;
        if (tag < self.linkages.count) {
            if (btn.state == NSOnState) {
                NSDictionary *dict = [self.linkages objectAtIndex:tag];
                result |= 1 << [[dict valueForKey:KEY_LINKAGE_VALUE] intValue];
            }
        }
    }
    
    return result;
}

- (void)updateLinkageUI :(int)linkage
{
    NSArray *checkBoxs = self.linkageView.subviews;
    for (NSButton *btn in checkBoxs) {
        int tag = (int)btn.tag;
        if (tag < self.linkages.count) {
            NSDictionary *dict = [self.linkages objectAtIndex:btn.tag];
            btn.state = linkage & (1 << [[dict valueForKey:KEY_LINKAGE_VALUE] intValue]);
            btn.hidden = NO;
        }
        else {
            btn.hidden = YES;
        }
    }
}

#pragma mrak - action
- (IBAction)editDetectionArea:(id)sender
{
    if (!self.detectionAreasEditWindowController) {
        DetectionAreasEditWindowController *daewc = [self daewc];
        //成功加在侦测区域编辑MVC
        if (daewc) {
            //使用成员变量Hold住该MVC
            [self setDetectionAreasEditWindowController:daewc];
            [self.view.window beginSheet:daewc.window completionHandler:^(NSModalResponse returnCode) {
                
                if (NSModalResponseOK == returnCode) {
                    [self onEditDone:[daewc detectConfig]];
                }
                
                [daewc close];
                [self setDetectionAreasEditWindowController:nil];
            }];
        }
    }
}

#pragma mark - control data
- (void)setHsMotionDetectConfig:(FOS_MOTIONDETECTCONFIG)hsMotionDetectConfig
{
    _hsMotionDetectConfig = hsMotionDetectConfig;
    [self updateUIWithHsMotionDetectConfig];
}

- (void)setAmbaMotionDetectConfig:(FOS_MOTIONDETECTCONFIG1)ambaMotionDetectConfig
{
    _ambaMotionDetectConfig = ambaMotionDetectConfig;
    [self updateUIWithAmbaMotionDetectConfig];
}

- (void)setAudioAlarmBtn:(NSButton *)audioAlarmBtn
{
    _audioAlarmBtn = audioAlarmBtn;
    
    NSString *title = [self audioAlarmTitle];
    
    if (title == nil) {
        _audioAlarmBtn.hidden = YES;
    }
    else {
        _audioAlarmBtn.hidden = NO;
        _audioAlarmBtn.title = title;
    }
}

- (void)setLinkageView:(NSView *)linkageView
{
    _linkageView = linkageView;
    
    NSArray *checkBoxs = [_linkageView subviews];
    
    //checkboxs
    for (NSButton *btn in checkBoxs) {
        int tag = (int)btn.tag;
        if (tag < self.linkages.count) {
            NSDictionary *dict = [self.linkages objectAtIndex:btn.tag];
            NSString *title = [dict valueForKey:KEY_LINKAGE_NAME];
            
            if (title == nil) {
                btn.hidden = YES;
            }
            else {
                btn.hidden = NO;
                btn.title = title;
            }
        }
        else {
            btn.hidden = YES;
        }
    }
}

- (void)setSnapIntervalBtn:(NSPopUpButton *)snapIntervalBtn
{
    _snapIntervalBtn = snapIntervalBtn;
    
    
    NSRange rg = NSMakeRange(1, 5);
    [_snapIntervalBtn removeAllItems];
    for (NSInteger i = 0; i < rg.length; i++) {
        NSInteger val = i + rg.location;
        [_snapIntervalBtn addItemWithTitle:[NSString stringWithFormat:@"%lds",val]];
        [_snapIntervalBtn lastItem].tag = val;
    }
}

- (void)setRecordTimeBtn:(NSPopUpButton *)recordTimeBtn
{
    _recordTimeBtn = recordTimeBtn;
    NSRange rg = NSMakeRange(30, 61);
    [_recordTimeBtn removeAllItems];
    for (NSInteger i = 0; i < rg.length; i++) {
        NSInteger val = i + rg.location;
        [_recordTimeBtn addItemWithTitle:[NSString stringWithFormat:@"%lds",val]];
        [_recordTimeBtn lastItem].tag = val;
    }
}

- (void)setMotionTriggerIntervalBtn:(NSPopUpButton *)motionTriggerIntervalBtn
{
    _motionTriggerIntervalBtn = motionTriggerIntervalBtn;
    NSRange rg = NSMakeRange(5, 11);
    
    [_motionTriggerIntervalBtn removeAllItems];
    
    for (int i = 0; i < rg.length; i++) {
        [_motionTriggerIntervalBtn addItemWithTitle:[NSString stringWithFormat:@"%lds",i + rg.location]];
        [_motionTriggerIntervalBtn lastItem].tag = i;
    }
}

- (void)setRecordTime:(int)recordTime
{
    _recordTime = recordTime;
    [self updateRecordTime];
}

@end
