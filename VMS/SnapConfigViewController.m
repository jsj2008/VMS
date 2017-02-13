//
//  SnapConfigViewController.m
//  VMS
//
//  Created by mac_dev on 16/8/30.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "SnapConfigViewController.h"

@interface SnapConfigViewController ()

@property(nonatomic,weak) IBOutlet NSPopUpButton *snapPicQualityBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *saveLocationBtn;
@property(nonatomic,weak) IBOutlet NSView *fileNameDiv;
@property(nonatomic,weak) IBOutlet NSView *scheduleDiv;
@property(nonatomic,weak) IBOutlet NSTextField *snapIntervalTF;
@property(nonatomic,weak) IBOutlet TimePickerView *timePickerView;
@property(nonatomic,weak) IBOutlet NSTextField *tip;

@property(nonatomic,assign) BOOL isEnableScheduleSnap;
@property(nonatomic,assign) BOOL isEnableFileName;
@property(nonatomic,assign) NSRange snapIntervalRg;

@end

@implementation SnapConfigViewController

- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //首先获取能力集
        FosAbility *ability = [[DispatchCenter sharedDispatchCenter] abilityOfDevice:self.device channel:0];
        BOOL success = NO;
        FOS_SNAPCONFIG snapConfig;
        FOS_SCHEDULESNAPCONFIG scheduleSnapConfig;
        
        if (ability) {
            FOSCAM_NET_CONFIG_TYPE cfgTyes[] =
            {
                FOSCAN_NET_CONFIG_VIDEO_SNAP,
                FOSCAM_NET_CONFIG_VIDEO_SCHEDULE_SNAP,
            };
            
            void *infos[] = {&snapConfig,&scheduleSnapConfig};
            FOSCAM_NET_CONFIG config;
            
            
            for (int i = 0; i < 2; i++) {
                config.info = infos[i];
                success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                   forType:cfgTyes[i]
                                                                fromDevice:self.device];
                if (!success)
                    break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setSnapConfig:snapConfig];
                [self setScheduleSnapConfig:scheduleSnapConfig];
                
                if (ability.model >= 1000 && ability.model < 4000) {
                    //CE平台
                    [self setSnapIntervalRg:NSMakeRange(5, 65531)];
                }
                else {
                    [self setSnapIntervalRg:NSMakeRange(1, 65535)];
                }
            }
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
           
            [self setActivity:NO];
        });
    });
}

- (NSString *)errMsg :(int)code
{
    switch (code) {
        case 0:
            return nil;
        case 1:
            return NSLocalizedString(@"time out", nil);
        case 2:
            return NSLocalizedString(@"snap interval is out of range", nil);
        case 3:
            return NSLocalizedString(@"empty filename", nil);
        default:
            break;
    }
    
    return NSLocalizedString(@"unknow error", nil);
}

- (void)push
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int err = 0;
        do {
            FOS_SNAPCONFIG snapConfig = [self snapConfigFromUI];
            FOS_SCHEDULESNAPCONFIG scheduleSnapConfig = [self scheduleSnapConfigFromUI];
            if (scheduleSnapConfig.isEnable) {
                
                if (scheduleSnapConfig.snapInterval < self.snapIntervalRg.location ||
                    scheduleSnapConfig.snapInterval > self.snapIntervalRg.location + self.snapIntervalRg.length - 1) {
                    err = 2;
                    break;
                }
            }
            
            FOSCAM_NET_CONFIG_TYPE cfgTyes[] =
            {
                FOSCAN_NET_CONFIG_VIDEO_SNAP,
                FOSCAM_NET_CONFIG_VIDEO_SCHEDULE_SNAP,
            };
            
            void *infos[] = {&snapConfig,&scheduleSnapConfig};
            FOSCAM_NET_CONFIG config;
           
            for (int i = 0; i< 2; i++) {
                config.info = infos[i];
                if (![[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                              forType:cfgTyes[i]
                                                             toDevice:self.device]) {
                    err = 1;
                    break;
                }
            }
        } while (0);
        
    
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err != 0) {
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:[self errMsg:err]];
            }
            
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Snap", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}


#pragma mark - nstextfield delegate
#define TF_SNAP_INTEVER @"snap intever"
- (void)controlTextDidChange:(NSNotification *)obj
{
    id sender = obj.object;
    if ([[(NSTextField *)sender identifier] isEqualToString:TF_SNAP_INTEVER]) {
        NSTextField *tf = sender;
        long val = tf.integerValue;
        if (val < 1) tf.intValue = 1;
        else if (val > 65535) tf.intValue = 65535;
    }
}

#pragma mark - action
- (IBAction)saveLocationSelected:(id)sender
{
    [self updateFileNameUI];
}

#pragma mark - update ui
- (void)updateSnapConfigUI
{
    [self.snapPicQualityBtn selectItemWithTag:self.snapConfig.snapPicQuality];
    [self.saveLocationBtn selectItemWithTag:self.snapConfig.saveLocation];
    [self updateFileNameUI];
}

- (void)updateScheduleSnapUI
{
    self.isEnableScheduleSnap = self.scheduleSnapConfig.isEnable;
    self.snapIntervalTF.intValue = self.scheduleSnapConfig.snapInterval;
    [self.timePickerView setNeedsDisplay:YES];
}

- (void)updateFileNameUI
{
    if (self.saveLocationBtn.indexOfSelectedItem == 2) {
        [self.fileNameDiv setHidden:YES];
        /*[self.scheduleDiv setFrameOrigin:NSMakePoint(self.fileNameDiv.frame.origin.x,
                                                     self.fileNameDiv.frame.origin.y + self.fileNameDiv.frame.size.height)];*/
    }
    else {
        [self.fileNameDiv setHidden:YES];
        //[self.scheduleDiv setFrameOrigin:self.fileNameDiv.frame.origin];
    }
}

#pragma mark - config from ui
- (FOS_SNAPCONFIG)snapConfigFromUI
{
    FOS_SNAPCONFIG snapConfig;
    memset(&snapConfig, 0, sizeof(FOS_SNAPCONFIG));
    
    snapConfig.snapPicQuality = (int)self.snapPicQualityBtn.selectedTag;
    snapConfig.saveLocation = (int)self.saveLocationBtn.selectedTag;
    
    return snapConfig;
}

- (FOS_SCHEDULESNAPCONFIG)scheduleSnapConfigFromUI
{
    FOS_SCHEDULESNAPCONFIG config;
    memset(&config, 0, sizeof(FOS_SCHEDULESNAPCONFIG));
    
    config.isEnable = self.isEnableScheduleSnap;
    config.snapInterval = self.snapIntervalTF.intValue;
    
    [self.timePickerView getSchedule:config.schedule lenght:7];
    return config;
}

#pragma mark - setter & getter
- (void)setSnapConfig:(FOS_SNAPCONFIG)snapConfig
{
    _snapConfig = snapConfig;
    [self updateSnapConfigUI];
}

- (void)setScheduleSnapConfig:(FOS_SCHEDULESNAPCONFIG)scheduleSnapConfig
{
    _scheduleSnapConfig = scheduleSnapConfig;
    //sdk是从星期一到星期日，这里需要做处理转换过来
    [self.timePickerView setSchedule:self.scheduleSnapConfig.schedule];
    [self updateScheduleSnapUI];
}

- (void)setSnapIntervalRg:(NSRange)snapIntervalRg
{
    _snapIntervalRg = snapIntervalRg;
    self.tip.stringValue = [NSString stringWithFormat:@"(%ld-%ld)s",_snapIntervalRg.location,_snapIntervalRg.location+_snapIntervalRg.length - 1];
}
@end
