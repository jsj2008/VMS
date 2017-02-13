//
//  VideoSettingViewController.m
//  VMS
//
//  Created by mac_dev on 15/8/28.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VideoSettingViewController.h"
#import "PrivacyCoverEditWindowController.h"

#define ID_VIDEO_STREAM_TYPE        @"video stream type"
#define ID_RESOLUTION1              @"resolution1"
#define ID_BIT_RATE1                @"bit rate1"
#define ID_FRAME_RATE1              @"frame rate1"
#define ID_GOP1                     @"gop1"
#define ID_VIDEO_SUB_STREAM_TYPE    @"video sub stream type"
#define ID_RESOLUTION2              @"resolution2"
#define ID_BIT_RATE2                @"bit rate2"
#define ID_FRAME_RATE2              @"frame rate2"
#define ID_GOP2                     @"gop2"
#define ID_SNAP_PIC_QUALITY         @"snap pic quality"
#define ID_SAVE_LOCATION            @"save location"
#define ID_BEGIN_HOUR1              @"begin hour1"
#define ID_BEGIN_MIN1               @"begin min1"
#define ID_END_HOUR1                @"end hour1"
#define ID_END_MIN1                 @"end min1"
#define ID_BEGIN_HOUR2              @"begin hour2"
#define ID_BEGIN_MIN2               @"begin min2"
#define ID_END_HOUR2                @"end hour2"
#define ID_END_MIN2                 @"end min2"
#define ID_BEGIN_HOUR3              @"begin hour3"
#define ID_BEGIN_MIN3               @"begin min3"
#define ID_END_HOUR3                @"end hour3"
#define ID_END_MIN3                 @"end min3"
#define K                           1024


@interface VideoSettingViewController ()

//主码流视频参数
@property (nonatomic,weak) IBOutlet NSPopUpButton *videoStreamType1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *videoStreamType2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *resolution1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *resolution2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *bitRate1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *bitRate2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *frameRate1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *frameRate2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *gop1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *gop2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *isVBR1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *isVBR2Btn;

//OSD屏幕显示
@property (nonatomic,weak) IBOutlet NSPopUpButton *timeStampEnableBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *deviceNameEnableBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *tempAndHumidEnableBtn;

//隐私遮盖
@property (nonatomic,weak) IBOutlet NSPopUpButton *osdMaskEnableBtn;

//红外灯模式设置
@property (nonatomic,assign) BOOL isEnableSchedule1;
@property (nonatomic,assign) BOOL isEnableSchedule2;
@property (nonatomic,assign) BOOL isEnableSchedule3;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginHour1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginMin1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endHour1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endMin1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginHour2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginMin2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endHour2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endMin2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginHour3Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *beginMin3Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endHour3Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *endMin3Btn;

@property (nonatomic,weak) IBOutlet NSButton *privacyCoverEditBtn;
@property (nonatomic,strong) PrivacyCoverEditWindowController *pcewc;
@end

@implementation VideoSettingViewController

@synthesize nightLightState = _nightLightState;
@synthesize osdSetting = _osdSetting;
@synthesize osdMaskEnable = _osdMaskEnable;
@synthesize snapConfig = _snapConfig;
@synthesize scheduleSnapConfig = _scheduleSnapConfig;
@synthesize scheduleInfraLedConfig = _scheduleInfraLedConfig;

#pragma mark - action
//用户选择视频流类型
- (IBAction)selectVideoStreamType:(id)sender
{
    switch ([sender tag]) {
        case 0:
            [self updateMainStreamEncoderArgsUI];
            break;
        case 1:
            [self updateSubStreamEncoderArgsUI];
            break;
        default:
            break;
    }
}

- (IBAction)editPrivacyCoverArea:(id)sender
{
    if (!self.pcewc) {
        Channel *chn = self.device.children[0];
        self.pcewc = [[PrivacyCoverEditWindowController alloc] initWithWindowNibName:@"PrivacyCoverEditWindowController"
                                                                           channelId:chn.uniqueId
                                                                               areas:self.osdMaskArea];
        [self.view.window beginSheet:self.pcewc.window
                   completionHandler:^(NSModalResponse returnCode)
        {
            self.osdMaskArea = self.pcewc.areas;
            
            [self.pcewc close];
            [self setPcewc:nil];
        }];
    }
}

- (IBAction)selectPrivacyCoverOption:(id)sender
{
    [self updatePrivacyCoverUI];
}
#pragma mark - public api
- (void)push :(NSInteger)tag
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    //Channel *channel = self.channel;
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        switch (tag) {
            case 0: {
                FOS_VIDEOSTREAMPARAM videoStreamParam = [self mainStreamEncoderArgs];
                config.info = &videoStreamParam;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_ENCODE_MAIN toDevice:device];
                
                FOS_VIDEOSTREAMPARAM videoSubStreamParam = [self subStreamEncoderArgs];
                config.info = &videoSubStreamParam;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_ENCODE_SUB toDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
            case 1: {
                FOS_OSDSETTING osdSetting = [self osdSettingFromUI];
                config.info = &osdSetting;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_OSD toDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
            case 2: {
                int             osdMaskEnable = (int)self.osdMaskEnableBtn.indexOfSelectedItem;
                FOS_OSDMASKAREA area = self.osdMaskArea;
                BOOL success = NO;
                
                do {
                    config.info = &osdMaskEnable;
                    success = [center setConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_OSD_MASK_ENABLE toDevice:device];
                    if (!success) break;
                    
                    config.info = &area;
                    success = [center setConfig:&config forType:FOSCAM_NET_CONFIG_OSD_MASK_AREA toDevice:device];
                }while (0);
    
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!success) [self alert:@"保存失败!"];
                    [self setActivity:NO];
                });
            }
                break;
            //case 3: {
                //TODO :以下两个暂时不用
                //        FOS_SNAPCONFIG snapConfig = self.snapConfig;
                //        config.info = &snapConfig;
                //        [center setConfig:&config forType:forType:FOSCAM_NET_CONFIG_VIDEO_SNAP_CONFIG channel:channel];
                //
                //        FOS_SCHEDULESNAPCONFIG scheduledSnapConfig = self.scheduleSnapConfig;
                //        config.info = &scheduledSnapConfig;
                //        [center setConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_SCHEDULE_SNAP_CONFIG channel:channel];
                
                //dispatch_async(dispatch_get_main_queue(), ^{
                //   [self setActivity:NO];
                //});
            //}
                //break;
            case 3: {
                FOS_SCHEDULEINFRALEDCONFIG scheduleInfraLedConfig = [self ledScheduleFromUI];
                config.info = &scheduleInfraLedConfig;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_IRLAMP_PLAN toDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
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

- (void)refetch:(NSInteger)tag
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    __block BOOL success = YES;
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        switch (tag) {
            case 0: {
                FOS_VIDEOSTREAMLISTPARAM videoStreamListParam;
                config.info = &videoStreamListParam;
                success = success && [center getConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_ENCODE_MAIN fromDevice:device];
                //Video Sub Stream List Param
                FOS_VIDEOSTREAMLISTPARAM videoSubStreamListParam;
                config.info = &videoSubStreamListParam;
                success = success && [center getConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_ENCODE_SUB fromDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [self setVideoStreamListParam:videoStreamListParam];
                        [self setVideoSubStreamListParam :videoSubStreamListParam];
                    } else
                        [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
            case 1 : {
                FOS_OSDSETTING osdSetting;
                config.info = &osdSetting;
                success = success && [center getConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_OSD fromDevice:device];
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    if (success)
                        [self setOsdSetting:osdSetting];
                    else
                        [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
            case 2 : {
                //osdMaskEnable
                int osdMaskEnable = 0;
                FOS_OSDMASKAREA osdMaskArea;
                do {
                    config.info = &osdMaskEnable;
                    success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_OSD_MASK_ENABLE fromDevice:device];
                    if (!success)
                        break;
                
                    config.info = &osdMaskArea;
                    success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_OSD_MASK_AREA fromDevice:device];
                }while (0);
                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    if (success) {
                        [self setOsdMaskEnable:osdMaskEnable];
                        [self setOsdMaskArea:osdMaskArea];
                    } else
                        [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
            //case 3: {
                //        TODO:Snap Config,暂时不处理
                //        FOS_SNAPCONFIG snapConfig;
                //        config.info = &snapConfig;
                //        if ([center getConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_SNAP_CONFIG fromChannel:channel])
                //            [self setSnapConfig :snapConfig];
                
                //        TODO:Schedule Snap Config,暂时不处理
                //        FOS_SCHEDULESNAPCONFIG scheduleSnapConfig;
                //        config.info = &scheduleSnapConfig;
                //        if ([center getConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_SCHEDULE_SNAP_CONFIG fromChannel:channel])
                //            [self setScheduleSnapConfig :scheduleSnapConfig];
                //dispatch_async(dispatch_get_main_queue(), ^
                //{
                //    [self setActivity:NO];
                //});
            //}
                //break;
            case 3: {
                FOS_SCHEDULEINFRALEDCONFIG scheduleInfraLedConfig;
                config.info = &scheduleInfraLedConfig;
                success = success && [center getConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_IRLAMP_PLAN fromDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    if (success)
                        [self setScheduleInfraLedConfig:scheduleInfraLedConfig];
                    else
                        [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
            default:
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
                break;
        }
    });
}

#pragma mark - private method
- (BOOL)isScheduleEnableBeginHour :(int)beginHour
                         beginMin :(int)beginMin
                          endHour :(int)endHour
                           endMin :(int)endMin
{
    return endHour * 60 + endMin > beginHour * 60 + beginMin;
}

- (NSArray *)hours
{
    NSMutableArray *hours = [[NSMutableArray alloc] init];
    for (int hour = 0; hour < 24 ; hour++)
        [hours addObject:[NSNumber numberWithInt:hour]];
    
    return hours;
}

- (NSArray *)minutes
{
    NSMutableArray *minutes = [[NSMutableArray alloc] init];
    for (int minute = 0; minute < 60; minute++)
        [minutes addObject:[NSNumber numberWithInt:minute]];
    
    return minutes;
}

- (NSArray *)availableSnapPicQuality
{
    return [NSArray arrayWithObjects:@"低",@"中",@"高", nil];
}

- (NSArray *)availableSaveLocation
{
    return [NSArray arrayWithObjects:@"无",@"SD卡",@"FTP" ,nil];
}

- (NSArray *)availableVideoStreamTypes
{
    return [NSArray arrayWithObjects:@"清晰模式", @"均衡模式",@"流畅模式",@"自定义",nil];
}

- (NSArray *)availableResolutions
{
    return [NSArray arrayWithObjects:@"720P",@"VGA(640*480)",@"VGA(640*360)",@"QVGA(320*240)",@"QVGA(320*180)", nil];
}

- (NSArray *)availableBitRatesName
{
    return [NSArray arrayWithObjects:@"4M",@"2M",@"1M",@"512K",@"256K",@"200K",@"128K",@"100K", nil];
}
- (NSArray *)availableBitRates
{
    //统一单位K
    return [NSArray arrayWithObjects:@4096,@2048,@1024,@512,@256,@200,@128,@100, nil];
}

- (NSArray *)availableFrameRates
{
    NSMutableArray *availableFrameRates = [[NSMutableArray alloc] init];
    for (int i = 1; i <= 30; i++) {
        NSNumber *frameRate = [NSNumber numberWithInt:i];
        [availableFrameRates addObject:frameRate];
    }
    return availableFrameRates;
}

- (NSArray *)availableGOP
{
    NSMutableArray *availableGOP = [[NSMutableArray alloc] init];
    for (int i = 10; i <= 100; i++) {
        NSNumber *gop = [NSNumber numberWithInt:i];
        [availableGOP addObject:gop];
    }
    return availableGOP;
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - combobox datasouce
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    NSString *identifier = [aComboBox identifier];
    NSInteger number = 0;
    
    if ([identifier isEqualToString:ID_SNAP_PIC_QUALITY]) {
        number = [self availableSnapPicQuality].count;
    } else if ([identifier isEqualToString:ID_SAVE_LOCATION]) {
        number = [self availableSaveLocation].count;
    } else if ([identifier isEqualToString:ID_BEGIN_HOUR1] ||
               [identifier isEqualToString:ID_BEGIN_HOUR2] ||
               [identifier isEqualToString:ID_BEGIN_HOUR3] ||
               [identifier isEqualToString:ID_END_HOUR1] ||
               [identifier isEqualToString:ID_END_HOUR2] ||
               [identifier isEqualToString:ID_END_HOUR3]) {
        number = [self hours].count;
    } else if ([identifier isEqualToString:ID_BEGIN_MIN1] ||
               [identifier isEqualToString:ID_BEGIN_MIN2] ||
               [identifier isEqualToString:ID_BEGIN_MIN3] ||
               [identifier isEqualToString:ID_END_MIN1] ||
               [identifier isEqualToString:ID_END_MIN2] ||
               [identifier isEqualToString:ID_END_MIN3]) {
        number = [self minutes].count;
    }
    
    return number;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    NSString *identifier = [aComboBox identifier];
    id result = nil;
    
    if ([identifier isEqualToString:ID_SNAP_PIC_QUALITY]) {
        result = [self availableSnapPicQuality][index];
    } else if ([identifier isEqualToString:ID_SAVE_LOCATION]) {
        result = [self availableSaveLocation][index];
    } else if ([identifier isEqualToString:ID_BEGIN_HOUR1] ||
                [identifier isEqualToString:ID_BEGIN_HOUR2] ||
                [identifier isEqualToString:ID_BEGIN_HOUR3] ||
                [identifier isEqualToString:ID_END_HOUR1] ||
                [identifier isEqualToString:ID_END_HOUR2] ||
                [identifier isEqualToString:ID_END_HOUR3]) {
        result = [self hours][index];
    } else if ([identifier isEqualToString:ID_BEGIN_MIN1] ||
               [identifier isEqualToString:ID_BEGIN_MIN2] ||
               [identifier isEqualToString:ID_BEGIN_MIN3] ||
               [identifier isEqualToString:ID_END_MIN1] ||
               [identifier isEqualToString:ID_END_MIN2] ||
               [identifier isEqualToString:ID_END_MIN3]) {
        result = [self minutes][index];
    }
    
    return result;
}



#pragma mark - resolution format
- (NSUInteger)bitRateWithByteFromString :(NSString *)str
{
    NSUInteger  bitRate = 0;
    NSUInteger  len     = str.length;
    
    if (len > 0) {
        NSString            *numberPart = [str substringWithRange:NSMakeRange(0,len - 1)];
        NSString            *unitPart   = [str substringWithRange:NSMakeRange(len - 1, 1)];
        NSNumberFormatter   *formatter  = [[NSNumberFormatter alloc] init];
        
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        NSUInteger          number      = [[formatter numberFromString:numberPart] unsignedIntegerValue];
        //解析
        if ([unitPart isEqualToString:@"M"]) {
            bitRate = number * 1024 * 1024;
        } else if ([str hasSuffix:@"K"]) {
            bitRate = number * 1024;
        }
    }
    
    return bitRate;
}



- (NSString *)stringFromBitRateWithByte :(NSUInteger)resolution
{
    CGFloat bitRateWithK = resolution / 1024.0;
    CGFloat bitRateWithM = bitRateWithK / 1024.0;
    
    if (bitRateWithM < 1.0) {
        return [NSString stringWithFormat:@"%dK",(int)bitRateWithK];
    }
    
    return [NSString stringWithFormat:@"%dM",(int)bitRateWithM];
}

#pragma mark - collect from UI
- (FOS_VIDEOSTREAMPARAM)mainStreamEncoderArgs
{
    NSArray *mainControls = @[self.videoStreamType1Btn,
                              self.resolution1Btn,
                              self.bitRate1Btn,
                              self.frameRate1Btn,
                              self.gop1Btn,
                              self.isVBR1Btn];
    return [self encoderArgsFromUIControls:mainControls];
}

- (FOS_VIDEOSTREAMPARAM)subStreamEncoderArgs
{
    NSArray *subControls = @[self.videoStreamType2Btn,
                             self.resolution2Btn,
                             self.bitRate2Btn,
                             self.frameRate2Btn,
                             self.gop2Btn,
                             self.isVBR2Btn];
    return [self encoderArgsFromUIControls:subControls];
}

- (FOS_OSDSETTING)osdSettingFromUI
{
    FOS_OSDSETTING osdSetting = self.osdSetting;
    osdSetting.isEnableTimeStamp = (int)self.timeStampEnableBtn.indexOfSelectedItem;
    osdSetting.isEnableDevName = (int)self.deviceNameEnableBtn.indexOfSelectedItem;
    osdSetting.isEnableTempAndHumid = (int)self.tempAndHumidEnableBtn.indexOfSelectedItem;
    return osdSetting;
}

- (FOS_VIDEOSTREAMPARAM)encoderArgsFromUIControls :(NSArray *)controls
{
    FOS_VIDEOSTREAMPARAM    streamParam;
    //获取视频流类型
    NSPopUpButton   *videoStreamTypeBtn = [controls objectAtIndex:0];
    NSUInteger      videoStreamType     = videoStreamTypeBtn.indexOfSelectedItem;
    if (videoStreamType < FOS_MAX_VIDEOSTREAM_TYPE) {
        streamParam.streamType = (int)videoStreamType;
        //分辨率（这里使用tag作为唯一标示）
        NSPopUpButton   *resolutionBtn  = [controls objectAtIndex:1];
        streamParam.resolution          = (int)[resolutionBtn selectedTag];
        
        //码率
        NSPopUpButton   *bitRateBtn     = [controls objectAtIndex:2];
        streamParam.bitRate             = (int)[self bitRateWithByteFromString:[bitRateBtn titleOfSelectedItem]];
        
        //帧率
        NSPopUpButton   *frameRateBtn   = [controls objectAtIndex:3];
        streamParam.frameRate = (int)([self frameRateRange].location + frameRateBtn.indexOfSelectedItem);

        //主帧间隔
        NSPopUpButton   *gopBtn         = [controls objectAtIndex:4];
        streamParam.GOP                 = (int)([self gopRange].location + gopBtn.indexOfSelectedItem);
        
        //是否可变码率
        NSPopUpButton   *isVBRBtn       = [controls objectAtIndex:5];
        streamParam.isVBR               = (int)isVBRBtn.indexOfSelectedItem;
    }
    
    return streamParam;
}

- (FOS_SCHEDULEINFRALEDCONFIG)ledScheduleFromUI
{
    FOS_SCHEDULEINFRALEDCONFIG scheduleCfg;
    
    for (int i = 0; i < FOS_LED_SCHEDULE_COUNT; i++) {
        scheduleCfg.startHour[i] = 0;
        scheduleCfg.startMin[i] = 0;
        scheduleCfg.endHour[i]  = 0;
        scheduleCfg.endMin[i] = 0;
    }
    
    if (self.isEnableSchedule1) {
        scheduleCfg.startHour[0] = (int)[self.beginHour1Btn indexOfSelectedItem];
        scheduleCfg.startMin[0] = (int)[self.beginMin1Btn indexOfSelectedItem];
        scheduleCfg.endHour[0] = (int)[self.endHour1Btn indexOfSelectedItem];
        scheduleCfg.endMin[0] = (int)[self.endMin1Btn indexOfSelectedItem];
    }
    
    if (self.isEnableSchedule2) {
        scheduleCfg.startHour[1] = (int)[self.beginHour2Btn indexOfSelectedItem];
        scheduleCfg.startMin[1] = (int)[self.beginMin2Btn indexOfSelectedItem];
        scheduleCfg.endHour[1] = (int)[self.endHour2Btn indexOfSelectedItem];
        scheduleCfg.endMin[1] = (int)[self.endMin2Btn indexOfSelectedItem];
    }
    
    if (self.isEnableSchedule3) {
        scheduleCfg.startHour[2] = (int)[self.beginHour3Btn indexOfSelectedItem];
        scheduleCfg.startMin[2] = (int)[self.beginMin3Btn indexOfSelectedItem];
        scheduleCfg.endHour[2] = (int)[self.endHour3Btn indexOfSelectedItem];
        scheduleCfg.endMin[2] = (int)[self.endMin3Btn indexOfSelectedItem];
    }
    
    return scheduleCfg;
}
#pragma mark - update UI
- (void)updatePrivacyCoverUI
{
    self.privacyCoverEditBtn.hidden = (self.osdMaskEnableBtn.indexOfSelectedItem == 0);
}
- (void)updateEncodeUIControls :(NSArray *)controls
                 withListParam :(FOS_VIDEOSTREAMLISTPARAM)listParam
{
    if (controls.count != 6) {
        return;
    }
    
    NSPopUpButton *videoStreamTypeBtn = [controls objectAtIndex:0];
    NSUInteger selectedVideoStreamType = videoStreamTypeBtn.indexOfSelectedItem;
    if (selectedVideoStreamType < FOS_MAX_VIDEOSTREAM_TYPE) {
        //分辨率(这里使用Tag作为唯一标示)
        NSUInteger resolutionIdx = listParam.resolution[selectedVideoStreamType];
        NSPopUpButton *resolutionBtn = [controls objectAtIndex:1];
        [resolutionBtn selectItemWithTag:resolutionIdx];

        
        //码率
        NSUInteger bitRate = listParam.bitRate[selectedVideoStreamType];
        NSString *bitRateString = [self stringFromBitRateWithByte:bitRate];
        NSPopUpButton *bitRateBtn = [controls objectAtIndex:2];
        NSUInteger selectedBitRateIdx = 0;
        for (NSUInteger idx = 0; idx < bitRateBtn.numberOfItems; idx++) {
            NSString *title = [bitRateBtn itemTitleAtIndex:idx];
            
            if ([title isEqualToString:bitRateString]) {
                selectedBitRateIdx = idx;
                break;
            }
        }
        [bitRateBtn selectItemAtIndex:selectedBitRateIdx];
        
        //帧率
        NSUInteger frameRate = listParam.frameRate[selectedVideoStreamType];
        NSUInteger selectedFrameRateIdx = frameRate - [self frameRateRange].location;
        NSPopUpButton *frameRateBtn = [controls objectAtIndex:3];
        if (selectedFrameRateIdx < frameRateBtn.numberOfItems) {
            [frameRateBtn selectItemAtIndex:selectedFrameRateIdx];
        }
        
        //主帧间隔
        NSUInteger gop = listParam.GOP[selectedVideoStreamType];
        NSUInteger selectedGopIdx = gop - [self gopRange].location;
        NSPopUpButton *gopBtn = [controls objectAtIndex:4];
        if (selectedGopIdx < gopBtn.numberOfItems) {
            [gopBtn selectItemAtIndex:selectedGopIdx];
        }
        
        //是否可变码率
        NSUInteger isVBR = listParam.isVBR[selectedVideoStreamType];
        NSPopUpButton *isVBRBtn = [controls objectAtIndex:5];
        if (isVBR < isVBRBtn.numberOfItems) {
            [isVBRBtn selectItemAtIndex:isVBR];
        }
    }
}

- (void)updateMainStreamEncoderArgsUI
{
    FOS_VIDEOSTREAMLISTPARAM mainListParam = self.videoStreamListParam;
    NSArray *mainControls = @[self.videoStreamType1Btn,
                              self.resolution1Btn,
                              self.bitRate1Btn,
                              self.frameRate1Btn,
                              self.gop1Btn,
                              self.isVBR1Btn];
    [self updateEncodeUIControls:mainControls withListParam:mainListParam];
}

- (void)updateSubStreamEncoderArgsUI
{
    FOS_VIDEOSTREAMLISTPARAM subListParam = self.videoSubStreamListParam;
    NSArray *subControls = @[self.videoStreamType2Btn,
                             self.resolution2Btn,
                             self.bitRate2Btn,
                             self.frameRate2Btn,
                             self.gop2Btn,
                             self.isVBR2Btn];
    [self updateEncodeUIControls:subControls withListParam:subListParam];
}

- (void)updateScreenDisplayUI
{
    FOS_OSDSETTING osdSetting = self.osdSetting;
    [self.timeStampEnableBtn selectItemAtIndex:osdSetting.isEnableTimeStamp];
    [self.deviceNameEnableBtn selectItemAtIndex:osdSetting.isEnableDevName];
    [self.tempAndHumidEnableBtn selectItemAtIndex:osdSetting.isEnableTempAndHumid];
}

- (void)updateControl :(NSPopUpButton *)btn withHour :(NSUInteger)hour
{
    if (hour < [self hourRange].length) {
        [btn selectItemAtIndex:hour];
    }
}

- (void)updateControl :(NSPopUpButton *)btn withMinutes :(NSUInteger)min
{
    if (min < [self minutesRange].length) {
        [btn selectItemAtIndex:min];
    }
}

- (void)updateLEDScheduleUI
{
    FOS_SCHEDULEINFRALEDCONFIG scheduleCfg = self.scheduleInfraLedConfig;
    //1
    self.isEnableSchedule1 = [self isScheduleEnableBeginHour:scheduleCfg.startHour[0]
                                                    beginMin:scheduleCfg.startMin[0]
                                                     endHour:scheduleCfg.endHour[0]
                                                      endMin:scheduleCfg.endMin[0]];
    [self updateControl:self.beginHour1Btn withHour:scheduleCfg.startHour[0]];
    [self updateControl:self.beginMin1Btn withMinutes:scheduleCfg.startMin[0]];
    [self updateControl:self.endHour1Btn withHour:scheduleCfg.endHour[0]];
    [self updateControl:self.endMin1Btn withMinutes:scheduleCfg.endMin[0]];
    
    //2
    self.isEnableSchedule2 = [self isScheduleEnableBeginHour:scheduleCfg.startHour[1]
                                                    beginMin:scheduleCfg.startMin[1]
                                                     endHour:scheduleCfg.endHour[1]
                                                      endMin:scheduleCfg.endMin[1]];
    [self updateControl:self.beginHour2Btn withHour:scheduleCfg.startHour[1]];
    [self updateControl:self.beginMin2Btn withMinutes:scheduleCfg.startMin[1]];
    [self updateControl:self.endHour2Btn withHour:scheduleCfg.endHour[1]];
    [self updateControl:self.endMin2Btn withMinutes:scheduleCfg.endMin[1]];

    //3
    self.isEnableSchedule3 = [self isScheduleEnableBeginHour:scheduleCfg.startHour[2]
                                                    beginMin:scheduleCfg.startMin[2]
                                                     endHour:scheduleCfg.endHour[2]
                                                      endMin:scheduleCfg.endMin[2]];
    [self updateControl:self.beginHour3Btn withHour:scheduleCfg.startHour[2]];
    [self updateControl:self.beginMin3Btn withMinutes:scheduleCfg.startMin[2]];
    [self updateControl:self.endHour3Btn withHour:scheduleCfg.endHour[2]];
    [self updateControl:self.endMin3Btn withMinutes:scheduleCfg.endMin[2]];
}



#pragma mark - setter && getter
- (void)setControl :(NSPopUpButton *)btn withRange :(NSRange)range
{
    [btn removeAllItems];
    for (int i = 0; i < range.length; i++) {
        NSString *title = [NSString stringWithFormat:@"%2d",(int)range.location + i];
        [btn addItemWithTitle:title];
    }
}

- (void)setVideoStreamListParam:(FOS_VIDEOSTREAMLISTPARAM)videoStreamListParam
{
    _videoStreamListParam = videoStreamListParam;
    [self updateMainStreamEncoderArgsUI];
}

- (void)setVideoSubStreamListParam:(FOS_VIDEOSTREAMLISTPARAM)videoSubStreamListParam
{
    _videoSubStreamListParam = videoSubStreamListParam;
    [self updateSubStreamEncoderArgsUI];
}

- (void)setOsdSetting:(FOS_OSDSETTING)osdSetting
{
    _osdSetting = osdSetting;
    [self updateScreenDisplayUI];
}



- (void)setOsdMaskEnable:(int)osdMaskEnable
{
    _osdMaskEnable = osdMaskEnable;
    [self.osdMaskEnableBtn selectItemAtIndex:osdMaskEnable];
    [self updatePrivacyCoverUI];
}


- (void)setScheduleInfraLedConfig:(FOS_SCHEDULEINFRALEDCONFIG)scheduleInfraLedConfig
{
    _scheduleInfraLedConfig = scheduleInfraLedConfig;
    [self updateLEDScheduleUI];
}


- (void)setFrameRate1Btn:(NSPopUpButton *)frameRate1Btn
{
    _frameRate1Btn = frameRate1Btn;
    [self setControl:_frameRate1Btn withRange:[self frameRateRange]];
}

- (void)setFrameRate2Btn:(NSPopUpButton *)frameRate2Btn
{
    _frameRate2Btn = frameRate2Btn;
    [self setControl:_frameRate2Btn withRange:[self frameRateRange]];
}

- (void)setGop1Btn:(NSPopUpButton *)gop1Btn
{
    _gop1Btn = gop1Btn;
    [self setControl:_gop1Btn withRange:[self gopRange]];
}

- (void)setGop2Btn:(NSPopUpButton *)gop2Btn
{
    _gop2Btn = gop2Btn;
    [self setControl:_gop2Btn withRange:[self gopRange]];
}

- (void)setBeginHour1Btn:(NSPopUpButton *)beginHour1Btn
{
    _beginHour1Btn = beginHour1Btn;
    [self setControl:beginHour1Btn withRange:[self hourRange]];
}

- (void)setBeginMin1Btn:(NSPopUpButton *)beginMin1Btn
{
    _beginMin1Btn = beginMin1Btn;
    [self setControl:beginMin1Btn withRange:[self minutesRange]];
}

- (void)setEndHour1Btn:(NSPopUpButton *)endHour1Btn
{
    _endHour1Btn = endHour1Btn;
    [self setControl:endHour1Btn withRange:[self hourRange]];
}

- (void)setEndMin1Btn:(NSPopUpButton *)endMin1Btn
{
    _endMin1Btn = endMin1Btn;
    [self setControl:_endMin1Btn withRange:[self minutesRange]];
}


- (void)setBeginHour2Btn:(NSPopUpButton *)beginHour2Btn
{
    _beginHour2Btn = beginHour2Btn;
    [self setControl:beginHour2Btn withRange:[self hourRange]];
}

- (void)setBeginMin2Btn:(NSPopUpButton *)beginMin2Btn
{
    _beginMin2Btn = beginMin2Btn;
    [self setControl:beginMin2Btn withRange:[self minutesRange]];
}

- (void)setEndHour2Btn:(NSPopUpButton *)endHour2Btn
{
    _endHour2Btn = endHour2Btn;
    [self setControl:endHour2Btn withRange:[self hourRange]];
}

- (void)setEndMin2Btn:(NSPopUpButton *)endMin2Btn
{
    _endMin2Btn = endMin2Btn;
    [self setControl:_endMin2Btn withRange:[self minutesRange]];
}


- (void)setBeginHour3Btn:(NSPopUpButton *)beginHour3Btn
{
    _beginHour3Btn = beginHour3Btn;
    [self setControl:beginHour3Btn withRange:[self hourRange]];
}

- (void)setBeginMin3Btn:(NSPopUpButton *)beginMin3Btn
{
    _beginMin3Btn = beginMin3Btn;
    [self setControl:beginMin3Btn withRange:[self minutesRange]];
}

- (void)setEndHour3Btn:(NSPopUpButton *)endHour3Btn
{
    _endHour3Btn = endHour3Btn;
    [self setControl:endHour3Btn withRange:[self hourRange]];
}

- (void)setEndMin3Btn:(NSPopUpButton *)endMin3Btn
{
    _endMin3Btn = endMin3Btn;
    [self setControl:_endMin3Btn withRange:[self minutesRange]];
}
#pragma mark - NSPopupButton Data

- (NSRange)frameRateRange
{
    return NSMakeRange(1, 30);
}

- (NSRange)gopRange
{
    return NSMakeRange(10, 90);
}

- (NSRange)hourRange
{
    return NSMakeRange(0, 24);
}

- (NSRange)minutesRange
{
    return NSMakeRange(0, 60);
}
@end
