//
//  NVRHsMotionDetectViewController.m
//  
//
//  Created by mac_dev on 16/5/30.
//
//

#import "NVRMotionDetectViewController.h"

@interface NVRMotionDetectViewController ()
@end

@implementation NVRMotionDetectViewController

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isEnableSnap = NO;
    self.isEnableRecord = YES;
}

#pragma mark - public api
- (void)fetchHsMotionConfig
{
    [self setActivity:YES];
    __block int chn = self.chn;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &chn;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        FOS_MOTIONDETECTCONFIG motionDetectCfg;
        int isEnableIPCAudioAlarm;
        int recordTime;
        
        if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_HS_MOTION_DETECT
                                                  fromDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSLog(@"%@",rawString);
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err && dict) {
                NSNumber *result = [dict valueForKey:KEY_XML_RESULT];
                
                if (result && result.intValue == 0) {
                    motionDetectCfg.isEnable = [[dict valueForKey:@"isEnable"] intValue];
                    motionDetectCfg.linkage = [[dict valueForKey:@"linkage"] intValue];
                    motionDetectCfg.sensitivity = [[dict valueForKey:@"sensitivity"] intValue];
                    motionDetectCfg.snapInterval = 0;
                    motionDetectCfg.triggerInterval = [[dict valueForKey:@"triggerInterval"] intValue];
                    
                    //Ignore ipcalarmsound
                    for (int i = 0; i < FOS_MAX_SCHEDULE_COUNT; i++) {
                        motionDetectCfg.schedules[i] = [[dict valueForKey:[NSString stringWithFormat:@"schedule%d",i]] longLongValue];
                    }
                    
                    for (int i = 0; i < FOS_MAX_AREA_COUNT; i++) {
                        motionDetectCfg.areas[i] = [[dict valueForKey:[NSString stringWithFormat:@"area%d",i]] intValue];
                    }
                    
                    isEnableIPCAudioAlarm = [[dict valueForKey:@"ipcalarmsound"] intValue];
                    recordTime = [[dict valueForKey:@"recordTime"] intValue];
                    success = YES;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setHsMotionDetectConfig:motionDetectCfg];
                [self setIsEnablePCAudioAlarm:isEnableIPCAudioAlarm];
                [self setRecordTime:recordTime];
            }
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
        });
    });
}

- (void)fetchAmbaMotionConfig
{
    [self setActivity:YES];
    __block int chn = self.chn;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &chn;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        FOS_MOTIONDETECTCONFIG1 motionDetectCfg;
        int isEnableIPCAudioAlarm;
        int recordTime;
        
        if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_AMBA_MOTION_DETECT
                                                  fromDevice:self.device]) {
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSLog(@"%@",rawString);
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err && dict) {
                NSNumber *result = [dict valueForKey:KEY_XML_RESULT];
                if (result && result.intValue == 0) {
                    motionDetectCfg.isEnable = [[dict valueForKey:@"enable"] intValue];
                    motionDetectCfg.linkage = [[dict valueForKey:@"linkage"] intValue];
                    motionDetectCfg.snapInterval = [[dict valueForKey:@"snapInt"] intValue];
                    motionDetectCfg.triggerInterval = [[dict valueForKey:@"triggerInt"] intValue];
                    
                    for (int i = 0; i < FOS_MAX_SCHEDULE_COUNT; i++) {
                        motionDetectCfg.schedules[i] = [[dict valueForKey:[NSString stringWithFormat:@"schedule%d",i]] longLongValue];
                    }
                    
                    for (int i = 0; i < ANBAMOTIONCOUNT; i++) {
                        motionDetectCfg.x[i] = [[dict valueForKey:[NSString stringWithFormat:@"x%d",i]] intValue];
                        motionDetectCfg.y[i] = [[dict valueForKey:[NSString stringWithFormat:@"y%d",i]] intValue];
                        motionDetectCfg.width[i] = [[dict valueForKey:[NSString stringWithFormat:@"width%d",i]] intValue];
                        motionDetectCfg.height[i] = [[dict valueForKey:[NSString stringWithFormat:@"height%d",i]] intValue];
                        motionDetectCfg.sensitivity[i] = [[dict valueForKey:[NSString stringWithFormat:@"sensitivity%d",i]] intValue];
                        motionDetectCfg.valid[i] = [[dict valueForKey:[NSString stringWithFormat:@"valid%d",i]] intValue];
                    }
                    
                    isEnableIPCAudioAlarm = [[dict valueForKey:@"ipcalarmsound"] intValue];
                    recordTime = [[dict valueForKey:@"recordTime"] intValue];
                    success = YES;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setAmbaMotionDetectConfig:motionDetectCfg];
                [self setIsEnablePCAudioAlarm:isEnableIPCAudioAlarm];
                [self setRecordTime:recordTime];
            }
            else {
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            }
            [self setActivity:NO];
        });
    });
}

- (void)pushHsDetectConfig
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //收集控件信息
        FOSCAM_NVR_CONFIG config;
        FOS_NVR_MOTION_DETECT_CONFIG nvrMotionDetectCfg;
        
        nvrMotionDetectCfg.motionDetectCfg = [self hsMotionDetectConfigFromUI];
        nvrMotionDetectCfg.isEnableIPCAudioAlarm = self.isEnablePCAudioAlarm;
        nvrMotionDetectCfg.recordTime = [self recordTimeFromUI];
        nvrMotionDetectCfg.chn = self.chn;
        
        for (int i=0; i<FOS_MAX_AREA_COUNT; i++) {
            nvrMotionDetectCfg.motionDetectCfg.areas[i] = self.hsMotionDetectConfig.areas[i];
        }
        
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &nvrMotionDetectCfg;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_HS_MOTION_DETECT
                                                    toDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSLog(@"%@",rawString);
            NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err) {
                NSNumber *result = [values valueForKey:KEY_XML_RESULT];
                success = result && (result.intValue == 0);
            }
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
    int chn = self.chn;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //收集控件信息
        FOSCAM_NVR_CONFIG config;
        FOS_NVR_MOTION_DETECT_CONFIG1 nvrMotionDetectCfg;
        
        nvrMotionDetectCfg.motionDetectCfg = [self ambaMotionDetectConfigFromUI];
        nvrMotionDetectCfg.isEnableIPCAudioAlarm = self.isEnablePCAudioAlarm;
        nvrMotionDetectCfg.chn = chn;
        nvrMotionDetectCfg.recordTime = [self recordTimeFromUI];
        
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &nvrMotionDetectCfg;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_AMBA_MOTION_DETECT
                                                    toDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSLog(@"%@",rawString);
            NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err) {
                NSNumber *result = [values valueForKey:KEY_XML_RESULT];
                success = result && (result.intValue == 0);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success)
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

#pragma mark - linkage init ui
- (NSArray *)linkages
{
    return @[@{KEY_LINKAGE_NAME : NSLocalizedString(@"Send E-mail", nil),KEY_LINKAGE_VALUE : @1},
             @{KEY_LINKAGE_NAME : @"FTP",KEY_LINKAGE_VALUE : @2},
             @{KEY_LINKAGE_NAME : NSLocalizedString(@"Record", nil),KEY_LINKAGE_VALUE : @3},
             @{KEY_LINKAGE_NAME : NSLocalizedString(@"Buzzer", nil),KEY_LINKAGE_VALUE : @4}];
}

- (NSString *)audioAlarmTitle
{
    return NSLocalizedString(@"IPC Buzzer", nil);
}
@end
