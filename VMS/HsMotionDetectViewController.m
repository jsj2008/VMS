//
//  HsMotionDetectViewController.m
//  
//
//  Created by mac_dev on 16/5/25.
//
//

#import "HsMotionDetectViewController.h"

@interface HsMotionDetectViewController ()
@end

@implementation HsMotionDetectViewController
#pragma mark - public api
- (void)push
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

- (void)fetch
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

#pragma mark - detect area edit scene
- (DetectionAreasEditWindowController *)daewc
{
    Channel *chn = self.device.children[0];
    FOS_MOTIONDETECTCONFIG motionCfg = [self hsMotionDetectConfigFromUI];
    return [[HsDetectionAreaEditWindowController alloc] initWithWindowNibName:@"HsDetectionAreasEditWindowController"
                                                                    channelId:chn.uniqueId
                                                                 detectConfig:motionCfg];
}

- (void)onEditDone:(void *)cfg
{
    self.hsMotionDetectConfig = *((FOS_MOTIONDETECTCONFIG *)cfg);
}

@end
