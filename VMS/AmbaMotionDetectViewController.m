//
//  AmbaDetectViewController.m
//  
//
//  Created by mac_dev on 16/5/25.
//
//

#import "AmbaMotionDetectViewController.h"

@interface AmbaMotionDetectViewController ()

@end

@implementation AmbaMotionDetectViewController

#pragma mark - public api
- (void)fetch
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

- (void)push
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

#pragma mark - detect area edit scene
- (DetectionAreasEditWindowController *)daewc
{
    Channel *chn = self.device.children[0];
    FOS_MOTIONDETECTCONFIG1 motionCfg = [self ambaMotionDetectConfigFromUI];
    
    return [[AmbaDetectionAreaEditWindowController alloc] initWithWindowNibName:@"AmbaDetectionAreaEditWindowController"
                                                                      channelId:chn.uniqueId
                                                                   detectConfig:motionCfg];
}

- (void)onEditDone:(void *)cfg
{
    self.ambaMotionDetectConfig = *((FOS_MOTIONDETECTCONFIG1 *)cfg);
}
@end
